with raw_customers as (
    select
        nullif(trim("customer_id"), '') as customer_id,
        nullif(trim("customer_unique_id"), '') as customer_unique_id,
        case
            when "customer_zip_code_prefix" is null then null
            else lpad(trim(to_varchar("customer_zip_code_prefix")), 5, '0')
        end as customer_zip_code_prefix,
        nullif(lower(trim("customer_city")), '') as customer_city,
        nullif(upper(trim("customer_state")), '') as customer_state,
        "ingested_at" as ingested_at
    from {{ source('raw_stream', 'RAW_CUSTOMERS') }}
),

ranked_customers as (
    select
        *,
        row_number() over (
            partition by customer_id
            order by ingested_at desc nulls last
        ) as rn
    from raw_customers
    where customer_id is not null
)

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
from ranked_customers
where rn = 1
