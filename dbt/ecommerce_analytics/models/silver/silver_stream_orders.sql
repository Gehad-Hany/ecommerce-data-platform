with orders as (
    select *
    from {{ ref('stg_stream_orders') }}
),

cleaned as (
    select
        *,
        to_timestamp_ntz('2026-05-20 23:59:59') as stream_cutoff_timestamp,

        (order_approved_at > to_timestamp_ntz('2026-05-20 23:59:59'))
            as is_approved_after_stream_cutoff,

        (order_delivered_carrier_timestamp > to_timestamp_ntz('2026-05-20 23:59:59'))
            as is_carrier_after_stream_cutoff,

        (order_delivered_customer_timestamp > to_timestamp_ntz('2026-05-20 23:59:59'))
            as is_customer_delivery_after_stream_cutoff,

        (order_estimated_delivery_timestamp > to_timestamp_ntz('2026-05-20 23:59:59'))
            as is_estimated_delivery_after_stream_cutoff,

        (order_delivered_carrier_timestamp < order_purchase_timestamp)
            as has_carrier_before_purchase,

        (order_approved_at is not null
            and order_delivered_carrier_timestamp is not null
            and order_delivered_carrier_timestamp < order_approved_at)
            as has_carrier_before_approved,

        (order_delivered_customer_timestamp is not null
            and order_delivered_customer_timestamp < order_purchase_timestamp)
            as has_customer_delivery_before_purchase,

        (order_delivered_customer_timestamp is not null
            and order_delivered_carrier_timestamp is not null
            and order_delivered_customer_timestamp < order_delivered_carrier_timestamp)
            as has_customer_delivery_before_carrier,

        (order_estimated_delivery_timestamp < order_purchase_timestamp)
            as has_estimated_delivery_before_purchase,

        (order_status = 'delivered'
            and order_delivered_customer_timestamp is null)
            as is_missing_delivery_date,

        (order_status = 'delivered'
            and order_delivered_customer_timestamp is null
            and order_estimated_delivery_timestamp is not null
            and order_estimated_delivery_timestamp <= to_timestamp_ntz('2026-05-20 23:59:59'))
            as is_delivery_date_imputed,

        (order_status = 'canceled'
            and order_delivered_customer_timestamp is not null)
            as is_canceled_with_delivery_date,

        datediff(day, order_purchase_timestamp, to_timestamp_ntz('2026-05-20 23:59:59'))
            as order_age_days
    from orders
),

business_rules as (
    select
        *,
        (
            has_carrier_before_purchase
            or has_carrier_before_approved
            or has_customer_delivery_before_purchase
            or has_customer_delivery_before_carrier
            or has_estimated_delivery_before_purchase
        ) as has_invalid_date_sequence,

        (order_status in ('created', 'approved', 'invoiced', 'processing', 'shipped')
            and order_age_days > 30)
            as is_expired_unfulfilled,

        case
            when order_status in ('created', 'approved', 'invoiced', 'processing', 'shipped')
                and order_age_days > 30
                then 'expired_unfulfilled'
            else order_status
        end as clean_order_status,

        case
            when order_approved_at is null then null
            else order_approved_at
        end as clean_order_approved_timestamp,

        case
            when order_estimated_delivery_timestamp is null then null
            else order_estimated_delivery_timestamp
        end as clean_estimated_delivery_timestamp,

        case
            when has_carrier_before_purchase then null
            else order_delivered_carrier_timestamp
        end as clean_delivered_carrier_timestamp
    from cleaned
),

delivery_rules as (
    select
        *,
        case
            when order_status = 'delivered'
                and order_delivered_customer_timestamp is null
                then clean_estimated_delivery_timestamp
            when has_customer_delivery_before_purchase
                or has_customer_delivery_before_carrier
                then null
            else order_delivered_customer_timestamp
        end as clean_delivered_customer_timestamp
    from business_rules
)

select
    order_id,
    customer_id,
    'stream' as source_system,
    order_status as original_order_status,
    clean_order_status,

    order_purchase_date,
    order_purchase_time,

    to_date(clean_order_approved_timestamp) as order_approved_date,
    to_time(clean_order_approved_timestamp) as order_approved_time,

    to_date(clean_delivered_carrier_timestamp) as clean_delivered_carrier_date,
    to_time(clean_delivered_carrier_timestamp) as clean_delivered_carrier_time,

    to_date(clean_delivered_customer_timestamp) as clean_delivered_customer_date,
    to_time(clean_delivered_customer_timestamp) as clean_delivered_customer_time,

    to_date(clean_estimated_delivery_timestamp) as order_estimated_delivery_date,
    to_time(clean_estimated_delivery_timestamp) as order_estimated_delivery_time,

    order_age_days,
    is_expired_unfulfilled,
    is_missing_delivery_date,
    is_delivery_date_imputed,
    is_canceled_with_delivery_date,
    is_approved_after_stream_cutoff as is_approved_after_batch_cutoff,
    is_carrier_after_stream_cutoff as is_carrier_after_batch_cutoff,
    is_customer_delivery_after_stream_cutoff as is_customer_delivery_after_batch_cutoff,
    is_estimated_delivery_after_stream_cutoff as is_estimated_delivery_after_batch_cutoff,
    has_invalid_date_sequence,
    has_carrier_before_purchase,
    has_carrier_before_approved,
    has_customer_delivery_before_purchase,
    has_customer_delivery_before_carrier,
    has_estimated_delivery_before_purchase,

    (clean_order_status = 'delivered'
        and clean_delivered_customer_timestamp is not null
        and clean_estimated_delivery_timestamp is not null
        and to_date(clean_delivered_customer_timestamp) > to_date(clean_estimated_delivery_timestamp))
        as is_late_delivery,

    case
        when clean_order_status = 'delivered'
            and clean_delivered_customer_timestamp is not null
            and clean_estimated_delivery_timestamp is not null
            and to_date(clean_delivered_customer_timestamp) > to_date(clean_estimated_delivery_timestamp)
            then datediff(day, to_date(clean_estimated_delivery_timestamp), to_date(clean_delivered_customer_timestamp))
        else 0
    end as delivery_delay_days,

    case
        when clean_order_status = 'delivered'
            and clean_delivered_customer_timestamp is not null
            and not has_invalid_date_sequence
            then datediff(day, order_purchase_date, to_date(clean_delivered_customer_timestamp))
        else null
    end as delivery_days,

    case
        when clean_delivered_carrier_timestamp is not null
            and clean_order_approved_timestamp is not null
            and not has_carrier_before_approved
            then datediff(day, to_date(clean_order_approved_timestamp), to_date(clean_delivered_carrier_timestamp))
        else null
    end as approval_to_shipping_days
from delivery_rules
