select distinct
    trim(geolocation_zip_code_prefix) as geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    lower(trim(geolocation_city)) as geolocation_city,
    upper(trim(geolocation_state)) as geolocation_state
from {{ source('raw_batch', 'GEOLOCATION') }}
