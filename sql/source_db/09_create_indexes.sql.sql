/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Create helpful indexes for joins, filtering, and analytics queries.
*/

USE Ecommerce_Source_DB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_customers_unique_id' AND object_id = OBJECT_ID('sales.customers'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_customers_unique_id
    ON sales.customers (customer_unique_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_customers_location' AND object_id = OBJECT_ID('sales.customers'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_customers_location
    ON sales.customers (customer_state, customer_city, customer_zip_code_prefix);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_orders_customer_id' AND object_id = OBJECT_ID('sales.orders'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_orders_customer_id
    ON sales.orders (customer_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_orders_purchase_date' AND object_id = OBJECT_ID('sales.orders'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_orders_purchase_date
    ON sales.orders (order_purchase_timestamp)
    INCLUDE (order_status, customer_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_orders_status' AND object_id = OBJECT_ID('sales.orders'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_orders_status
    ON sales.orders (order_status);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_order_items_product_id' AND object_id = OBJECT_ID('sales.order_items'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_order_items_product_id
    ON sales.order_items (product_id)
    INCLUDE (price, freight_value);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_order_items_seller_id' AND object_id = OBJECT_ID('sales.order_items'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_order_items_seller_id
    ON sales.order_items (seller_id)
    INCLUDE (price, freight_value);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_order_items_shipping_limit_date' AND object_id = OBJECT_ID('sales.order_items'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_order_items_shipping_limit_date
    ON sales.order_items (shipping_limit_date);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_order_payments_type' AND object_id = OBJECT_ID('sales.order_payments'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_order_payments_type
    ON sales.order_payments (payment_type)
    INCLUDE (payment_value, payment_installments);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_order_reviews_score' AND object_id = OBJECT_ID('sales.order_reviews'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_order_reviews_score
    ON sales.order_reviews (review_score, review_creation_date);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_order_reviews_order_id' AND object_id = OBJECT_ID('sales.order_reviews'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_order_reviews_order_id
    ON sales.order_reviews (order_id)
    INCLUDE (review_score, review_creation_date, review_answer_timestamp);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_products_category' AND object_id = OBJECT_ID('sales.products'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_products_category
    ON sales.products (product_category_name);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_sales_sellers_location' AND object_id = OBJECT_ID('sales.sellers'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_sales_sellers_location
    ON sales.sellers (seller_state, seller_city, seller_zip_code_prefix);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_geolocation_geolocation_zip_code_prefix' AND object_id = OBJECT_ID('geolocation.geolocation'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_geolocation_geolocation_zip_code_prefix
    ON geolocation.geolocation (geolocation_zip_code_prefix);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_geolocation_geolocation_state_city' AND object_id = OBJECT_ID('geolocation.geolocation'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_geolocation_geolocation_state_city
    ON geolocation.geolocation (geolocation_state, geolocation_city);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_calendar_brazil_holidays_date' AND object_id = OBJECT_ID('calendar.brazil_holidays'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_calendar_brazil_holidays_date
    ON calendar.brazil_holidays (calendar_date);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ix_calendar_brazil_holidays_type' AND object_id = OBJECT_ID('calendar.brazil_holidays'))
BEGIN
    CREATE NONCLUSTERED INDEX ix_calendar_brazil_holidays_type
    ON calendar.brazil_holidays (event_type, calendar_year)
    INCLUDE (calendar_date, event_name, country_code);
END;
GO

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON i.object_id = t.object_id
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name IN ('sales', 'geolocation', 'calendar')
  AND i.name IS NOT NULL
ORDER BY
    s.name,
    t.name,
    i.name;
GO
