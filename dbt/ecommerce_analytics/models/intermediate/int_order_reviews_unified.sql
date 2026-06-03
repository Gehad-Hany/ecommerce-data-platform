with unioned as (
    select
        review_id,
        order_id,
        review_score,
        is_invalid_review_score,
        review_creation_date,
        review_creation_time,
        review_answer_date,
        review_answer_time,
        is_review_creation_after_batch_cutoff,
        is_review_answer_after_batch_cutoff,
        'batch' as source_system,
        1 as source_priority
    from {{ ref('silver_order_reviews') }}

    union all

    select
        review_id,
        order_id,
        review_score,
        is_invalid_review_score,
        review_creation_date,
        review_creation_time,
        review_answer_date,
        review_answer_time,
        is_review_creation_after_batch_cutoff,
        is_review_answer_after_batch_cutoff,
        'stream' as source_system,
        2 as source_priority
    from {{ ref('silver_stream_order_reviews') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by review_id, order_id
            order by source_priority desc
        ) as rn
    from unioned
    where review_id is not null
      and order_id is not null
)

select
    review_id,
    order_id,
    review_score,
    is_invalid_review_score,
    review_creation_date,
    review_creation_time,
    review_answer_date,
    review_answer_time,
    is_review_creation_after_batch_cutoff,
    is_review_answer_after_batch_cutoff,
    source_system
from deduplicated
where rn = 1
