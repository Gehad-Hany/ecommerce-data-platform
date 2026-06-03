select
    row_number() over (
        order by
            geolocation_zip_code_prefix,
            geolocation_lat,
            geolocation_lng,
            geolocation_city,
            geolocation_state
    ) as geolocation_sk,
    geolocation_zip_code_prefix as zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    current_timestamp() as load_datetime
from {{ ref('silver_geolocation') }}
where geolocation_zip_code_prefix is not null
