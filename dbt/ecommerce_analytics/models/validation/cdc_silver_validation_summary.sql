with validation_checks as (

    select
        'cdc customers have no null customer_id' as check_name,
        count(*) as issue_count
    from {{ ref('silver_cdc_customers') }}
    where customer_id is null or trim(customer_id) = ''

    union all

    select
        'cdc products have no null product_id' as check_name,
        count(*) as issue_count
    from {{ ref('silver_cdc_products') }}
    where product_id is null or trim(product_id) = ''

    union all

    select
        'cdc sellers have no null seller_id' as check_name,
        count(*) as issue_count
    from {{ ref('silver_cdc_sellers') }}
    where seller_id is null or trim(seller_id) = ''

    union all

    select
        'cdc customers text columns are trimmed and cased' as check_name,
        count(*) as issue_count
    from {{ ref('silver_cdc_customers') }}
    where customer_city <> lower(trim(customer_city))
       or customer_state <> upper(trim(customer_state))
       or customer_id <> trim(customer_id)
       or customer_unique_id <> trim(customer_unique_id)
       or customer_zip_code_prefix <> trim(customer_zip_code_prefix)

    union all

    select
        'cdc sellers text columns are trimmed and cased' as check_name,
        count(*) as issue_count
    from {{ ref('silver_cdc_sellers') }}
    where seller_city <> lower(trim(seller_city))
       or seller_state <> upper(trim(seller_state))
       or seller_id <> trim(seller_id)
       or seller_zip_code_prefix <> trim(seller_zip_code_prefix)

    union all

    select
        'cdc product categories are not null after cleaning' as check_name,
        count(*) as issue_count
    from {{ ref('silver_cdc_products') }}
    where clean_product_category_name is null
       or trim(clean_product_category_name) = ''

    union all

    select
        'cdc event dates and times are available' as check_name,
        count(*) as issue_count
    from (
        select cdc_event_date, cdc_event_time from {{ ref('silver_cdc_customers') }}
        union all
        select cdc_event_date, cdc_event_time from {{ ref('silver_cdc_products') }}
        union all
        select cdc_event_date, cdc_event_time from {{ ref('silver_cdc_sellers') }}
    )
    where cdc_event_date is null
       or cdc_event_time is null

    union all

    select
        'cdc operations are readable values' as check_name,
        count(*) as issue_count
    from (
        select cdc_operation from {{ ref('silver_cdc_customers') }}
        union all
        select cdc_operation from {{ ref('silver_cdc_products') }}
        union all
        select cdc_operation from {{ ref('silver_cdc_sellers') }}
    )
    where cdc_operation not in ('insert', 'update', 'delete', 'snapshot', 'unknown')
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
