select
    product_category_name,
    product_category_name_english
from {{ ref('stg_product_category_translation') }}
