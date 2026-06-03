with source_orders as (
    select
        trim(order_id) as order_id,
        trim(customer_id) as customer_id,
        lower(trim(order_status)) as order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date as order_delivered_carrier_timestamp,
        order_delivered_customer_date as order_delivered_customer_timestamp,
        order_estimated_delivery_date as order_estimated_delivery_timestamp
    from {{ source('raw_batch', 'ORDERS') }}
),

shifted as (
    select
        *,
        dateadd(year, 8, order_purchase_timestamp) as order_purchase_timestamp_shifted,
        dateadd(year, 8, order_approved_at) as order_approved_at_shifted,
        dateadd(year, 8, order_delivered_carrier_timestamp) as order_delivered_carrier_timestamp_shifted,
        dateadd(year, 8, order_delivered_customer_timestamp) as order_delivered_customer_timestamp_shifted,
        dateadd(year, 8, order_estimated_delivery_timestamp) as order_estimated_delivery_timestamp_shifted
    from source_orders
)

select
    *,
    to_date(order_purchase_timestamp_shifted) as order_purchase_date,
    to_time(order_purchase_timestamp_shifted) as order_purchase_time,
    to_date(order_approved_at_shifted) as order_approved_date,
    to_time(order_approved_at_shifted) as order_approved_time,
    to_date(order_delivered_carrier_timestamp_shifted) as order_delivered_carrier_date,
    to_time(order_delivered_carrier_timestamp_shifted) as order_delivered_carrier_time,
    to_date(order_delivered_customer_timestamp_shifted) as order_delivered_customer_date,
    to_time(order_delivered_customer_timestamp_shifted) as order_delivered_customer_time,
    to_date(order_estimated_delivery_timestamp_shifted) as order_estimated_delivery_date,
    to_time(order_estimated_delivery_timestamp_shifted) as order_estimated_delivery_time
from shifted
where order_purchase_timestamp_shifted <= to_timestamp_ntz('2026-05-20 23:59:59')
