{{ config(
    materialized='incremental',
    unique_key=['order_id', 'order_item_id'],
    incremental_strategy='merge',
    on_schema_change='sync_all_columns'
) }}

with order_items as (
    select *
    from {{ ref('int_order_items_unified') }}
),

orders as (
    select *
    from {{ ref('int_orders_unified') }}
),

primary_payment as (
    select *
    from {{ ref('dim_payment') }}
    qualify row_number() over (
        partition by order_id
        order by payment_sequential
    ) = 1
),

primary_review as (
    select *
    from {{ ref('dim_review') }}
    qualify row_number() over (
        partition by order_id
        order by review_creation_date_key desc nulls last, review_sk
    ) = 1
)

select
    abs(hash(i.order_id, i.order_item_id)) as sales_sk,

    i.order_id,
    i.order_item_id,
    o.original_order_status as order_status,
    o.clean_order_status,

    to_number(to_char(o.order_purchase_date, 'YYYYMMDD')) as order_purchase_date_key,
    to_number(to_char(o.order_approved_date, 'YYYYMMDD')) as order_approved_date_key,
    to_number(to_char(o.clean_delivered_carrier_date, 'YYYYMMDD')) as order_carrier_date_key,
    to_number(to_char(o.clean_delivered_customer_date, 'YYYYMMDD')) as order_delivered_customer_date_key,
    to_number(to_char(o.order_estimated_delivery_date, 'YYYYMMDD')) as order_estimated_delivery_date_key,
    to_number(to_char(i.shipping_limit_date, 'YYYYMMDD')) as shipping_limit_date_key,

    o.order_purchase_time,

    i.price,
    i.freight_value,
    coalesce(i.price, 0) + coalesce(i.freight_value, 0) as total_price,
    1 as total_quantity,

    case
        when o.clean_delivered_carrier_date is null
            or i.shipping_limit_date is null
            or o.has_invalid_date_sequence
            then null
        when o.clean_delivered_carrier_date <= i.shipping_limit_date
            then true
        else false
    end as is_shipped_on_time,

    o.is_expired_unfulfilled,
    o.is_late_delivery,

    case
        when o.clean_delivered_carrier_date is null
            or i.shipping_limit_date is null
            or o.has_invalid_date_sequence
            then null
        else datediff(day, i.shipping_limit_date, o.clean_delivered_carrier_date)
    end as shipping_delay_days,

    o.delivery_delay_days,
    o.delivery_days,
    o.approval_to_shipping_days,

    p.product_sk,
    pay.payment_sk,
    r.review_sk,
    c.customer_sk,
    s.seller_sk,
    current_timestamp() as load_datetime
from order_items i
inner join orders o
    on i.order_id = o.order_id
left join {{ ref('dim_product') }} p
    on i.product_id = p.product_id
    and o.order_purchase_date >= p.start_date
    and (
        p.end_date is null
        or o.order_purchase_date < p.end_date
    )
left join primary_payment pay
    on i.order_id = pay.order_id
left join primary_review r
    on i.order_id = r.order_id
left join {{ ref('dim_customer') }} c
    on o.customer_id = c.customer_id
    and o.order_purchase_date >= c.start_date
    and (
        c.end_date is null
        or o.order_purchase_date < c.end_date
    )
left join {{ ref('dim_seller') }} s
    on i.seller_id = s.seller_id
    and o.order_purchase_date >= s.start_date
    and (
        s.end_date is null
        or o.order_purchase_date < s.end_date
    )
