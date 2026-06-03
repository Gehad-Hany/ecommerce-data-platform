with validation_checks as (

    select
        'gold bridge_geolocation has rows' as check_name,
        case when count(*) = 0 then 1 else 0 end as issue_count
    from {{ ref('bridge_geolocation') }}

    union all

    select
        'gold dim_customer has rows' as check_name,
        case when count(*) = 0 then 1 else 0 end as issue_count
    from {{ ref('dim_customer') }}

    union all

    select
        'gold dim_date has rows' as check_name,
        case when count(*) = 0 then 1 else 0 end as issue_count
    from {{ ref('dim_date') }}

    union all

    select
        'gold dim_geolocation has rows' as check_name,
        case when count(*) = 0 then 1 else 0 end as issue_count
    from {{ ref('dim_geolocation') }}

    union all

    select
        'gold dim_payment has rows' as check_name,
        case when count(*) = 0 then 1 else 0 end as issue_count
    from {{ ref('dim_payment') }}

    union all

    select
        'gold dim_product has rows' as check_name,
        case when count(*) = 0 then 1 else 0 end as issue_count
    from {{ ref('dim_product') }}

    union all

    select
        'gold dim_review has rows' as check_name,
        case when count(*) = 0 then 1 else 0 end as issue_count
    from {{ ref('dim_review') }}

    union all

    select
        'gold dim_seller has rows' as check_name,
        case when count(*) = 0 then 1 else 0 end as issue_count
    from {{ ref('dim_seller') }}

    union all

    select
        'gold sales_fact has rows' as check_name,
        case when count(*) = 0 then 1 else 0 end as issue_count
    from {{ ref('sales_fact') }}

    union all

    select
        'sales_fact row count matches unified order item grain' as check_name,
        case when f.fact_count <> e.expected_count then 1 else 0 end as issue_count
    from (select count(*) as fact_count from {{ ref('sales_fact') }}) f
    cross join (
        select count(*) as expected_count
        from {{ ref('int_order_items_unified') }} i
        inner join {{ ref('int_orders_unified') }} o
            on i.order_id = o.order_id
    ) e

    union all

    select
        'sales_fact has no duplicate order item grain' as check_name,
        count(*) as issue_count
    from (
        select order_id, order_item_id
        from {{ ref('sales_fact') }}
        group by order_id, order_item_id
        having count(*) > 1
    )

    union all

    select
        'sales_fact order status columns are populated' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }}
    where order_status is null
       or clean_order_status is null

    union all

    select
        'sales_fact order status matches unified orders' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    inner join {{ ref('int_orders_unified') }} o
        on f.order_id = o.order_id
    where coalesce(f.order_status, '') <> coalesce(o.original_order_status, '')
       or coalesce(f.clean_order_status, '') <> coalesce(o.clean_order_status, '')

    union all

    select
        'dim_date has no duplicate date_key' as check_name,
        count(*) as issue_count
    from (
        select date_key
        from {{ ref('dim_date') }}
        group by date_key
        having count(*) > 1
    )

    union all

    select
        'bridge_geolocation has no duplicate zip_code_prefix' as check_name,
        count(*) as issue_count
    from (
        select zip_code_prefix
        from {{ ref('bridge_geolocation') }}
        group by zip_code_prefix
        having count(*) > 1
    )

    union all

    select
        'bridge_geolocation row count matches silver zip prefixes' as check_name,
        case when b.bridge_count <> s.silver_count then 1 else 0 end as issue_count
    from (select count(*) as bridge_count from {{ ref('bridge_geolocation') }}) b
    cross join (select count(*) as silver_count from {{ ref('silver_zip_code_prefixes') }}) s

    union all

    select
        'dim_geolocation zip prefixes exist in bridge_geolocation' as check_name,
        count(*) as issue_count
    from {{ ref('dim_geolocation') }} g
    left join {{ ref('bridge_geolocation') }} b
        on g.zip_code_prefix = b.zip_code_prefix
    where b.zip_code_prefix is null

    union all

    select
        'sales_fact required dimension keys are not null' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }}
    where product_sk is null
       or customer_sk is null
       or seller_sk is null

    union all

    select
        'sales_fact product_sk exists in dim_product' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_product') }} d
        on f.product_sk = d.product_sk
    where f.product_sk is not null
      and d.product_sk is null

    union all

    select
        'sales_fact payment_sk exists in dim_payment' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_payment') }} d
        on f.payment_sk = d.payment_sk
    where f.payment_sk is not null
      and d.payment_sk is null

    union all

    select
        'sales_fact review_sk exists in dim_review' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_review') }} d
        on f.review_sk = d.review_sk
    where f.review_sk is not null
      and d.review_sk is null

    union all

    select
        'sales_fact customer_sk exists in dim_customer' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_customer') }} d
        on f.customer_sk = d.customer_sk
    where f.customer_sk is not null
      and d.customer_sk is null

    union all

    select
        'sales_fact seller_sk exists in dim_seller' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_seller') }} d
        on f.seller_sk = d.seller_sk
    where f.seller_sk is not null
      and d.seller_sk is null

    union all

    select
        'sales_fact purchase date keys exist in dim_date' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_date') }} d
        on f.order_purchase_date_key = d.date_key
    where f.order_purchase_date_key is not null
      and d.date_key is null

    union all

    select
        'sales_fact approved date keys exist in dim_date' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_date') }} d
        on f.order_approved_date_key = d.date_key
    where f.order_approved_date_key is not null
      and d.date_key is null

    union all

    select
        'sales_fact carrier date keys exist in dim_date' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_date') }} d
        on f.order_carrier_date_key = d.date_key
    where f.order_carrier_date_key is not null
      and d.date_key is null

    union all

    select
        'sales_fact delivered customer date keys exist in dim_date' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_date') }} d
        on f.order_delivered_customer_date_key = d.date_key
    where f.order_delivered_customer_date_key is not null
      and d.date_key is null

    union all

    select
        'sales_fact estimated delivery date keys exist in dim_date' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_date') }} d
        on f.order_estimated_delivery_date_key = d.date_key
    where f.order_estimated_delivery_date_key is not null
      and d.date_key is null

    union all

    select
        'sales_fact shipping limit date keys exist in dim_date' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }} f
    left join {{ ref('dim_date') }} d
        on f.shipping_limit_date_key = d.date_key
    where f.shipping_limit_date_key is not null
      and d.date_key is null

    union all

    select
        'all gold tables have load_datetime populated' as check_name,
        count(*) as issue_count
    from (
        select load_datetime from {{ ref('bridge_geolocation') }}
        union all
        select load_datetime from {{ ref('dim_customer') }}
        union all
        select load_datetime from {{ ref('dim_date') }}
        union all
        select load_datetime from {{ ref('dim_geolocation') }}
        union all
        select load_datetime from {{ ref('dim_payment') }}
        union all
        select load_datetime from {{ ref('dim_product') }}
        union all
        select load_datetime from {{ ref('dim_review') }}
        union all
        select load_datetime from {{ ref('dim_seller') }}
        union all
        select load_datetime from {{ ref('sales_fact') }}
    )
    where load_datetime is null

    union all

    select
        'dim_customer has one current row per customer' as check_name,
        count(*) as issue_count
    from (
        select customer_id
        from {{ ref('dim_customer') }}
        where is_current
        group by customer_id
        having count(*) > 1
    )

    union all

    select
        'dim_product has one current row per product' as check_name,
        count(*) as issue_count
    from (
        select product_id
        from {{ ref('dim_product') }}
        where is_current
        group by product_id
        having count(*) > 1
    )

    union all

    select
        'dim_seller has one current row per seller' as check_name,
        count(*) as issue_count
    from (
        select seller_id
        from {{ ref('dim_seller') }}
        where is_current
        group by seller_id
        having count(*) > 1
    )

    union all

    select
        'dim_customer SCD2 dates are valid' as check_name,
        count(*) as issue_count
    from {{ ref('dim_customer') }}
    where start_date is null
       or (end_date is not null and end_date < start_date)
       or (is_current and end_date is not null)
       or (not is_current and end_date is null)

    union all

    select
        'dim_product SCD2 dates are valid' as check_name,
        count(*) as issue_count
    from {{ ref('dim_product') }}
    where start_date is null
       or (end_date is not null and end_date < start_date)
       or (is_current and end_date is not null)
       or (not is_current and end_date is null)

    union all

    select
        'dim_seller SCD2 dates are valid' as check_name,
        count(*) as issue_count
    from {{ ref('dim_seller') }}
    where start_date is null
       or (end_date is not null and end_date < start_date)
       or (is_current and end_date is not null)
       or (not is_current and end_date is null)

    union all

    select
        'cdc customer events are represented in dim_customer SCD2' as check_name,
        count(*) as issue_count
    from {{ ref('silver_cdc_customers') }} cdc
    left join {{ ref('dim_customer') }} d
        on cdc.customer_id = d.customer_id
       and cdc.cdc_event_date = d.start_date
    where d.customer_id is null

    union all

    select
        'cdc product events are represented in dim_product SCD2' as check_name,
        count(*) as issue_count
    from {{ ref('silver_cdc_products') }} cdc
    left join {{ ref('dim_product') }} d
        on cdc.product_id = d.product_id
       and cdc.cdc_event_date = d.start_date
    where d.product_id is null

    union all

    select
        'cdc seller events are represented in dim_seller SCD2' as check_name,
        count(*) as issue_count
    from {{ ref('silver_cdc_sellers') }} cdc
    left join {{ ref('dim_seller') }} d
        on cdc.seller_id = d.seller_id
       and cdc.cdc_event_date = d.start_date
    where d.seller_id is null

    union all

    select
        'is_shipped_on_time agrees with shipping_delay_days' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }}
    where (is_shipped_on_time = true and shipping_delay_days > 0)
       or (is_shipped_on_time = false and shipping_delay_days <= 0)

    union all

    select
        'late deliveries have positive delivery_delay_days' as check_name,
        count(*) as issue_count
    from {{ ref('sales_fact') }}
    where is_late_delivery = true
      and delivery_delay_days <= 0

    union all

    select
        'review response days are not negative' as check_name,
        count(*) as issue_count
    from {{ ref('dim_review') }}
    where review_response_days < 0
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
