with base_sellers as (
    select
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        to_date('1900-01-01') as start_date,
        'snapshot' as cdc_operation,
        sha2(
            concat_ws(
                '|',
                coalesce(seller_zip_code_prefix, ''),
                coalesce(seller_city, ''),
                coalesce(seller_state, '')
            ),
            256
        ) as change_hash,
        'base' as source_system,
        0 as source_rank
    from {{ ref('silver_sellers') }}
    where seller_id is not null
),

cdc_sellers as (
    select
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state,
        cdc_event_date as start_date,
        cdc_operation,
        change_hash,
        source_system,
        1 as source_rank
    from {{ ref('silver_cdc_sellers') }}
    where seller_id is not null
),

unioned as (
    select * from base_sellers
    union all
    select * from cdc_sellers
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by seller_id, start_date, change_hash
            order by source_rank desc
        ) as rn
    from unioned
),

sequenced as (
    select
        *,
        lead(start_date) over (
            partition by seller_id
            order by start_date, source_rank
        ) as end_date,
        lag(change_hash) over (
            partition by seller_id
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
    row_number() over (order by seller_id, start_date) as seller_sk,
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    start_date,
    end_date,
    (end_date is null and cdc_operation <> 'delete') as is_current,
    current_timestamp() as load_datetime
from scd2
