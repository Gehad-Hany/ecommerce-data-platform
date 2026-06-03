with unioned as (
    select
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value,
        is_invalid_payment_value,
        clean_payment_value,
        'batch' as source_system,
        1 as source_priority
    from {{ ref('silver_order_payments') }}

    union all

    select
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value,
        is_invalid_payment_value,
        clean_payment_value,
        'stream' as source_system,
        2 as source_priority
    from {{ ref('silver_stream_order_payments') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by order_id, payment_sequential
            order by source_priority desc
        ) as rn
    from unioned
    where order_id is not null
      and payment_sequential is not null
)

select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    is_invalid_payment_value,
    clean_payment_value,
    source_system
from deduplicated
where rn = 1
