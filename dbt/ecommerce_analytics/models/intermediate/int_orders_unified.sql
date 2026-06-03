with unioned as (
    select
        order_id,
        customer_id,
        source_system,
        original_order_status,
        clean_order_status,
        order_purchase_date,
        order_purchase_time,
        order_approved_date,
        order_approved_time,
        clean_delivered_carrier_date,
        clean_delivered_carrier_time,
        clean_delivered_customer_date,
        clean_delivered_customer_time,
        order_estimated_delivery_date,
        order_estimated_delivery_time,
        order_age_days,
        is_expired_unfulfilled,
        is_missing_delivery_date,
        is_delivery_date_imputed,
        is_canceled_with_delivery_date,
        is_approved_after_batch_cutoff,
        is_carrier_after_batch_cutoff,
        is_customer_delivery_after_batch_cutoff,
        is_estimated_delivery_after_batch_cutoff,
        has_invalid_date_sequence,
        has_carrier_before_purchase,
        has_carrier_before_approved,
        has_customer_delivery_before_purchase,
        has_customer_delivery_before_carrier,
        has_estimated_delivery_before_purchase,
        is_late_delivery,
        delivery_delay_days,
        delivery_days,
        approval_to_shipping_days,
        1 as source_priority
    from {{ ref('silver_orders') }}

    union all

    select
        order_id,
        customer_id,
        source_system,
        original_order_status,
        clean_order_status,
        order_purchase_date,
        order_purchase_time,
        order_approved_date,
        order_approved_time,
        clean_delivered_carrier_date,
        clean_delivered_carrier_time,
        clean_delivered_customer_date,
        clean_delivered_customer_time,
        order_estimated_delivery_date,
        order_estimated_delivery_time,
        order_age_days,
        is_expired_unfulfilled,
        is_missing_delivery_date,
        is_delivery_date_imputed,
        is_canceled_with_delivery_date,
        is_approved_after_batch_cutoff,
        is_carrier_after_batch_cutoff,
        is_customer_delivery_after_batch_cutoff,
        is_estimated_delivery_after_batch_cutoff,
        has_invalid_date_sequence,
        has_carrier_before_purchase,
        has_carrier_before_approved,
        has_customer_delivery_before_purchase,
        has_customer_delivery_before_carrier,
        has_estimated_delivery_before_purchase,
        is_late_delivery,
        delivery_delay_days,
        delivery_days,
        approval_to_shipping_days,
        2 as source_priority
    from {{ ref('silver_stream_orders') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by order_id
            order by source_priority desc
        ) as rn
    from unioned
    where order_id is not null
)

select
    order_id,
    customer_id,
    source_system,
    original_order_status,
    clean_order_status,
    order_purchase_date,
    order_purchase_time,
    order_approved_date,
    order_approved_time,
    clean_delivered_carrier_date,
    clean_delivered_carrier_time,
    clean_delivered_customer_date,
    clean_delivered_customer_time,
    order_estimated_delivery_date,
    order_estimated_delivery_time,
    order_age_days,
    is_expired_unfulfilled,
    is_missing_delivery_date,
    is_delivery_date_imputed,
    is_canceled_with_delivery_date,
    is_approved_after_batch_cutoff,
    is_carrier_after_batch_cutoff,
    is_customer_delivery_after_batch_cutoff,
    is_estimated_delivery_after_batch_cutoff,
    has_invalid_date_sequence,
    has_carrier_before_purchase,
    has_carrier_before_approved,
    has_customer_delivery_before_purchase,
    has_customer_delivery_before_carrier,
    has_estimated_delivery_before_purchase,
    is_late_delivery,
    delivery_delay_days,
    delivery_days,
    approval_to_shipping_days
from deduplicated
where rn = 1
