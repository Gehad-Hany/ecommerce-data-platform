select
    zip_code_prefix
from {{ ref('stg_zip_code_prefixes') }}
