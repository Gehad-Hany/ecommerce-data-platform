with base_products as (
    select
        p.product_id,
        p.clean_product_category_name as product_category_name,
        coalesce(t.product_category_name_english, 'unknown') as product_category_name_english,
        to_date('1900-01-01') as start_date,
        'snapshot' as cdc_operation,
        sha2(
            concat_ws(
                '|',
                coalesce(p.clean_product_category_name, ''),
                coalesce(t.product_category_name_english, 'unknown')
            ),
            256
        ) as change_hash,
        'base' as source_system,
        0 as source_rank
    from {{ ref('silver_products') }} p
    left join {{ ref('silver_product_category_translation') }} t
        on p.clean_product_category_name = t.product_category_name
    where p.product_id is not null
),

cdc_products as (
    select
        p.product_id,
        p.clean_product_category_name as product_category_name,
        coalesce(t.product_category_name_english, 'unknown') as product_category_name_english,
        p.cdc_event_date as start_date,
        p.cdc_operation,
        sha2(
            concat_ws(
                '|',
                coalesce(p.clean_product_category_name, ''),
                coalesce(t.product_category_name_english, 'unknown')
            ),
            256
        ) as change_hash,
        p.source_system,
        1 as source_rank
    from {{ ref('silver_cdc_products') }} p
    left join {{ ref('silver_product_category_translation') }} t
        on p.clean_product_category_name = t.product_category_name
    where p.product_id is not null
),

unioned as (
    select * from base_products
    union all
    select * from cdc_products
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by product_id, start_date, change_hash
            order by source_rank desc
        ) as rn
    from unioned
),

sequenced as (
    select
        *,
        lead(start_date) over (
            partition by product_id
            order by start_date, source_rank
        ) as end_date,
        lag(change_hash) over (
            partition by product_id
            order by start_date, source_rank
        ) as previous_change_hash
    from deduplicated
    where rn = 1
),

scd2 as (
    select *
    from sequenced
    where previous_change_hash is null
       or previous_change_hash <> change_hash
       or cdc_operation = 'delete'
)

select
    row_number() over (order by product_id, start_date) as product_sk,
    product_id,
    product_category_name,
    product_category_name_english,
    start_date,
    end_date,
    (end_date is null and cdc_operation <> 'delete') as is_current,
    current_timestamp() as load_datetime
from scd2
