with validation_checks as (

    select
        'unified customers have no duplicate customer_id' as check_name,
        count(*) as issue_count
    from (
        select customer_id
        from {{ ref('int_customers_unified') }}
        group by customer_id
        having count(*) > 1
    )

    union all

    select
        'unified orders have no duplicate order_id' as check_name,
        count(*) as issue_count
    from (
        select order_id
        from {{ ref('int_orders_unified') }}
        group by order_id
        having count(*) > 1
    )

    union all

    select
        'unified order items have no duplicate order item key' as check_name,
        count(*) as issue_count
    from (
        select order_id, order_item_id
        from {{ ref('int_order_items_unified') }}
        group by order_id, order_item_id
        having count(*) > 1
    )

    union all

    select
        'unified payments have no duplicate payment key' as check_name,
        count(*) as issue_count
    from (
        select order_id, payment_sequential
        from {{ ref('int_order_payments_unified') }}
        group by order_id, payment_sequential
        having count(*) > 1
    )

    union all

    select
        'unified reviews have no duplicate review key' as check_name,
        count(*) as issue_count
    from (
        select review_id, order_id
        from {{ ref('int_order_reviews_unified') }}
        group by review_id, order_id
        having count(*) > 1
    )

    union all

    select
        'unified source systems are batch or stream' as check_name,
        count(*) as issue_count
    from (
        select source_system from {{ ref('int_customers_unified') }}
        union all
        select source_system from {{ ref('int_orders_unified') }}
        union all
        select source_system from {{ ref('int_order_items_unified') }}
        union all
        select source_system from {{ ref('int_order_payments_unified') }}
        union all
        select source_system from {{ ref('int_order_reviews_unified') }}
    )
    where source_system not in ('batch', 'stream')

    union all

    select
        'unified customers row count is within expected range' as check_name,
        case
            when u.unified_count < b.batch_count
                or u.unified_count > b.batch_count + s.stream_count
                then 1
            else 0
        end as issue_count
    from (select count(*) as unified_count from {{ ref('int_customers_unified') }}) u
    cross join (select count(*) as batch_count from {{ ref('silver_customers') }}) b
    cross join (select count(*) as stream_count from {{ ref('silver_stream_customers') }}) s

    union all

    select
        'unified orders row count is within expected range' as check_name,
        case
            when u.unified_count < b.batch_count
                or u.unified_count > b.batch_count + s.stream_count
                then 1
            else 0
        end as issue_count
    from (select count(*) as unified_count from {{ ref('int_orders_unified') }}) u
    cross join (select count(*) as batch_count from {{ ref('silver_orders') }}) b
    cross join (select count(*) as stream_count from {{ ref('silver_stream_orders') }}) s

    union all

    select
        'unified order items row count is within expected range' as check_name,
        case
            when u.unified_count < b.batch_count
                or u.unified_count > b.batch_count + s.stream_count
                then 1
            else 0
        end as issue_count
    from (select count(*) as unified_count from {{ ref('int_order_items_unified') }}) u
    cross join (select count(*) as batch_count from {{ ref('silver_order_items') }}) b
    cross join (select count(*) as stream_count from {{ ref('silver_stream_order_items') }}) s

    union all

    select
        'unified payments row count is within expected range' as check_name,
        case
            when u.unified_count < b.batch_count
                or u.unified_count > b.batch_count + s.stream_count
                then 1
            else 0
        end as issue_count
    from (select count(*) as unified_count from {{ ref('int_order_payments_unified') }}) u
    cross join (select count(*) as batch_count from {{ ref('silver_order_payments') }}) b
    cross join (select count(*) as stream_count from {{ ref('silver_stream_order_payments') }}) s

    union all

    select
        'unified reviews row count is within expected range' as check_name,
        case
            when u.unified_count < b.batch_count
                or u.unified_count > b.batch_count + s.stream_count
                then 1
            else 0
        end as issue_count
    from (select count(*) as unified_count from {{ ref('int_order_reviews_unified') }}) u
    cross join (select count(*) as batch_count from {{ ref('silver_order_reviews') }}) b
    cross join (select count(*) as stream_count from {{ ref('silver_stream_order_reviews') }}) s
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
