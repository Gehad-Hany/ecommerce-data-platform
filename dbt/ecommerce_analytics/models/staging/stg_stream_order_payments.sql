with raw_payments as (
    select
        nullif(trim("order_id"), '') as order_id,
        cast("payment_sequential" as number(38, 0)) as payment_sequential,
        nullif(lower(trim("payment_type")), '') as payment_type,
        cast("payment_installments" as number(38, 0)) as payment_installments,
        cast("payment_value" as number(12, 2)) as payment_value,
        "ingested_at" as ingested_at
    from {{ source('raw_stream', 'RAW_PAYMENTS') }}
    where nullif(trim("order_id"), '') is not null
),

ranked_payments as (
    select
        *,
        row_number() over (
            partition by order_id, payment_sequential
            order by ingested_at desc nulls last
        ) as rn
    from raw_payments
)

select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
from ranked_payments
where rn = 1
