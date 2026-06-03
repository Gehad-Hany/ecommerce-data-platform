select
    lower(trim(product_category_name)) as product_category_name,
    lower(trim(product_category_name_english)) as product_category_name_english
from {{ source('raw_batch', 'PRODUCT_CATEGORY_TRANSLATION') }}
