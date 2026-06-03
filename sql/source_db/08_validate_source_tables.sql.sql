/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Validate final source tables after loading from staging.

    Run after:
        06_load_source_tables.sql

    This script checks:
        1. Final source row counts
        2. Required key columns
        3. Duplicate business keys
        4. Important date and numeric columns
        5. Basic relationships between final source tables
        6. Useful sample records
*/

USE Ecommerce_Source_DB;
GO

DROP TABLE IF EXISTS #expected_source_row_counts;
GO

CREATE TABLE #expected_source_row_counts (
    table_name SYSNAME NOT NULL PRIMARY KEY,
    expected_row_count INT NOT NULL
);

INSERT INTO #expected_source_row_counts (table_name, expected_row_count)
VALUES
    ('calendar.brazil_holidays', 346),
    ('geolocation.geolocation', 1000163),
    ('sales.customers', 99441),
    ('sales.order_items', 112650),
    ('sales.order_payments', 103886),
    ('sales.order_reviews', 99224),
    ('sales.orders', 99441),
    ('sales.product_category_translation', 71),
    ('sales.products', 32951),
    ('sales.sellers', 3095);

WITH actual_source_row_counts AS (
    SELECT 'calendar.brazil_holidays' AS table_name, COUNT(*) AS actual_row_count FROM calendar.brazil_holidays
    UNION ALL
    SELECT 'geolocation.geolocation', COUNT(*) FROM geolocation.geolocation
    UNION ALL
    SELECT 'sales.customers', COUNT(*) FROM sales.customers
    UNION ALL
    SELECT 'sales.order_items', COUNT(*) FROM sales.order_items
    UNION ALL
    SELECT 'sales.order_payments', COUNT(*) FROM sales.order_payments
    UNION ALL
    SELECT 'sales.order_reviews', COUNT(*) FROM sales.order_reviews
    UNION ALL
    SELECT 'sales.orders', COUNT(*) FROM sales.orders
    UNION ALL
    SELECT 'sales.product_category_translation', COUNT(*) FROM sales.product_category_translation
    UNION ALL
    SELECT 'sales.products', COUNT(*) FROM sales.products
    UNION ALL
    SELECT 'sales.sellers', COUNT(*) FROM sales.sellers
)
SELECT
    e.table_name,
    e.expected_row_count,
    a.actual_row_count,
    a.actual_row_count - e.expected_row_count AS row_count_difference,
    CASE
        WHEN a.actual_row_count = e.expected_row_count THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM #expected_source_row_counts AS e
INNER JOIN actual_source_row_counts AS a
    ON e.table_name = a.table_name
ORDER BY e.table_name;
GO

SELECT 'sales.customers.customer_id' AS check_name, COUNT(*) AS issue_count
FROM sales.customers
WHERE customer_id IS NULL OR LTRIM(RTRIM(customer_id)) = ''
UNION ALL
SELECT 'sales.orders.order_id', COUNT(*)
FROM sales.orders
WHERE order_id IS NULL OR LTRIM(RTRIM(order_id)) = ''
UNION ALL
SELECT 'sales.orders.customer_id', COUNT(*)
FROM sales.orders
WHERE customer_id IS NULL OR LTRIM(RTRIM(customer_id)) = ''
UNION ALL
SELECT 'sales.order_items.order_id', COUNT(*)
FROM sales.order_items
WHERE order_id IS NULL OR LTRIM(RTRIM(order_id)) = ''
UNION ALL
SELECT 'sales.order_items.order_item_id', COUNT(*)
FROM sales.order_items
WHERE order_item_id IS NULL
UNION ALL
SELECT 'sales.order_payments.order_id', COUNT(*)
FROM sales.order_payments
WHERE order_id IS NULL OR LTRIM(RTRIM(order_id)) = ''
UNION ALL
SELECT 'sales.order_payments.payment_sequential', COUNT(*)
FROM sales.order_payments
WHERE payment_sequential IS NULL
UNION ALL
SELECT 'sales.order_reviews.review_id', COUNT(*)
FROM sales.order_reviews
WHERE review_id IS NULL OR LTRIM(RTRIM(review_id)) = ''
UNION ALL
SELECT 'sales.order_reviews.order_id', COUNT(*)
FROM sales.order_reviews
WHERE order_id IS NULL OR LTRIM(RTRIM(order_id)) = ''
UNION ALL
SELECT 'sales.products.product_id', COUNT(*)
FROM sales.products
WHERE product_id IS NULL OR LTRIM(RTRIM(product_id)) = ''
UNION ALL
SELECT 'sales.sellers.seller_id', COUNT(*)
FROM sales.sellers
WHERE seller_id IS NULL OR LTRIM(RTRIM(seller_id)) = ''
UNION ALL
SELECT 'calendar.brazil_holidays.calendar_date', COUNT(*)
FROM calendar.brazil_holidays
WHERE calendar_date IS NULL;
GO

SELECT 'customers duplicate customer_id' AS check_name, COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_id
    FROM sales.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) AS d
UNION ALL
SELECT 'orders duplicate order_id', COUNT(*)
FROM (
    SELECT order_id
    FROM sales.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS d
UNION ALL
SELECT 'order_items duplicate order_id/order_item_id', COUNT(*)
FROM (
    SELECT order_id, order_item_id
    FROM sales.order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) AS d
UNION ALL
SELECT 'order_payments duplicate order_id/payment_sequential', COUNT(*)
FROM (
    SELECT order_id, payment_sequential
    FROM sales.order_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) AS d
UNION ALL
SELECT 'products duplicate product_id', COUNT(*)
FROM (
    SELECT product_id
    FROM sales.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) AS d
UNION ALL
SELECT 'sellers duplicate seller_id', COUNT(*)
FROM (
    SELECT seller_id
    FROM sales.sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) AS d;
GO

SELECT 'orders null purchase timestamp' AS check_name, COUNT(*) AS issue_count
FROM sales.orders
WHERE order_purchase_timestamp IS NULL
UNION ALL
SELECT 'order_items null shipping_limit_date', COUNT(*)
FROM sales.order_items
WHERE shipping_limit_date IS NULL
UNION ALL
SELECT 'order_items null price', COUNT(*)
FROM sales.order_items
WHERE price IS NULL
UNION ALL
SELECT 'order_items negative price', COUNT(*)
FROM sales.order_items
WHERE price < 0
UNION ALL
SELECT 'order_items negative freight_value', COUNT(*)
FROM sales.order_items
WHERE freight_value < 0
UNION ALL
SELECT 'order_payments null payment_value', COUNT(*)
FROM sales.order_payments
WHERE payment_value IS NULL
UNION ALL
SELECT 'order_payments negative payment_value', COUNT(*)
FROM sales.order_payments
WHERE payment_value < 0
UNION ALL
SELECT 'order_reviews invalid review_score_range', COUNT(*)
FROM sales.order_reviews
WHERE review_score NOT BETWEEN 1 AND 5
UNION ALL
SELECT 'geolocation null latitude', COUNT(*)
FROM geolocation.geolocation
WHERE geolocation_lat IS NULL
UNION ALL
SELECT 'geolocation null longitude', COUNT(*)
FROM geolocation.geolocation
WHERE geolocation_lng IS NULL
UNION ALL
SELECT 'calendar null event_name', COUNT(*)
FROM calendar.brazil_holidays
WHERE event_name IS NULL OR LTRIM(RTRIM(event_name)) = '';
GO

SELECT 'orders without matching customer' AS check_name, COUNT(*) AS issue_count
FROM sales.orders AS o
LEFT JOIN sales.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'order_items without matching order', COUNT(*)
FROM sales.order_items AS oi
LEFT JOIN sales.orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_items without matching product', COUNT(*)
FROM sales.order_items AS oi
LEFT JOIN sales.products AS p
    ON oi.product_id = p.product_id
WHERE oi.product_id IS NOT NULL
  AND p.product_id IS NULL
UNION ALL
SELECT 'order_items without matching seller', COUNT(*)
FROM sales.order_items AS oi
LEFT JOIN sales.sellers AS s
    ON oi.seller_id = s.seller_id
WHERE oi.seller_id IS NOT NULL
  AND s.seller_id IS NULL
UNION ALL
SELECT 'order_payments without matching order', COUNT(*)
FROM sales.order_payments AS op
LEFT JOIN sales.orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_reviews without matching order', COUNT(*)
FROM sales.order_reviews AS r
LEFT JOIN sales.orders AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
GO

SELECT
    MIN(order_purchase_timestamp) AS first_order_purchase_timestamp,
    MAX(order_purchase_timestamp) AS last_order_purchase_timestamp,
    COUNT(DISTINCT order_status) AS order_status_count
FROM sales.orders;
GO

SELECT
    MIN(calendar_date) AS first_calendar_date,
    MAX(calendar_date) AS last_calendar_date,
    COUNT(*) AS calendar_event_count,
    SUM(CASE WHEN event_type = 'Weekend' THEN 1 ELSE 0 END) AS weekend_count,
    SUM(CASE WHEN event_type = 'Public Holiday' THEN 1 ELSE 0 END) AS public_holiday_count
FROM calendar.brazil_holidays;
GO

SELECT TOP (20)
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_state,
    c.customer_city,
    oi.order_item_id,
    oi.price,
    oi.freight_value,
    p.product_category_name,
    r.review_score
FROM sales.orders AS o
INNER JOIN sales.customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id
LEFT JOIN sales.products AS p
    ON oi.product_id = p.product_id
LEFT JOIN sales.order_reviews AS r
    ON o.order_id = r.order_id
ORDER BY o.order_purchase_timestamp DESC;
GO
