with base_customers as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        to_date('1900-01-01') as start_date,
        'snapshot' as cdc_operation,
        sha2(
            concat_ws(
                '|',
                coalesce(customer_unique_id, ''),
                coalesce(customer_zip_code_prefix, ''),
                coalesce(customer_city, ''),
                coalesce(customer_state, '')
            ),
            256
        ) as change_hash,
        'base' as source_system,
        0 as source_rank
    from {{ ref('int_customers_unified') }}
    where customer_id is not null
),

cdc_customers as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        cdc_event_date as start_date,
        cdc_operation,
        change_hash,
        source_system,
        1 as source_rank
    from {{ ref('silver_cdc_customers') }}
    where customer_id is not null
),

unioned as (
    select * from base_customers
    union all
    select * from cdc_customers
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by customer_id, start_date, change_hash
            order by source_rank desc
        ) as rn
    from unioned
),

sequenced as (
    select
        *,
        lead(start_date) over (
            partition by customer_id
            order by start_date, source_rank
        ) as end_date,
        lag(change_hash) over (
            partition by customer_id
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
    row_number() over (order by customer_id, start_date) as customer_sk,
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    start_date,
    end_date,
    (end_date is null and cdc_operation <> 'delete') as is_current,
    current_timestamp() as load_datetime
from scd2
