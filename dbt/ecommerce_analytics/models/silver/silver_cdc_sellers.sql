select
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    cdc_event_date,
    cdc_event_time,
    cdc_operation,
    change_hash,
    'cdc' as source_system
from {{ ref('stg_cdc_sellers') }}
