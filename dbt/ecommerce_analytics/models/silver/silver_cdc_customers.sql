select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    cdc_event_date,
    cdc_event_time,
    cdc_operation,
    change_hash,
    'cdc' as source_system
from {{ ref('stg_cdc_customers') }}
