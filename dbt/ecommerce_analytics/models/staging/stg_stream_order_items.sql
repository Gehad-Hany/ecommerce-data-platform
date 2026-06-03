with raw_order_items as (
    select
        nullif(trim("order_id"), '') as order_id,
        cast("order_item_id" as number(38, 0)) as order_item_id,
        nullif(trim("product_id"), '') as product_id,
        nullif(trim("seller_id"), '') as seller_id,
        "shipping_limit_date" as shipping_limit_timestamp,
        dateadd(year, 8, "shipping_limit_date") as shipping_limit_timestamp_shifted,
        to_date(dateadd(year, 8, "shipping_limit_date")) as shipping_limit_date,
        to_time(dateadd(year, 8, "shipping_limit_date")) as shipping_limit_time,
        cast("price" as number(12, 2)) as price,
        cast("freight_value" as number(12, 2)) as freight_value,
        "ingested_at" as ingested_at
    from {{ source('raw_stream', 'RAW_ORDER_ITEMS') }}
    where nullif(trim("order_id"), '') is not null
),

ranked_items as (
    select
        *,
        row_number() over (
            partition by order_id, order_item_id
            order by ingested_at desc nulls last
        ) as rn
    from raw_order_items
)

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_timestamp,
    shipping_limit_timestamp_shifted,
    shipping_limit_date,
    shipping_limit_time,
    price,
    freight_value
from ranked_items
where rn = 1
