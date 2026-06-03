/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Create source tables for the Olist dataset and Brazil calendar data.
*/

USE Ecommerce_Source_DB;
GO

IF OBJECT_ID('sales.customers', 'U') IS NULL
BEGIN
    CREATE TABLE sales.customers (
        customer_id CHAR(32) NOT NULL,
        customer_unique_id CHAR(32) NULL,
        customer_zip_code_prefix VARCHAR(5) NULL,
        customer_city NVARCHAR(100) NULL,
        customer_state CHAR(2) NULL,
        CONSTRAINT pk_sales_customers PRIMARY KEY CLUSTERED (customer_id)
    );
END;
GO

IF OBJECT_ID('sales.orders', 'U') IS NULL
BEGIN
    CREATE TABLE sales.orders (
        order_id CHAR(32) NOT NULL,
        customer_id CHAR(32) NOT NULL,
        order_status VARCHAR(20) NULL,
        order_purchase_timestamp DATETIME2(0) NULL,
        order_approved_at DATETIME2(0) NULL,
        order_delivered_carrier_date DATETIME2(0) NULL,
        order_delivered_customer_date DATETIME2(0) NULL,
        order_estimated_delivery_date DATETIME2(0) NULL,
        CONSTRAINT pk_sales_orders PRIMARY KEY CLUSTERED (order_id)
    );
END;
GO

IF OBJECT_ID('sales.order_items', 'U') IS NULL
BEGIN
    CREATE TABLE sales.order_items (
        order_id CHAR(32) NOT NULL,
        order_item_id INT NOT NULL,
        product_id CHAR(32) NULL,
        seller_id CHAR(32) NULL,
        shipping_limit_date DATETIME2(0) NULL,
        price DECIMAL(12, 2) NULL,
        freight_value DECIMAL(12, 2) NULL,
        CONSTRAINT pk_sales_order_items PRIMARY KEY CLUSTERED (order_id, order_item_id)
    );
END;
GO

IF OBJECT_ID('sales.order_payments', 'U') IS NULL
BEGIN
    CREATE TABLE sales.order_payments (
        order_id CHAR(32) NOT NULL,
        payment_sequential INT NOT NULL,
        payment_type VARCHAR(30) NULL,
        payment_installments INT NULL,
        payment_value DECIMAL(12, 2) NULL,
        CONSTRAINT pk_sales_order_payments PRIMARY KEY CLUSTERED (order_id, payment_sequential)
    );
END;
GO

IF OBJECT_ID('sales.order_reviews', 'U') IS NULL
BEGIN
    CREATE TABLE sales.order_reviews (
        review_id CHAR(32) NOT NULL,
        order_id CHAR(32) NOT NULL,
        review_score TINYINT NULL,
        review_creation_date DATETIME2(0) NULL,
        review_answer_timestamp DATETIME2(0) NULL,
        CONSTRAINT pk_sales_order_reviews PRIMARY KEY CLUSTERED (review_id, order_id)
    );
END;
GO

IF OBJECT_ID('sales.products', 'U') IS NULL
BEGIN
    CREATE TABLE sales.products (
        product_id CHAR(32) NOT NULL,
        product_category_name NVARCHAR(100) NULL,
        product_name_lenght INT NULL,
        product_description_lenght INT NULL,
        product_photos_qty INT NULL,
        product_weight_g INT NULL,
        product_length_cm INT NULL,
        product_height_cm INT NULL,
        product_width_cm INT NULL,
        CONSTRAINT pk_sales_products PRIMARY KEY CLUSTERED (product_id)
    );
END;
GO

IF OBJECT_ID('sales.sellers', 'U') IS NULL
BEGIN
    CREATE TABLE sales.sellers (
        seller_id CHAR(32) NOT NULL,
        seller_zip_code_prefix VARCHAR(5) NULL,
        seller_city NVARCHAR(100) NULL,
        seller_state CHAR(2) NULL,
        CONSTRAINT pk_sales_sellers PRIMARY KEY CLUSTERED (seller_id)
    );
END;
GO

IF OBJECT_ID('sales.product_category_translation', 'U') IS NULL
BEGIN
    CREATE TABLE sales.product_category_translation (
        product_category_name NVARCHAR(100) NOT NULL,
        product_category_name_english NVARCHAR(100) NULL,
        CONSTRAINT pk_sales_product_category_translation PRIMARY KEY CLUSTERED (product_category_name)
    );
END;
GO

IF OBJECT_ID('geolocation.geolocation', 'U') IS NULL
BEGIN
    CREATE TABLE geolocation.geolocation (
        geolocation_zip_code_prefix VARCHAR(5) NULL,
        geolocation_lat DECIMAL(10, 7) NULL,
        geolocation_lng DECIMAL(10, 7) NULL,
        geolocation_city NVARCHAR(100) NULL,
        geolocation_state CHAR(2) NULL
    );
END;
GO


IF OBJECT_ID('calendar.brazil_holidays', 'U') IS NULL
BEGIN
    CREATE TABLE calendar.brazil_holidays (
        calendar_year INT NOT NULL,
        calendar_date DATE NOT NULL,
        event_name NVARCHAR(100) NOT NULL,
        event_type VARCHAR(30) NOT NULL,
        country_code CHAR(2) NOT NULL,
        CONSTRAINT pk_calendar_brazil_holidays PRIMARY KEY CLUSTERED (calendar_date, event_name)
    );
END;
GO




