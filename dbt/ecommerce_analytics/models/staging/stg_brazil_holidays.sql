select
    calendar_year,
    calendar_date,
    dateadd(year, 8, calendar_date) as calendar_date_shifted,
    year(dateadd(year, 8, calendar_date)) as calendar_year_shifted,
    lower(trim(event_name)) as event_name,
    lower(trim(event_type)) as event_type,
    upper(trim(country_code)) as country_code
from {{ source('raw_batch', 'BRAZIL_HOLIDAYS') }}
