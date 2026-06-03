with unioned as (
    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        shipping_limit_time,
        is_shipping_limit_after_batch_cutoff,
        price,
        freight_value,
        is_invalid_price,
        is_invalid_freight_value,
        'batch' as source_system,
        1 as source_priority
    from {{ ref('silver_order_items') }}

    union all

    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        shipping_limit_time,
        is_shipping_limit_after_batch_cutoff,
        price,
        freight_value,
        is_invalid_price,
        is_invalid_freight_value,
        'stream' as source_system,
        2 as source_priority
    from {{ ref('silver_stream_order_items') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by order_id, order_item_id
            order by source_priority desc
        ) as rn
    from unioned
    where order_id is not null
      and order_item_id is not null
)

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    shipping_limit_time,
    is_shipping_limit_after_batch_cutoff,
    price,
    freight_value,
    is_invalid_price,
    is_invalid_freight_value,
    source_system
from deduplicated
where rn = 1
