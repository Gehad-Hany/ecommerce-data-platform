with validation_checks as (

    select
        'orders purchase dates are not after 2026-05-20' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where order_purchase_date > to_date('2026-05-20')

    union all

    select
        'orders purchase dates are shifted to 2024-2026' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where order_purchase_date < to_date('2024-01-01')
       or order_purchase_date > to_date('2026-05-20')

    union all

    select
        'orders approved dates are shifted to 2024-2026 when available' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where order_approved_date is not null
      and (
          order_approved_date < to_date('2024-01-01')
          or order_approved_date > to_date('2026-05-20')
      )

    union all

    select
        'orders carrier dates are shifted to 2024-2026 when available' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where clean_delivered_carrier_date is not null
      and (
          clean_delivered_carrier_date < to_date('2024-01-01')
          or clean_delivered_carrier_date > to_date('2026-05-20')
      )

    union all

    select
        'orders customer delivery dates are shifted to 2024-2026 when available' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where clean_delivered_customer_date is not null
      and (
          clean_delivered_customer_date < to_date('2024-01-01')
          or clean_delivered_customer_date > to_date('2026-05-20')
      )

    union all

    select
        'orders estimated delivery dates are shifted to 2024-2026 when available' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where order_estimated_delivery_date is not null
      and (
          order_estimated_delivery_date < to_date('2024-01-01')
          or order_estimated_delivery_date > to_date('2026-05-20')
      )

    union all

    select
        'orders have no null order_id' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where order_id is null or trim(order_id) = ''

    union all

    select
        'orders have no duplicate order_id' as check_name,
        count(*) as issue_count
    from (
        select order_id
        from {{ ref('silver_orders') }}
        group by order_id
        having count(*) > 1
    )

    union all

    select
        'expired unfulfilled orders are flagged consistently' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where clean_order_status = 'expired_unfulfilled'
      and is_expired_unfulfilled = false

    union all

    select
        'delivered orders missing delivery date are imputed when estimated date exists' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where original_order_status = 'delivered'
      and is_missing_delivery_date = true
      and order_estimated_delivery_date is not null
      and clean_delivered_customer_date is null

    union all

    select
        'late deliveries have positive delay days' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where is_late_delivery = true
      and delivery_delay_days <= 0

    union all

    select
        'non-late deliveries have zero delay days' as check_name,
        count(*) as issue_count
    from {{ ref('silver_orders') }}
    where is_late_delivery = false
      and delivery_delay_days <> 0

    union all

    select
        'customers text columns are trimmed and cased' as check_name,
        count(*) as issue_count
    from {{ ref('silver_customers') }}
    where customer_city <> lower(trim(customer_city))
       or customer_state <> upper(trim(customer_state))
       or customer_id <> trim(customer_id)
       or customer_unique_id <> trim(customer_unique_id)
       or customer_zip_code_prefix <> trim(customer_zip_code_prefix)

    union all

    select
        'sellers text columns are trimmed and cased' as check_name,
        count(*) as issue_count
    from {{ ref('silver_sellers') }}
    where seller_city <> lower(trim(seller_city))
       or seller_state <> upper(trim(seller_state))
       or seller_id <> trim(seller_id)
       or seller_zip_code_prefix <> trim(seller_zip_code_prefix)

    union all

    select
        'geolocation text columns are trimmed and cased' as check_name,
        count(*) as issue_count
    from {{ ref('silver_geolocation') }}
    where geolocation_city <> lower(trim(geolocation_city))
       or geolocation_state <> upper(trim(geolocation_state))
       or geolocation_zip_code_prefix <> trim(geolocation_zip_code_prefix)

    union all

    select
        'product categories are not null after cleaning' as check_name,
        count(*) as issue_count
    from {{ ref('silver_products') }}
    where clean_product_category_name is null
       or trim(clean_product_category_name) = ''

    union all

    select
        'products with unknown category are marked as missing metadata' as check_name,
        count(*) as issue_count
    from {{ ref('silver_products') }}
    where clean_product_category_name = 'unknown'
      and is_missing_product_metadata = false

    union all

    select
        'product photos quantity is not null after cleaning' as check_name,
        count(*) as issue_count
    from {{ ref('silver_products') }}
    where product_photos_qty is null

    union all

    select
        'invalid payments have null clean payment value' as check_name,
        count(*) as issue_count
    from {{ ref('silver_order_payments') }}
    where is_invalid_payment_value = true
      and clean_payment_value is not null

    union all

    select
        'valid payments keep positive clean payment value' as check_name,
        count(*) as issue_count
    from {{ ref('silver_order_payments') }}
    where is_invalid_payment_value = false
      and (clean_payment_value is null or clean_payment_value <= 0)

    union all

    select
        'order items shipping dates are shifted to 2024-2026 when available' as check_name,
        count(*) as issue_count
    from {{ ref('silver_order_items') }}
    where shipping_limit_date is not null
      and (
          shipping_limit_date < to_date('2024-01-01')
          or shipping_limit_date > to_date('2026-05-20')
      )

    union all

    select
        'order reviews dates are shifted to 2024-2026 when available' as check_name,
        count(*) as issue_count
    from {{ ref('silver_order_reviews') }}
    where (
        review_creation_date is not null
        and (
            review_creation_date < to_date('2024-01-01')
            or review_creation_date > to_date('2026-05-20')
        )
    )
    or (
        review_answer_date is not null
        and (
            review_answer_date < to_date('2024-01-01')
            or review_answer_date > to_date('2026-05-20')
        )
    )

    union all

    select
        'reviews scores are within 1 to 5' as check_name,
        count(*) as issue_count
    from {{ ref('silver_order_reviews') }}
    where review_score is not null
      and (review_score < 1 or review_score > 5)

    union all

    select
        'brazil holiday dates are shifted to 2024-2026 and before cutoff' as check_name,
        count(*) as issue_count
    from {{ ref('silver_brazil_holidays') }}
    where calendar_date < to_date('2024-01-01')
       or calendar_date > to_date('2026-05-20')

    union all

    select
        'silver output does not expose old timestamp helper columns' as check_name,
        count(*) as issue_count
    from information_schema.columns
    where table_schema = 'SILVER'
      and table_name in (
          'SILVER_ORDERS',
          'SILVER_ORDER_ITEMS',
          'SILVER_ORDER_REVIEWS',
          'SILVER_BRAZIL_HOLIDAYS'
      )
      and (
          lower(column_name) like '%timestamp%'
          or lower(column_name) like '%_shifted%'
      )
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
