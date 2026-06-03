with raw_orders as (
    select
        nullif(lower(trim("event_type")), '') as event_type,
        nullif(trim("order_id"), '') as order_id,
        nullif(trim("customer_id"), '') as customer_id,
        nullif(lower(trim("order_status")), '') as order_status,
        "event_timestamp" as event_timestamp,
        dateadd(year, 8, "event_timestamp") as event_timestamp_shifted,
        "order_purchase_timestamp" as order_purchase_timestamp,
        dateadd(year, 8, "order_purchase_timestamp") as order_purchase_timestamp_shifted,
        "order_approved_at" as order_approved_at,
        dateadd(year, 8, "order_approved_at") as order_approved_at_shifted,
        "order_delivered_carrier_date" as order_delivered_carrier_timestamp,
        dateadd(year, 8, "order_delivered_carrier_date") as order_delivered_carrier_timestamp_shifted,
        "order_delivered_customer_date" as order_delivered_customer_timestamp,
        dateadd(year, 8, "order_delivered_customer_date") as order_delivered_customer_timestamp_shifted,
        "order_estimated_delivery_date" as order_estimated_delivery_timestamp,
        dateadd(year, 8, "order_estimated_delivery_date") as order_estimated_delivery_timestamp_shifted,
        "ingested_at" as ingested_at
    from {{ source('raw_stream', 'RAW_ORDERS') }}
    where nullif(trim("order_id"), '') is not null
),

latest_status as (
    select
        *,
        row_number() over (
            partition by order_id
            order by event_timestamp_shifted desc nulls last, ingested_at desc nulls last
        ) as rn
    from raw_orders
),

timestamps_agg as (
    select
        order_id,
        max(order_purchase_timestamp_shifted) as order_purchase_timestamp,
        max(order_approved_at_shifted) as order_approved_at,
        max(order_delivered_carrier_timestamp_shifted) as order_delivered_carrier_timestamp,
        max(order_delivered_customer_timestamp_shifted) as order_delivered_customer_timestamp,
        max(order_estimated_delivery_timestamp_shifted) as order_estimated_delivery_timestamp
    from raw_orders
    group by order_id
),

latest_orders as (
    select
        l.event_type as latest_event_type,
        l.order_id,
        l.customer_id,
        l.order_status,
        l.event_timestamp_shifted as last_event_timestamp,
        coalesce(t.order_purchase_timestamp, l.event_timestamp_shifted) as order_purchase_timestamp,
        case
            when l.order_status in ('approved', 'shipped', 'delivered') then
                coalesce(t.order_approved_at, t.order_purchase_timestamp, l.event_timestamp_shifted)
            else null
        end as order_approved_at,
        case
            when l.order_status in ('shipped', 'delivered') then
                coalesce(
                    t.order_delivered_carrier_timestamp,
                    t.order_approved_at,
                    t.order_purchase_timestamp,
                    l.event_timestamp_shifted
                )
            else null
        end as order_delivered_carrier_timestamp,
        case
            when l.order_status = 'delivered' then
                coalesce(t.order_delivered_customer_timestamp, l.event_timestamp_shifted)
            else null
        end as order_delivered_customer_timestamp,
        t.order_estimated_delivery_timestamp
    from latest_status l
    inner join timestamps_agg t
        on l.order_id = t.order_id
    where l.rn = 1
)

select
    *,
    to_date(order_purchase_timestamp) as order_purchase_date,
    to_time(order_purchase_timestamp) as order_purchase_time,
    to_date(order_approved_at) as order_approved_date,
    to_time(order_approved_at) as order_approved_time,
    to_date(order_delivered_carrier_timestamp) as order_delivered_carrier_date,
    to_time(order_delivered_carrier_timestamp) as order_delivered_carrier_time,
    to_date(order_delivered_customer_timestamp) as order_delivered_customer_date,
    to_time(order_delivered_customer_timestamp) as order_delivered_customer_time,
    to_date(order_estimated_delivery_timestamp) as order_estimated_delivery_date,
    to_time(order_estimated_delivery_timestamp) as order_estimated_delivery_time
from latest_orders
