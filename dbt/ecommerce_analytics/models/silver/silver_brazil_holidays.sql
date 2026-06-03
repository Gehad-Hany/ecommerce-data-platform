select
    calendar_year_shifted as calendar_year,
    calendar_date_shifted as calendar_date,
    event_name,
    event_type,
    country_code,
    (event_type = 'weekend') as is_weekend,
    (event_type = 'public_holiday') as is_public_holiday
from {{ ref('stg_brazil_holidays') }}
where calendar_date_shifted <= to_date('2026-05-20')
