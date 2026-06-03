/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Add source-table foreign keys after source data has been loaded.

    Run after:
        07_load_source_tables.sql.sql

    Notes:
        - This script does not clean, deduplicate, or delete geolocation rows.
        - geolocation.geolocation keeps all original repeated coordinates.
        - geolocation.zip_code_prefixes is a small reference table used only to make
          zip-code foreign keys possible in SQL Server.
        - calendar.brazil_holidays is not a full date dimension, so orders should
          join to it analytically by date, not through a source FK.
*/

USE Ecommerce_Source_DB;
GO

/* Drop direct geolocation relationships if an older script partially created them. */
IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_customers_geolocation'
      AND parent_object_id = OBJECT_ID('sales.customers')
)
    ALTER TABLE sales.customers DROP CONSTRAINT fk_sales_customers_geolocation;

IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_sellers_geolocation'
      AND parent_object_id = OBJECT_ID('sales.sellers')
)
    ALTER TABLE sales.sellers DROP CONSTRAINT fk_sales_sellers_geolocation;
GO

IF OBJECT_ID('geolocation.zip_code_prefixes', 'U') IS NULL
BEGIN
    CREATE TABLE geolocation.zip_code_prefixes (
        zip_code_prefix VARCHAR(5) NOT NULL,
        CONSTRAINT pk_geolocation_zip_code_prefixes PRIMARY KEY CLUSTERED (zip_code_prefix)
    );
END;
GO

;WITH zip_source AS (
    SELECT NULLIF(LTRIM(RTRIM(customer_zip_code_prefix)), '') AS zip_code_prefix
    FROM sales.customers
    UNION
    SELECT NULLIF(LTRIM(RTRIM(seller_zip_code_prefix)), '') AS zip_code_prefix
    FROM sales.sellers
    UNION
    SELECT NULLIF(LTRIM(RTRIM(geolocation_zip_code_prefix)), '') AS zip_code_prefix
    FROM geolocation.geolocation
)
INSERT INTO geolocation.zip_code_prefixes (zip_code_prefix)
SELECT zip_source.zip_code_prefix
FROM zip_source
WHERE zip_source.zip_code_prefix IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM geolocation.zip_code_prefixes AS existing_zip
      WHERE existing_zip.zip_code_prefix = zip_source.zip_code_prefix
  );
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_orders_customers'
      AND parent_object_id = OBJECT_ID('sales.orders')
)
BEGIN
    ALTER TABLE sales.orders WITH CHECK
    ADD CONSTRAINT fk_sales_orders_customers
        FOREIGN KEY (customer_id)
        REFERENCES sales.customers (customer_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_order_items_orders'
      AND parent_object_id = OBJECT_ID('sales.order_items')
)
BEGIN
    ALTER TABLE sales.order_items WITH CHECK
    ADD CONSTRAINT fk_sales_order_items_orders
        FOREIGN KEY (order_id)
        REFERENCES sales.orders (order_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_order_items_products'
      AND parent_object_id = OBJECT_ID('sales.order_items')
)
BEGIN
    /* sales.order_items.product_id -> sales.products.product_id */
    ALTER TABLE sales.order_items WITH CHECK
    ADD CONSTRAINT fk_sales_order_items_products
        FOREIGN KEY (product_id)
        REFERENCES sales.products (product_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_order_items_sellers'
      AND parent_object_id = OBJECT_ID('sales.order_items')
)
BEGIN
    ALTER TABLE sales.order_items WITH CHECK
    ADD CONSTRAINT fk_sales_order_items_sellers
        FOREIGN KEY (seller_id)
        REFERENCES sales.sellers (seller_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_order_payments_orders'
      AND parent_object_id = OBJECT_ID('sales.order_payments')
)
BEGIN
    ALTER TABLE sales.order_payments WITH CHECK
    ADD CONSTRAINT fk_sales_order_payments_orders
        FOREIGN KEY (order_id)
        REFERENCES sales.orders (order_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_order_reviews_orders'
      AND parent_object_id = OBJECT_ID('sales.order_reviews')
)
BEGIN
    ALTER TABLE sales.order_reviews WITH CHECK
    ADD CONSTRAINT fk_sales_order_reviews_orders
        FOREIGN KEY (order_id)
        REFERENCES sales.orders (order_id);
END;
GO

/*
    Some Olist products have categories that are missing from the translation CSV.
    WITH NOCHECK keeps the relationship visible without rewriting source data.
*/
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_products_product_category_translation'
      AND parent_object_id = OBJECT_ID('sales.products')
)
BEGIN
    /* sales.products.product_category_name -> sales.product_category_translation.product_category_name */
    ALTER TABLE sales.products WITH NOCHECK
    ADD CONSTRAINT fk_sales_products_product_category_translation
        FOREIGN KEY (product_category_name)
        REFERENCES sales.product_category_translation (product_category_name);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_customers_zip_code_prefixes'
      AND parent_object_id = OBJECT_ID('sales.customers')
)
BEGIN
    ALTER TABLE sales.customers WITH CHECK
    ADD CONSTRAINT fk_sales_customers_zip_code_prefixes
        FOREIGN KEY (customer_zip_code_prefix)
        REFERENCES geolocation.zip_code_prefixes (zip_code_prefix);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_sales_sellers_zip_code_prefixes'
      AND parent_object_id = OBJECT_ID('sales.sellers')
)
BEGIN
    ALTER TABLE sales.sellers WITH CHECK
    ADD CONSTRAINT fk_sales_sellers_zip_code_prefixes
        FOREIGN KEY (seller_zip_code_prefix)
        REFERENCES geolocation.zip_code_prefixes (zip_code_prefix);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'fk_geolocation_geolocation_zip_code_prefixes'
      AND parent_object_id = OBJECT_ID('geolocation.geolocation')
)
BEGIN
    ALTER TABLE geolocation.geolocation WITH CHECK
    ADD CONSTRAINT fk_geolocation_geolocation_zip_code_prefixes
        FOREIGN KEY (geolocation_zip_code_prefix)
        REFERENCES geolocation.zip_code_prefixes (zip_code_prefix);
END;
GO
