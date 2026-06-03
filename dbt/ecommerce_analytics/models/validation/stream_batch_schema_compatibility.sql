with table_pairs as (
    select
        column1 as table_group,
        column2 as batch_table,
        column3 as stream_table
    from values
        ('customers', 'SILVER_CUSTOMERS', 'SILVER_STREAM_CUSTOMERS'),
        ('orders', 'SILVER_ORDERS', 'SILVER_STREAM_ORDERS'),
        ('order_items', 'SILVER_ORDER_ITEMS', 'SILVER_STREAM_ORDER_ITEMS'),
        ('order_payments', 'SILVER_ORDER_PAYMENTS', 'SILVER_STREAM_ORDER_PAYMENTS'),
        ('order_reviews', 'SILVER_ORDER_REVIEWS', 'SILVER_STREAM_ORDER_REVIEWS')
),

join_keys as (
    select
        column1 as table_group,
        column2 as column_name
    from values
        ('customers', 'CUSTOMER_ID'),
        ('orders', 'ORDER_ID'),
        ('orders', 'CUSTOMER_ID'),
        ('order_items', 'ORDER_ID'),
        ('order_items', 'ORDER_ITEM_ID'),
        ('order_items', 'PRODUCT_ID'),
        ('order_items', 'SELLER_ID'),
        ('order_payments', 'ORDER_ID'),
        ('order_payments', 'PAYMENT_SEQUENTIAL'),
        ('order_reviews', 'REVIEW_ID'),
        ('order_reviews', 'ORDER_ID')
),

batch_columns as (
    select
        p.table_group,
        p.batch_table,
        p.stream_table,
        c.column_name,
        c.data_type,
        c.numeric_precision,
        c.numeric_scale
    from table_pairs p
    inner join {{ target.database }}.information_schema.columns c
        on c.table_schema = upper('{{ target.schema }}')
       and c.table_name = p.batch_table
),

stream_columns as (
    select
        p.table_group,
        p.batch_table,
        p.stream_table,
        c.column_name,
        c.data_type,
        c.numeric_precision,
        c.numeric_scale
    from table_pairs p
    inner join {{ target.database }}.information_schema.columns c
        on c.table_schema = upper('{{ target.schema }}')
       and c.table_name = p.stream_table
),

batch_to_stream_checks as (
    select
        b.table_group,
        b.batch_table,
        b.stream_table,
        b.column_name as batch_column,
        b.column_name as stream_column,
        b.data_type as batch_data_type,
        s.data_type as stream_data_type,
        b.numeric_precision as batch_numeric_precision,
        s.numeric_precision as stream_numeric_precision,
        b.numeric_scale as batch_numeric_scale,
        s.numeric_scale as stream_numeric_scale,
        case
            when jk.column_name is not null then true
            else false
        end as is_join_key,
        case
            when s.column_name is null then 'missing_in_stream'
            when b.data_type <> s.data_type then 'data_type_mismatch'
            when b.data_type = 'NUMBER'
                and (
                    coalesce(b.numeric_precision, -1) <> coalesce(s.numeric_precision, -1)
                    or coalesce(b.numeric_scale, -1) <> coalesce(s.numeric_scale, -1)
                )
                then 'numeric_definition_mismatch'
            else 'pass'
        end as issue_type
    from batch_columns b
    left join stream_columns s
        on b.table_group = s.table_group
       and b.column_name = s.column_name
    left join join_keys jk
        on b.table_group = jk.table_group
       and b.column_name = jk.column_name
),

extra_stream_columns as (
    select
        s.table_group,
        s.batch_table,
        s.stream_table,
        null as batch_column,
        s.column_name as stream_column,
        null as batch_data_type,
        s.data_type as stream_data_type,
        null as batch_numeric_precision,
        s.numeric_precision as stream_numeric_precision,
        null as batch_numeric_scale,
        s.numeric_scale as stream_numeric_scale,
        case
            when jk.column_name is not null then true
            else false
        end as is_join_key,
        'extra_in_stream' as issue_type
    from stream_columns s
    left join batch_columns b
        on s.table_group = b.table_group
       and s.column_name = b.column_name
    left join join_keys jk
        on s.table_group = jk.table_group
       and s.column_name = jk.column_name
    where b.column_name is null
),

all_checks as (
    select * from batch_to_stream_checks
    union all
    select * from extra_stream_columns
)

select
    table_group,
    batch_table,
    stream_table,
    batch_column,
    stream_column,
    case
        when batch_data_type = 'NUMBER'
            then batch_data_type || '(' || batch_numeric_precision || ',' || batch_numeric_scale || ')'
        else batch_data_type
    end as batch_column_type,
    case
        when stream_data_type = 'NUMBER'
            then stream_data_type || '(' || stream_numeric_precision || ',' || stream_numeric_scale || ')'
        else stream_data_type
    end as stream_column_type,
    is_join_key,
    issue_type,
    case
        when issue_type = 'pass' then 'PASS'
        else 'FAIL'
    end as validation_status
from all_checks
order by
    validation_status desc,
    is_join_key desc,
    table_group,
    coalesce(batch_column, stream_column)
