select
    r.review_id,
    r.order_id,
    r.review_score,
    (r.review_score < 1 or r.review_score > 5) as is_invalid_review_score,
    r.review_creation_date,
    r.review_creation_time,
    r.review_answer_date,
    r.review_answer_time,
    (r.review_creation_date > to_date('2026-05-20')) as is_review_creation_after_batch_cutoff,
    (r.review_answer_date > to_date('2026-05-20')) as is_review_answer_after_batch_cutoff
from {{ ref('stg_stream_order_reviews') }} r
