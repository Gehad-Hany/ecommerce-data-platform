/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Validate staging tables after BULK INSERT.
*/

USE Ecommerce_Source_DB;
GO

DROP TABLE IF EXISTS #expected_row_counts;
GO

CREATE TABLE #expected_row_counts (
    table_name SYSNAME NOT NULL PRIMARY KEY,
    expected_row_count INT NOT NULL
);

INSERT INTO #expected_row_counts (table_name, expected_row_count)
VALUES
    ('staging.brazil_holidays_weekends', 346),
    ('staging.olist_customers', 99441),
    ('staging.olist_geolocation', 1000163),
    ('staging.olist_order_items', 112650),
    ('staging.olist_order_payments', 103886),
    ('staging.olist_order_reviews', 99224),
    ('staging.olist_orders', 99441),
    ('staging.olist_products', 32951),
    ('staging.olist_sellers', 3095),
    ('staging.product_category_translation', 71);

WITH actual_row_counts AS (
    SELECT 'staging.brazil_holidays_weekends' AS table_name, COUNT(*) AS actual_row_count FROM staging.brazil_holidays_weekends
    UNION ALL SELECT 'staging.olist_customers', COUNT(*) FROM staging.olist_customers
    UNION ALL SELECT 'staging.olist_geolocation', COUNT(*) FROM staging.olist_geolocation
    UNION ALL SELECT 'staging.olist_order_items', COUNT(*) FROM staging.olist_order_items
    UNION ALL SELECT 'staging.olist_order_payments', COUNT(*) FROM staging.olist_order_payments
    UNION ALL SELECT 'staging.olist_order_reviews', COUNT(*) FROM staging.olist_order_reviews
    UNION ALL SELECT 'staging.olist_orders', COUNT(*) FROM staging.olist_orders
    UNION ALL SELECT 'staging.olist_products', COUNT(*) FROM staging.olist_products
    UNION ALL SELECT 'staging.olist_sellers', COUNT(*) FROM staging.olist_sellers
    UNION ALL SELECT 'staging.product_category_translation', COUNT(*) FROM staging.product_category_translation
)
SELECT
    e.table_name,
    e.expected_row_count,
    a.actual_row_count,
    a.actual_row_count - e.expected_row_count AS row_count_difference,
    CASE WHEN a.actual_row_count = e.expected_row_count THEN 'PASS' ELSE 'FAIL' END AS validation_status
FROM #expected_row_counts AS e
INNER JOIN actual_row_counts AS a
    ON e.table_name = a.table_name
ORDER BY e.table_name;
GO

SELECT 'staging.olist_customers.customer_id' AS check_name, COUNT(*) AS issue_count
FROM staging.olist_customers
WHERE NULLIF(LTRIM(RTRIM(customer_id)), '') IS NULL
UNION ALL
SELECT 'staging.olist_orders.order_id', COUNT(*)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
UNION ALL
SELECT 'staging.olist_orders.customer_id', COUNT(*)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(customer_id)), '') IS NULL
UNION ALL
SELECT 'staging.olist_order_items.order_id', COUNT(*)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
UNION ALL
SELECT 'staging.olist_order_items.order_item_id', COUNT(*)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(order_item_id)), '') IS NULL
UNION ALL
SELECT 'staging.olist_order_payments.order_id', COUNT(*)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
UNION ALL
SELECT 'staging.olist_order_payments.payment_sequential', COUNT(*)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_sequential)), '') IS NULL
UNION ALL
SELECT 'staging.olist_order_reviews.review_id', COUNT(*)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_id)), '') IS NULL
UNION ALL
SELECT 'staging.olist_order_reviews.order_id', COUNT(*)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
UNION ALL
SELECT 'staging.olist_products.product_id', COUNT(*)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_id)), '') IS NULL
UNION ALL
SELECT 'staging.olist_sellers.seller_id', COUNT(*)
FROM staging.olist_sellers
WHERE NULLIF(LTRIM(RTRIM(seller_id)), '') IS NULL
UNION ALL
SELECT 'staging.product_category_translation.product_category_name', COUNT(*)
FROM staging.product_category_translation
WHERE NULLIF(LTRIM(RTRIM(product_category_name)), '') IS NULL
UNION ALL
SELECT 'staging.brazil_holidays_weekends.date', COUNT(*)
FROM staging.brazil_holidays_weekends
WHERE NULLIF(LTRIM(RTRIM([date])), '') IS NULL;
GO

SELECT 'customers duplicate customer_id' AS check_name, COUNT(*) AS duplicate_groups
FROM (SELECT customer_id FROM staging.olist_customers GROUP BY customer_id HAVING COUNT(*) > 1) AS d
UNION ALL
SELECT 'orders duplicate order_id', COUNT(*)
FROM (SELECT order_id FROM staging.olist_orders GROUP BY order_id HAVING COUNT(*) > 1) AS d
UNION ALL
SELECT 'order_items duplicate order_id/order_item_id', COUNT(*)
FROM (SELECT order_id, order_item_id FROM staging.olist_order_items GROUP BY order_id, order_item_id HAVING COUNT(*) > 1) AS d
UNION ALL
SELECT 'order_payments duplicate order_id/payment_sequential', COUNT(*)
FROM (SELECT order_id, payment_sequential FROM staging.olist_order_payments GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1) AS d
UNION ALL
SELECT 'products duplicate product_id', COUNT(*)
FROM (SELECT product_id FROM staging.olist_products GROUP BY product_id HAVING COUNT(*) > 1) AS d
UNION ALL
SELECT 'sellers duplicate seller_id', COUNT(*)
FROM (SELECT seller_id FROM staging.olist_sellers GROUP BY seller_id HAVING COUNT(*) > 1) AS d;
GO

SELECT 'orders invalid order_purchase_timestamp' AS check_name, COUNT(*) AS issue_count
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), '') IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(DATETIME2(0), order_purchase_timestamp, 120),
        TRY_CONVERT(DATETIME2(0), order_purchase_timestamp, 101),
        TRY_CONVERT(DATETIME2(0), order_purchase_timestamp, 103),
        TRY_PARSE(order_purchase_timestamp AS DATETIME2 USING 'en-US')
      ) IS NULL
UNION ALL
SELECT 'orders invalid order_approved_at', COUNT(*)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_approved_at)), '') IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(DATETIME2(0), order_approved_at, 120),
        TRY_CONVERT(DATETIME2(0), order_approved_at, 101),
        TRY_CONVERT(DATETIME2(0), order_approved_at, 103),
        TRY_PARSE(order_approved_at AS DATETIME2 USING 'en-US')
      ) IS NULL
UNION ALL
SELECT 'orders invalid order_delivered_carrier_date', COUNT(*)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), '') IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(DATETIME2(0), order_delivered_carrier_date, 120),
        TRY_CONVERT(DATETIME2(0), order_delivered_carrier_date, 101),
        TRY_CONVERT(DATETIME2(0), order_delivered_carrier_date, 103),
        TRY_PARSE(order_delivered_carrier_date AS DATETIME2 USING 'en-US')
      ) IS NULL
UNION ALL
SELECT 'orders invalid order_delivered_customer_date', COUNT(*)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '') IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(DATETIME2(0), order_delivered_customer_date, 120),
        TRY_CONVERT(DATETIME2(0), order_delivered_customer_date, 101),
        TRY_CONVERT(DATETIME2(0), order_delivered_customer_date, 103),
        TRY_PARSE(order_delivered_customer_date AS DATETIME2 USING 'en-US')
      ) IS NULL
UNION ALL
SELECT 'orders invalid order_estimated_delivery_date', COUNT(*)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), '') IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(DATETIME2(0), order_estimated_delivery_date, 120),
        TRY_CONVERT(DATETIME2(0), order_estimated_delivery_date, 101),
        TRY_CONVERT(DATETIME2(0), order_estimated_delivery_date, 103),
        TRY_PARSE(order_estimated_delivery_date AS DATETIME2 USING 'en-US')
      ) IS NULL
UNION ALL
SELECT 'order_items invalid shipping_limit_date', COUNT(*)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(shipping_limit_date)), '') IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(DATETIME2(0), shipping_limit_date, 120),
        TRY_CONVERT(DATETIME2(0), shipping_limit_date, 101),
        TRY_CONVERT(DATETIME2(0), shipping_limit_date, 103),
        TRY_PARSE(shipping_limit_date AS DATETIME2 USING 'en-US')
      ) IS NULL
UNION ALL
SELECT 'order_reviews invalid review_creation_date', COUNT(*)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_creation_date)), '') IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(DATETIME2(0), review_creation_date, 120),
        TRY_CONVERT(DATETIME2(0), review_creation_date, 101),
        TRY_CONVERT(DATETIME2(0), review_creation_date, 103),
        TRY_PARSE(review_creation_date AS DATETIME2 USING 'en-US')
      ) IS NULL
UNION ALL
SELECT 'order_reviews invalid review_answer_timestamp', COUNT(*)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_answer_timestamp)), '') IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(DATETIME2(0), review_answer_timestamp, 120),
        TRY_CONVERT(DATETIME2(0), review_answer_timestamp, 101),
        TRY_CONVERT(DATETIME2(0), review_answer_timestamp, 103),
        TRY_PARSE(review_answer_timestamp AS DATETIME2 USING 'en-US')
      ) IS NULL
UNION ALL
SELECT 'calendar invalid date', COUNT(*)
FROM staging.brazil_holidays_weekends
WHERE NULLIF(LTRIM(RTRIM([date])), '') IS NOT NULL
  AND COALESCE(
        TRY_CONVERT(DATE, [date], 23),
        TRY_CONVERT(DATE, [date], 101),
        TRY_CONVERT(DATE, [date], 103),
        TRY_PARSE([date] AS DATE USING 'en-US')
      ) IS NULL;
GO

SELECT 'order_items invalid order_item_id' AS check_name, COUNT(*) AS issue_count
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(order_item_id)), '') IS NOT NULL
  AND TRY_CONVERT(INT, order_item_id) IS NULL
UNION ALL
SELECT 'order_items invalid price', COUNT(*)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(price)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(12, 2), price) IS NULL
UNION ALL
SELECT 'order_items invalid freight_value', COUNT(*)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(freight_value)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(12, 2), freight_value) IS NULL
UNION ALL
SELECT 'order_payments invalid payment_sequential', COUNT(*)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_sequential)), '') IS NOT NULL
  AND TRY_CONVERT(INT, payment_sequential) IS NULL
UNION ALL
SELECT 'order_payments invalid payment_installments', COUNT(*)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_installments)), '') IS NOT NULL
  AND TRY_CONVERT(INT, payment_installments) IS NULL
UNION ALL
SELECT 'order_payments invalid payment_value', COUNT(*)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_value)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(12, 2), payment_value) IS NULL
UNION ALL
SELECT 'order_reviews invalid review_score', COUNT(*)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_score)), '') IS NOT NULL
  AND TRY_CONVERT(TINYINT, review_score) IS NULL
UNION ALL
SELECT 'products invalid product_weight_g', COUNT(*)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_weight_g)), '') IS NOT NULL
  AND TRY_CONVERT(INT, product_weight_g) IS NULL
UNION ALL
SELECT 'geolocation invalid geolocation_lat', COUNT(*)
FROM staging.olist_geolocation
WHERE NULLIF(LTRIM(RTRIM(geolocation_lat)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(11, 8), geolocation_lat) IS NULL
UNION ALL
SELECT 'geolocation invalid geolocation_lng', COUNT(*)
FROM staging.olist_geolocation
WHERE NULLIF(LTRIM(RTRIM(geolocation_lng)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(11, 8), geolocation_lng) IS NULL;
GO

SELECT 'orders without matching customer' AS check_name, COUNT(*) AS issue_count
FROM staging.olist_orders AS o
LEFT JOIN staging.olist_customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'order_items without matching order', COUNT(*)
FROM staging.olist_order_items AS oi
LEFT JOIN staging.olist_orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_items without matching product', COUNT(*)
FROM staging.olist_order_items AS oi
LEFT JOIN staging.olist_products AS p
    ON oi.product_id = p.product_id
WHERE oi.product_id IS NOT NULL
  AND p.product_id IS NULL
UNION ALL
SELECT 'order_items without matching seller', COUNT(*)
FROM staging.olist_order_items AS oi
LEFT JOIN staging.olist_sellers AS s
    ON oi.seller_id = s.seller_id
WHERE oi.seller_id IS NOT NULL
  AND s.seller_id IS NULL
UNION ALL
SELECT 'order_payments without matching order', COUNT(*)
FROM staging.olist_order_payments AS op
LEFT JOIN staging.olist_orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_reviews without matching order', COUNT(*)
FROM staging.olist_order_reviews AS r
LEFT JOIN staging.olist_orders AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
GO