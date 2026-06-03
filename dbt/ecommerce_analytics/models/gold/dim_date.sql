with date_values as (
    select order_purchase_date as date_value from {{ ref('int_orders_unified') }}
    union all
    select order_approved_date from {{ ref('int_orders_unified') }}
    union all
    select clean_delivered_carrier_date from {{ ref('int_orders_unified') }}
    union all
    select clean_delivered_customer_date from {{ ref('int_orders_unified') }}
    union all
    select order_estimated_delivery_date from {{ ref('int_orders_unified') }}
    union all
    select shipping_limit_date from {{ ref('int_order_items_unified') }}
    union all
    select review_creation_date from {{ ref('int_order_reviews_unified') }}
    union all
    select review_answer_date from {{ ref('int_order_reviews_unified') }}
    union all
    select calendar_date from {{ ref('silver_brazil_holidays') }}
),

date_bounds as (
    select
        min(date_value) as min_date,
        max(date_value) as max_date
    from date_values
    where date_value is not null
),

numbers as (
    select row_number() over (order by seq4()) - 1 as day_offset
    from table(generator(rowcount => 5000))
),

date_spine as (
    select dateadd(day, n.day_offset, b.min_date) as full_date
    from date_bounds b
    inner join numbers n
        on n.day_offset <= datediff(day, b.min_date, b.max_date)
),

holiday_events as (
    select
        calendar_date,
        max(calendar_year) as calendar_year,
        listagg(distinct event_name, ', ') within group (order by event_name) as event_name,
        listagg(distinct event_type, ', ') within group (order by event_type) as event_type,
        max(country_code) as country_code,
        boolor_agg(is_weekend) as is_weekend_from_calendar,
        boolor_agg(is_public_holiday) as is_public_holiday
    from {{ ref('silver_brazil_holidays') }}
    group by calendar_date
)

select
    row_number() over (order by d.full_date) as date_sk,
    to_number(to_char(d.full_date, 'YYYYMMDD')) as date_key,
    d.full_date,
    year(d.full_date) as calendar_year,
    quarter(d.full_date) as calendar_quarter,
    month(d.full_date) as month_number,
    monthname(d.full_date) as month_name,
    day(d.full_date) as day_of_month,
    dayofweekiso(d.full_date) as day_of_week,
    dayname(d.full_date) as day_name,
    weekiso(d.full_date) as week_of_year,
    (dayofweekiso(d.full_date) in (6, 7)) as is_weekend,
    coalesce(h.is_public_holiday, false) as is_holiday,
    h.event_name,
    h.event_type,
    h.country_code,
    current_timestamp() as load_datetime
from date_spine d
left join holiday_events h
    on d.full_date = h.calendar_date
