/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Incrementally load final source tables from staging tables.

    Notes:
        - Staging tables are still reloaded using TRUNCATE + BULK INSERT.
        - Final source tables use MERGE to avoid duplicates and avoid full reloads.
        - geolocation.geolocation remains full reload because the Olist geolocation file has duplicate rows
          and does not have a reliable business key.
*/

USE Ecommerce_Source_DB;
GO

IF COL_LENGTH('sales.order_reviews', 'review_comment_title') IS NOT NULL
BEGIN
    ALTER TABLE sales.order_reviews DROP COLUMN review_comment_title;
END;
GO

IF COL_LENGTH('sales.order_reviews', 'review_comment_message') IS NOT NULL
BEGIN
    ALTER TABLE sales.order_reviews DROP COLUMN review_comment_message;
END;
GO

ALTER TABLE geolocation.geolocation ALTER COLUMN geolocation_lat DECIMAL(11, 8) NULL;
ALTER TABLE geolocation.geolocation ALTER COLUMN geolocation_lng DECIMAL(11, 8) NULL;
GO

PRINT 'Incremental loading sales.customers';
;WITH src AS (
    SELECT
        LTRIM(RTRIM(customer_id)) AS customer_id,
        NULLIF(LTRIM(RTRIM(customer_unique_id)), '') AS customer_unique_id,
        NULLIF(LTRIM(RTRIM(customer_zip_code_prefix)), '') AS customer_zip_code_prefix,
        NULLIF(LTRIM(RTRIM(customer_city)), '') AS customer_city,
        NULLIF(LTRIM(RTRIM(customer_state)), '') AS customer_state
    FROM staging.olist_customers
)
MERGE sales.customers AS tgt
USING src
    ON tgt.customer_id = src.customer_id
WHEN MATCHED AND EXISTS (
    SELECT tgt.customer_unique_id, tgt.customer_zip_code_prefix, tgt.customer_city, tgt.customer_state
    EXCEPT
    SELECT src.customer_unique_id, src.customer_zip_code_prefix, src.customer_city, src.customer_state
) THEN
    UPDATE SET
        customer_unique_id = src.customer_unique_id,
        customer_zip_code_prefix = src.customer_zip_code_prefix,
        customer_city = src.customer_city,
        customer_state = src.customer_state
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    )
    VALUES (
        src.customer_id,
        src.customer_unique_id,
        src.customer_zip_code_prefix,
        src.customer_city,
        src.customer_state
    );
GO

PRINT 'Incremental loading sales.products';
;WITH src AS (
    SELECT
        LTRIM(RTRIM(product_id)) AS product_id,
        NULLIF(LTRIM(RTRIM(product_category_name)), '') AS product_category_name,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_name_lenght)), '')) AS product_name_lenght,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_description_lenght)), '')) AS product_description_lenght,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_photos_qty)), '')) AS product_photos_qty,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_weight_g)), '')) AS product_weight_g,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_length_cm)), '')) AS product_length_cm,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_height_cm)), '')) AS product_height_cm,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_width_cm)), '')) AS product_width_cm
    FROM staging.olist_products
)
MERGE sales.products AS tgt
USING src
    ON tgt.product_id = src.product_id
WHEN MATCHED AND EXISTS (
    SELECT
        tgt.product_category_name,
        tgt.product_name_lenght,
        tgt.product_description_lenght,
        tgt.product_photos_qty,
        tgt.product_weight_g,
        tgt.product_length_cm,
        tgt.product_height_cm,
        tgt.product_width_cm
    EXCEPT
    SELECT
        src.product_category_name,
        src.product_name_lenght,
        src.product_description_lenght,
        src.product_photos_qty,
        src.product_weight_g,
        src.product_length_cm,
        src.product_height_cm,
        src.product_width_cm
) THEN
    UPDATE SET
        product_category_name = src.product_category_name,
        product_name_lenght = src.product_name_lenght,
        product_description_lenght = src.product_description_lenght,
        product_photos_qty = src.product_photos_qty,
        product_weight_g = src.product_weight_g,
        product_length_cm = src.product_length_cm,
        product_height_cm = src.product_height_cm,
        product_width_cm = src.product_width_cm
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        product_id,
        product_category_name,
        product_name_lenght,
        product_description_lenght,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    )
    VALUES (
        src.product_id,
        src.product_category_name,
        src.product_name_lenght,
        src.product_description_lenght,
        src.product_photos_qty,
        src.product_weight_g,
        src.product_length_cm,
        src.product_height_cm,
        src.product_width_cm
    );
GO

PRINT 'Incremental loading sales.sellers';
;WITH src AS (
    SELECT
        LTRIM(RTRIM(seller_id)) AS seller_id,
        NULLIF(LTRIM(RTRIM(seller_zip_code_prefix)), '') AS seller_zip_code_prefix,
        NULLIF(LTRIM(RTRIM(seller_city)), '') AS seller_city,
        NULLIF(LTRIM(RTRIM(seller_state)), '') AS seller_state
    FROM staging.olist_sellers
)
MERGE sales.sellers AS tgt
USING src
    ON tgt.seller_id = src.seller_id
WHEN MATCHED AND EXISTS (
    SELECT tgt.seller_zip_code_prefix, tgt.seller_city, tgt.seller_state
    EXCEPT
    SELECT src.seller_zip_code_prefix, src.seller_city, src.seller_state
) THEN
    UPDATE SET
        seller_zip_code_prefix = src.seller_zip_code_prefix,
        seller_city = src.seller_city,
        seller_state = src.seller_state
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    )
    VALUES (
        src.seller_id,
        src.seller_zip_code_prefix,
        src.seller_city,
        src.seller_state
    );
GO

PRINT 'Incremental loading sales.product_category_translation';
;WITH src AS (
    SELECT
        LTRIM(RTRIM(product_category_name)) AS product_category_name,
        NULLIF(LTRIM(RTRIM(product_category_name_english)), '') AS product_category_name_english
    FROM staging.product_category_translation
)
MERGE sales.product_category_translation AS tgt
USING src
    ON tgt.product_category_name = src.product_category_name
WHEN MATCHED AND EXISTS (
    SELECT tgt.product_category_name_english
    EXCEPT
    SELECT src.product_category_name_english
) THEN
    UPDATE SET
        product_category_name_english = src.product_category_name_english
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        product_category_name,
        product_category_name_english
    )
    VALUES (
        src.product_category_name,
        src.product_category_name_english
    );
GO

PRINT 'Incremental loading sales.orders';
;WITH src AS (
    SELECT
        LTRIM(RTRIM(order_id)) AS order_id,
        LTRIM(RTRIM(customer_id)) AS customer_id,
        NULLIF(LTRIM(RTRIM(order_status)), '') AS order_status,
        COALESCE(
            TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), ''), 120),
            TRY_PARSE(NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), '') AS DATETIME2 USING 'en-US')
        ) AS order_purchase_timestamp,
        COALESCE(
            TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_approved_at)), ''), 120),
            TRY_PARSE(NULLIF(LTRIM(RTRIM(order_approved_at)), '') AS DATETIME2 USING 'en-US')
        ) AS order_approved_at,
        COALESCE(
            TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), ''), 120),
            TRY_PARSE(NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), '') AS DATETIME2 USING 'en-US')
        ) AS order_delivered_carrier_date,
        COALESCE(
            TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), ''), 120),
            TRY_PARSE(NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '') AS DATETIME2 USING 'en-US')
        ) AS order_delivered_customer_date,
        COALESCE(
            TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), ''), 120),
            TRY_PARSE(NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), '') AS DATETIME2 USING 'en-US')
        ) AS order_estimated_delivery_date
    FROM staging.olist_orders
)
MERGE sales.orders AS tgt
USING src
    ON tgt.order_id = src.order_id
WHEN MATCHED AND EXISTS (
    SELECT
        tgt.customer_id,
        tgt.order_status,
        tgt.order_purchase_timestamp,
        tgt.order_approved_at,
        tgt.order_delivered_carrier_date,
        tgt.order_delivered_customer_date,
        tgt.order_estimated_delivery_date
    EXCEPT
    SELECT
        src.customer_id,
        src.order_status,
        src.order_purchase_timestamp,
        src.order_approved_at,
        src.order_delivered_carrier_date,
        src.order_delivered_customer_date,
        src.order_estimated_delivery_date
) THEN
    UPDATE SET
        customer_id = src.customer_id,
        order_status = src.order_status,
        order_purchase_timestamp = src.order_purchase_timestamp,
        order_approved_at = src.order_approved_at,
        order_delivered_carrier_date = src.order_delivered_carrier_date,
        order_delivered_customer_date = src.order_delivered_customer_date,
        order_estimated_delivery_date = src.order_estimated_delivery_date
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    )
    VALUES (
        src.order_id,
        src.customer_id,
        src.order_status,
        src.order_purchase_timestamp,
        src.order_approved_at,
        src.order_delivered_carrier_date,
        src.order_delivered_customer_date,
        src.order_estimated_delivery_date
    );
GO

PRINT 'Incremental loading sales.order_items';
;WITH src AS (
    SELECT
        LTRIM(RTRIM(order_id)) AS order_id,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(order_item_id)), '')) AS order_item_id,
        NULLIF(LTRIM(RTRIM(product_id)), '') AS product_id,
        NULLIF(LTRIM(RTRIM(seller_id)), '') AS seller_id,
        COALESCE(
            TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(shipping_limit_date)), ''), 120),
            TRY_PARSE(NULLIF(LTRIM(RTRIM(shipping_limit_date)), '') AS DATETIME2 USING 'en-US')
        ) AS shipping_limit_date,
        TRY_CONVERT(DECIMAL(12, 2), NULLIF(LTRIM(RTRIM(price)), '')) AS price,
        TRY_CONVERT(DECIMAL(12, 2), NULLIF(LTRIM(RTRIM(freight_value)), '')) AS freight_value
    FROM staging.olist_order_items
)
MERGE sales.order_items AS tgt
USING src
    ON tgt.order_id = src.order_id
   AND tgt.order_item_id = src.order_item_id
WHEN MATCHED AND EXISTS (
    SELECT tgt.product_id, tgt.seller_id, tgt.shipping_limit_date, tgt.price, tgt.freight_value
    EXCEPT
    SELECT src.product_id, src.seller_id, src.shipping_limit_date, src.price, src.freight_value
) THEN
    UPDATE SET
        product_id = src.product_id,
        seller_id = src.seller_id,
        shipping_limit_date = src.shipping_limit_date,
        price = src.price,
        freight_value = src.freight_value
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    )
    VALUES (
        src.order_id,
        src.order_item_id,
        src.product_id,
        src.seller_id,
        src.shipping_limit_date,
        src.price,
        src.freight_value
    );
GO

PRINT 'Incremental loading sales.order_payments';
;WITH src AS (
    SELECT
        LTRIM(RTRIM(order_id)) AS order_id,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_sequential)), '')) AS payment_sequential,
        NULLIF(LTRIM(RTRIM(payment_type)), '') AS payment_type,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_installments)), '')) AS payment_installments,
        TRY_CONVERT(DECIMAL(12, 2), NULLIF(LTRIM(RTRIM(payment_value)), '')) AS payment_value
    FROM staging.olist_order_payments
)
MERGE sales.order_payments AS tgt
USING src
    ON tgt.order_id = src.order_id
   AND tgt.payment_sequential = src.payment_sequential
WHEN MATCHED AND EXISTS (
    SELECT tgt.payment_type, tgt.payment_installments, tgt.payment_value
    EXCEPT
    SELECT src.payment_type, src.payment_installments, src.payment_value
) THEN
    UPDATE SET
        payment_type = src.payment_type,
        payment_installments = src.payment_installments,
        payment_value = src.payment_value
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    )
    VALUES (
        src.order_id,
        src.payment_sequential,
        src.payment_type,
        src.payment_installments,
        src.payment_value
    );
GO

PRINT 'Incremental loading sales.order_reviews';
;WITH src AS (
    SELECT
        LTRIM(RTRIM(review_id)) AS review_id,
        LTRIM(RTRIM(order_id)) AS order_id,
        TRY_CONVERT(TINYINT, NULLIF(LTRIM(RTRIM(review_score)), '')) AS review_score,
        COALESCE(
            TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(review_creation_date)), ''), 120),
            TRY_PARSE(NULLIF(LTRIM(RTRIM(review_creation_date)), '') AS DATETIME2 USING 'en-US')
        ) AS review_creation_date,
        COALESCE(
            TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(review_answer_timestamp)), ''), 120),
            TRY_PARSE(NULLIF(LTRIM(RTRIM(review_answer_timestamp)), '') AS DATETIME2 USING 'en-US')
        ) AS review_answer_timestamp
    FROM staging.olist_order_reviews
)
MERGE sales.order_reviews AS tgt
USING src
    ON tgt.review_id = src.review_id
   AND tgt.order_id = src.order_id
WHEN MATCHED AND EXISTS (
    SELECT tgt.review_score, tgt.review_creation_date, tgt.review_answer_timestamp
    EXCEPT
    SELECT src.review_score, src.review_creation_date, src.review_answer_timestamp
) THEN
    UPDATE SET
        review_score = src.review_score,
        review_creation_date = src.review_creation_date,
        review_answer_timestamp = src.review_answer_timestamp
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        review_id,
        order_id,
        review_score,
        review_creation_date,
        review_answer_timestamp
    )
    VALUES (
        src.review_id,
        src.order_id,
        src.review_score,
        src.review_creation_date,
        src.review_answer_timestamp
    );
GO

PRINT 'Full reloading geolocation.geolocation';
TRUNCATE TABLE geolocation.geolocation;

INSERT INTO geolocation.geolocation (
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT
    NULLIF(LTRIM(RTRIM(geolocation_zip_code_prefix)), ''),
    TRY_CONVERT(DECIMAL(11, 8), NULLIF(LTRIM(RTRIM(geolocation_lat)), '')),
    TRY_CONVERT(DECIMAL(11, 8), NULLIF(LTRIM(RTRIM(geolocation_lng)), '')),
    NULLIF(LTRIM(RTRIM(geolocation_city)), ''),
    NULLIF(LTRIM(RTRIM(geolocation_state)), '')
FROM staging.olist_geolocation;
GO

PRINT 'Incremental loading calendar.brazil_holidays';
;WITH src AS (
    SELECT
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM([year])), '')) AS calendar_year,
        COALESCE(
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([date])), ''), 23),
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([date])), ''), 101),
            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([date])), ''), 103),
            TRY_PARSE(NULLIF(LTRIM(RTRIM([date])), '') AS DATE USING 'en-US')
        ) AS calendar_date,
        LTRIM(RTRIM([name])) AS event_name,
        LTRIM(RTRIM([type])) AS event_type,
        LEFT(
            REPLACE(REPLACE(LTRIM(RTRIM(country)), CHAR(13), ''), CHAR(10), ''),
            2
        ) AS country_code
    FROM staging.brazil_holidays_weekends
)
MERGE calendar.brazil_holidays AS tgt
USING src
    ON tgt.calendar_date = src.calendar_date
   AND tgt.event_name = src.event_name
WHEN MATCHED AND EXISTS (
    SELECT tgt.calendar_year, tgt.event_type, tgt.country_code
    EXCEPT
    SELECT src.calendar_year, src.event_type, src.country_code
) THEN
    UPDATE SET
        calendar_year = src.calendar_year,
        event_type = src.event_type,
        country_code = src.country_code
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        calendar_year,
        calendar_date,
        event_name,
        event_type,
        country_code
    )
    VALUES (
        src.calendar_year,
        src.calendar_date,
        src.event_name,
        src.event_type,
        src.country_code
    );
GO

SELECT 'sales.customers' AS table_name, COUNT(*) AS row_count FROM sales.customers
UNION ALL
SELECT 'sales.orders', COUNT(*) FROM sales.orders
UNION ALL
SELECT 'sales.order_items', COUNT(*) FROM sales.order_items
UNION ALL
SELECT 'sales.order_payments', COUNT(*) FROM sales.order_payments
UNION ALL
SELECT 'sales.order_reviews', COUNT(*) FROM sales.order_reviews
UNION ALL
SELECT 'sales.products', COUNT(*) FROM sales.products
UNION ALL
SELECT 'sales.sellers', COUNT(*) FROM sales.sellers
UNION ALL
SELECT 'sales.product_category_translation', COUNT(*) FROM sales.product_category_translation
UNION ALL
SELECT 'geolocation.geolocation', COUNT(*) FROM geolocation.geolocation
UNION ALL
SELECT 'calendar.brazil_holidays', COUNT(*) FROM calendar.brazil_holidays
ORDER BY table_name;
GO
