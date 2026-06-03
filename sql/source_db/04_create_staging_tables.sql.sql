USE Ecommerce_Source_DB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
BEGIN
    EXEC('CREATE SCHEMA staging');
END;
GO

IF OBJECT_ID('staging.olist_customers', 'U') IS NULL
BEGIN
    CREATE TABLE staging.olist_customers (
        customer_id NVARCHAR(100) NULL,
        customer_unique_id NVARCHAR(100) NULL,
        customer_zip_code_prefix NVARCHAR(20) NULL,
        customer_city NVARCHAR(200) NULL,
        customer_state NVARCHAR(20) NULL
    );
END;
GO

IF OBJECT_ID('staging.olist_orders', 'U') IS NULL
BEGIN
    CREATE TABLE staging.olist_orders (
        order_id NVARCHAR(100) NULL,
        customer_id NVARCHAR(100) NULL,
        order_status NVARCHAR(50) NULL,
        order_purchase_timestamp NVARCHAR(50) NULL,
        order_approved_at NVARCHAR(50) NULL,
        order_delivered_carrier_date NVARCHAR(50) NULL,
        order_delivered_customer_date NVARCHAR(50) NULL,
        order_estimated_delivery_date NVARCHAR(50) NULL
    );
END;
GO

IF OBJECT_ID('staging.olist_order_items', 'U') IS NULL
BEGIN
    CREATE TABLE staging.olist_order_items (
        order_id NVARCHAR(100) NULL,
        order_item_id NVARCHAR(20) NULL,
        product_id NVARCHAR(100) NULL,
        seller_id NVARCHAR(100) NULL,
        shipping_limit_date NVARCHAR(50) NULL,
        price NVARCHAR(50) NULL,
        freight_value NVARCHAR(50) NULL
    );
END;
GO

IF OBJECT_ID('staging.olist_order_payments', 'U') IS NULL
BEGIN
    CREATE TABLE staging.olist_order_payments (
        order_id NVARCHAR(100) NULL,
        payment_sequential NVARCHAR(20) NULL,
        payment_type NVARCHAR(50) NULL,
        payment_installments NVARCHAR(20) NULL,
        payment_value NVARCHAR(50) NULL
    );
END;
GO

IF OBJECT_ID('staging.olist_order_reviews', 'U') IS NOT NULL
BEGIN
    DROP TABLE staging.olist_order_reviews;
END;
GO

CREATE TABLE staging.olist_order_reviews (
    review_id NVARCHAR(100) NULL,
    order_id NVARCHAR(100) NULL,
    review_score NVARCHAR(20) NULL,
    review_creation_date NVARCHAR(50) NULL,
    review_answer_timestamp NVARCHAR(50) NULL
);
GO

IF OBJECT_ID('staging.olist_products', 'U') IS NULL
BEGIN
    CREATE TABLE staging.olist_products (
        product_id NVARCHAR(100) NULL,
        product_category_name NVARCHAR(200) NULL,
        product_name_lenght NVARCHAR(20) NULL,
        product_description_lenght NVARCHAR(20) NULL,
        product_photos_qty NVARCHAR(20) NULL,
        product_weight_g NVARCHAR(20) NULL,
        product_length_cm NVARCHAR(20) NULL,
        product_height_cm NVARCHAR(20) NULL,
        product_width_cm NVARCHAR(20) NULL
    );
END;
GO

IF OBJECT_ID('staging.olist_sellers', 'U') IS NULL
BEGIN
    CREATE TABLE staging.olist_sellers (
        seller_id NVARCHAR(100) NULL,
        seller_zip_code_prefix NVARCHAR(20) NULL,
        seller_city NVARCHAR(200) NULL,
        seller_state NVARCHAR(20) NULL
    );
END;
GO

IF OBJECT_ID('staging.product_category_translation', 'U') IS NULL
BEGIN
    CREATE TABLE staging.product_category_translation (
        product_category_name NVARCHAR(200) NULL,
        product_category_name_english NVARCHAR(200) NULL
    );
END;
GO

IF OBJECT_ID('staging.olist_geolocation', 'U') IS NULL
BEGIN
    CREATE TABLE staging.olist_geolocation (
        geolocation_zip_code_prefix NVARCHAR(20) NULL,
        geolocation_lat NVARCHAR(50) NULL,
        geolocation_lng NVARCHAR(50) NULL,
        geolocation_city NVARCHAR(200) NULL,
        geolocation_state NVARCHAR(20) NULL
    );
END;
GO

IF OBJECT_ID('staging.brazil_holidays_weekends', 'U') IS NULL
BEGIN
    CREATE TABLE staging.brazil_holidays_weekends (
        [year] NVARCHAR(20) NULL,
        [date] NVARCHAR(50) NULL,
        [name] NVARCHAR(200) NULL,
        [type] NVARCHAR(50) NULL,
        country NVARCHAR(20) NULL
    );
END;
GO