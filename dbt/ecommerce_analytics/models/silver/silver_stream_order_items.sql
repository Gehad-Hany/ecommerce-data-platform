select
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    i.shipping_limit_date,
    i.shipping_limit_time,
    (i.shipping_limit_date > to_date('2026-05-20')) as is_shipping_limit_after_batch_cutoff,
    i.price,
    i.freight_value,
    (i.price <= 0) as is_invalid_price,
    (i.freight_value < 0) as is_invalid_freight_value
from {{ ref('stg_stream_order_items') }} i
