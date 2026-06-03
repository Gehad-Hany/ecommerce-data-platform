select
    trim(product_id) as product_id,
    nullif(lower(trim(product_category_name)), '') as product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
from {{ source('raw_batch', 'PRODUCTS') }}
