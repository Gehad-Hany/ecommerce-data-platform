select
    zip_code_prefix,
    current_timestamp() as load_datetime
from {{ ref('silver_zip_code_prefixes') }}
where zip_code_prefix is not null
