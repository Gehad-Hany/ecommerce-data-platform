select
    trim(order_id) as order_id,
    payment_sequential,
    lower(trim(payment_type)) as payment_type,
    payment_installments,
    payment_value
from {{ source('raw_batch', 'ORDER_PAYMENTS') }}
