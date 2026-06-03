with validation_checks as (

    select
        'stream orders have no null order_id' as check_name,
        count(*) as issue_count
    from {{ ref('silver_stream_orders') }}
    where order_id is null or trim(order_id) = ''

    union all

    select
        'stream orders have no duplicate order_id' as check_name,
        count(*) as issue_count
    from (
        select order_id
        from {{ ref('silver_stream_orders') }}
        group by order_id
        having count(*) > 1
    )

    union all

    select
        'stream customers have no duplicate customer_id' as check_name,
        count(*) as issue_count
    from (
        select customer_id
        from {{ ref('silver_stream_customers') }}
        group by customer_id
        having count(*) > 1
    )

    union all

    select
        'stream customers text columns are trimmed and cased' as check_name,
        count(*) as issue_count
    from {{ ref('silver_stream_customers') }}
    where customer_city <> lower(trim(customer_city))
       or customer_state <> upper(trim(customer_state))
       or customer_id <> trim(customer_id)
       or customer_unique_id <> trim(customer_unique_id)
       or customer_zip_code_prefix <> trim(customer_zip_code_prefix)

    union all

    select
        'stream expired unfulfilled orders are flagged consistently' as check_name,
        count(*) as issue_count
    from {{ ref('silver_stream_orders') }}
    where clean_order_status = 'expired_unfulfilled'
      and is_expired_unfulfilled = false

    union all

    select
        'stream delivered orders missing delivery date are imputed when estimated date exists' as check_name,
        count(*) as issue_count
    from {{ ref('silver_stream_orders') }}
    where original_order_status = 'delivered'
      and is_missing_delivery_date = true
      and order_estimated_delivery_date is not null
      and clean_delivered_customer_date is null

    union all

    select
        'stream late deliveries have positive delay days' as check_name,
        count(*) as issue_count
    from {{ ref('silver_stream_orders') }}
    where is_late_delivery = true
      and delivery_delay_days <= 0

    union all

    select
        'stream non-late deliveries have zero delay days' as check_name,
        count(*) as issue_count
    from {{ ref('silver_stream_orders') }}
    where is_late_delivery = false
      and delivery_delay_days <> 0

    union all

    select
        'stream invalid payments have null clean payment value' as check_name,
        count(*) as issue_count
    from {{ ref('silver_stream_order_payments') }}
    where is_invalid_payment_value = true
      and clean_payment_value is not null

    union all

    select
        'stream valid payments keep positive clean payment value' as check_name,
        count(*) as issue_count
    from {{ ref('silver_stream_order_payments') }}
    where is_invalid_payment_value = false
      and (clean_payment_value is null or clean_payment_value <= 0)

    union all

    select
        'stream reviews scores are within 1 to 5' as check_name,
        count(*) as issue_count
    from {{ ref('silver_stream_order_reviews') }}
    where review_score is not null
      and (review_score < 1 or review_score > 5)
)

select
    check_name,
    issue_count,
    case
        when issue_count = 0 then 'PASS'
        else 'FAIL'
    end as validation_status
from validation_checks
order by validation_status desc, check_name
