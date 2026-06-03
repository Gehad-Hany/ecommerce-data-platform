with raw_reviews as (
    select
        nullif(trim("review_id"), '') as review_id,
        nullif(trim("order_id"), '') as order_id,
        cast("review_score" as number(3, 0)) as review_score,
        "review_creation_date" as review_creation_timestamp,
        dateadd(year, 8, "review_creation_date") as review_creation_timestamp_shifted,
        to_date(dateadd(year, 8, "review_creation_date")) as review_creation_date,
        to_time(dateadd(year, 8, "review_creation_date")) as review_creation_time,
        "review_answer_timestamp" as review_answer_timestamp,
        dateadd(year, 8, "review_answer_timestamp") as review_answer_timestamp_shifted,
        to_date(dateadd(year, 8, "review_answer_timestamp")) as review_answer_date,
        to_time(dateadd(year, 8, "review_answer_timestamp")) as review_answer_time,
        "ingested_at" as ingested_at
    from {{ source('raw_stream', 'RAW_REVIEWS') }}
    where nullif(trim("review_id"), '') is not null
),

ranked_reviews as (
    select
        *,
        row_number() over (
            partition by review_id
            order by ingested_at desc nulls last
        ) as rn
    from raw_reviews
)

select
    review_id,
    order_id,
    review_score,
    review_creation_timestamp,
    review_creation_timestamp_shifted,
    review_creation_date,
    review_creation_time,
    review_answer_timestamp,
    review_answer_timestamp_shifted,
    review_answer_date,
    review_answer_time
from ranked_reviews
where rn = 1
