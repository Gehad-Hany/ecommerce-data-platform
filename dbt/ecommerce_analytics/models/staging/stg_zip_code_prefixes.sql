select distinct
    trim(zip_code_prefix) as zip_code_prefix
from {{ source('raw_batch', 'ZIP_CODE_PREFIXES') }}
where zip_code_prefix is not null
  and trim(zip_code_prefix) <> ''
