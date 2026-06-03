select
    trim(order_id) as order_id,
    order_item_id,
    trim(product_id) as product_id,
    trim(seller_id) as seller_id,
    shipping_limit_date as shipping_limit_timestamp,
    dateadd(year, 8, shipping_limit_date) as shipping_limit_timestamp_shifted,
    to_date(dateadd(year, 8, shipping_limit_date)) as shipping_limit_date,
    to_time(dateadd(year, 8, shipping_limit_date)) as shipping_limit_time,
    price,
    freight_value
from {{ source('raw_batch', 'ORDER_ITEMS') }}
