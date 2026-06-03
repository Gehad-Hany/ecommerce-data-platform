select
    trim(review_id) as review_id,
    trim(order_id) as order_id,
    review_score,
    review_creation_date as review_creation_timestamp,
    review_answer_timestamp,
    dateadd(year, 8, review_creation_date) as review_creation_timestamp_shifted,
    to_date(dateadd(year, 8, review_creation_date)) as review_creation_date,
    to_time(dateadd(year, 8, review_creation_date)) as review_creation_time,
    dateadd(year, 8, review_answer_timestamp) as review_answer_timestamp_shifted,
    to_date(dateadd(year, 8, review_answer_timestamp)) as review_answer_date,
    to_time(dateadd(year, 8, review_answer_timestamp)) as review_answer_time
from {{ source('raw_batch', 'ORDER_REVIEWS') }}
