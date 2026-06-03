select
    row_number() over (order by review_id, order_id) as review_sk,
    review_id,
    order_id,
    review_score,
    to_number(to_char(review_creation_date, 'YYYYMMDD')) as review_creation_date_key,
    to_number(to_char(review_answer_date, 'YYYYMMDD')) as review_answer_date_key,
    case
        when review_answer_date is null or review_answer_time is null then null
        else to_timestamp_ntz(review_answer_date || ' ' || review_answer_time)
    end as review_answer_timestamp,
    case
        when review_creation_date is null or review_answer_date is null then null
        else datediff(day, review_creation_date, review_answer_date)
    end as review_response_days,
    current_timestamp() as load_datetime
from {{ ref('int_order_reviews_unified') }}
where review_id is not null
  and order_id is not null
