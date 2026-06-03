with unioned as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        'batch' as source_system,
        1 as source_priority
    from {{ ref('silver_customers') }}

    union all

    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        'stream' as source_system,
        2 as source_priority
    from {{ ref('silver_stream_customers') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by customer_id
            order by source_priority desc
        ) as rn
    from unioned
    where customer_id is not null
)

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    source_system
from deduplicated
where rn = 1
