select
    product_id,
    coalesce(product_category_name, 'unknown') as clean_product_category_name,
    product_name_lenght,
    product_description_lenght,
    coalesce(product_photos_qty, 0) as product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,

    (product_category_name is null
        or product_name_lenght is null
        or product_description_lenght is null
        or product_photos_qty is null)
        as is_missing_product_metadata,

    (product_weight_g is null
        or product_length_cm is null
        or product_height_cm is null
        or product_width_cm is null)
        as is_missing_product_dimensions
from {{ ref('stg_products') }}
