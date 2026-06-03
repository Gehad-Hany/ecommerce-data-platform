select
    row_number() over (order by order_id, payment_sequential) as payment_sk,
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    current_timestamp() as load_datetime
from {{ ref('int_order_payments_unified') }}
where order_id is not null
  and payment_sequential is not null
