select
    trim(seller_id) as seller_id,
    trim(seller_zip_code_prefix) as seller_zip_code_prefix,
    lower(trim(seller_city)) as seller_city,
    upper(trim(seller_state)) as seller_state
from {{ source('raw_batch', 'SELLERS') }}
