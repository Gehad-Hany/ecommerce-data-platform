/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Simulate realistic CDC update events for Debezium/Kafka testing.

    This script updates a small batch of rows in:
        - sales.customers
        - sales.products
        - sales.sellers

    Run after:
        - SQL Server CDC is enabled
        - Debezium connector is running
        - Kafka topics are available
*/

USE Ecommerce_Source_DB;
GO

DECLARE @run_suffix VARCHAR(20) = FORMAT(SYSDATETIME(), 'MMddHHmmss');

BEGIN TRANSACTION;

------------------------------------------------------------
-- 1. Simulate customer profile/location corrections
-- Updates 10 customers
------------------------------------------------------------
;WITH customers_to_update AS (
    SELECT TOP (10)
        customer_id,
        ROW_NUMBER() OVER (ORDER BY customer_id) AS rn
    FROM sales.customers
    ORDER BY customer_id
)
UPDATE c
SET
    customer_city = CONCAT('cdc customer city ', customers_to_update.rn, ' ', @run_suffix),
    customer_state = CASE
        WHEN customers_to_update.rn % 3 = 0 THEN 'RJ'
        WHEN customers_to_update.rn % 3 = 1 THEN 'SP'
        ELSE 'MG'
    END
FROM sales.customers c
INNER JOIN customers_to_update
    ON c.customer_id = customers_to_update.customer_id;

------------------------------------------------------------
-- 2. Simulate product catalog maintenance
-- Updates 10 products
------------------------------------------------------------
;WITH products_to_update AS (
    SELECT TOP (10)
        product_id,
        ROW_NUMBER() OVER (ORDER BY product_id) AS rn
    FROM sales.products
    ORDER BY product_id
)
UPDATE p
SET
    product_category_name = CONCAT('cdc_test_category_', products_to_update.rn, '_', @run_suffix),
    product_photos_qty = COALESCE(product_photos_qty, 0) + 1,
    product_description_lenght = COALESCE(product_description_lenght, 0) + 5
FROM sales.products p
INNER JOIN products_to_update
    ON p.product_id = products_to_update.product_id;

------------------------------------------------------------
-- 3. Simulate seller address corrections
-- Updates 5 sellers
------------------------------------------------------------
;WITH sellers_to_update AS (
    SELECT TOP (5)
        seller_id,
        ROW_NUMBER() OVER (ORDER BY seller_id) AS rn
    FROM sales.sellers
    ORDER BY seller_id
)
UPDATE s
SET
    seller_city = CONCAT('cdc seller city ', sellers_to_update.rn, ' ', @run_suffix),
    seller_state = CASE
        WHEN sellers_to_update.rn % 2 = 0 THEN 'RJ'
        ELSE 'SP'
    END
FROM sales.sellers s
INNER JOIN sellers_to_update
    ON s.seller_id = sellers_to_update.seller_id;

COMMIT TRANSACTION;
GO

------------------------------------------------------------
-- Confirm updated rows
------------------------------------------------------------
SELECT TOP (10)
    'sales.customers' AS table_name,
    customer_id,
    customer_city,
    customer_state
FROM sales.customers
WHERE customer_city LIKE 'cdc customer city%'
ORDER BY customer_city DESC;

SELECT TOP (10)
    'sales.products' AS table_name,
    product_id,
    product_category_name,
    product_photos_qty,
    product_description_lenght
FROM sales.products
WHERE product_category_name LIKE 'cdc_test_category%'
ORDER BY product_category_name DESC;

SELECT TOP (5)
    'sales.sellers' AS table_name,
    seller_id,
    seller_city,
    seller_state
FROM sales.sellers
WHERE seller_city LIKE 'cdc seller city%'
ORDER BY seller_city DESC;
GO