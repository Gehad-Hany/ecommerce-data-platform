select
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value,
    (p.payment_value <= 0) as is_invalid_payment_value,
    case
        when p.payment_value <= 0 then null
        else p.payment_value
    end as clean_payment_value
from {{ ref('stg_stream_order_payments') }} p
