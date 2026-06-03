USE WAREHOUSE ECOMMERCE_INGEST_WH;
USE DATABASE ECOMMERCE_ANALYTICS_DB;
USE SCHEMA RAW_BATCH;

CREATE TABLE IF NOT EXISTS CUSTOMERS (
    customer_id CHAR(32) NOT NULL,
    customer_unique_id CHAR(32),
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

CREATE TABLE IF NOT EXISTS ORDERS (
    order_id CHAR(32) NOT NULL,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP_NTZ(0),
    order_approved_at TIMESTAMP_NTZ(0),
    order_delivered_carrier_date TIMESTAMP_NTZ(0),
    order_delivered_customer_date TIMESTAMP_NTZ(0),
    order_estimated_delivery_date TIMESTAMP_NTZ(0)
);

CREATE TABLE IF NOT EXISTS ORDER_ITEMS (
    order_id CHAR(32) NOT NULL,
    order_item_id NUMBER(38, 0) NOT NULL,
    product_id CHAR(32),
    seller_id CHAR(32),
    shipping_limit_date TIMESTAMP_NTZ(0),
    price NUMBER(12, 2),
    freight_value NUMBER(12, 2)
);

CREATE TABLE IF NOT EXISTS ORDER_PAYMENTS (
    order_id CHAR(32) NOT NULL,
    payment_sequential NUMBER(38, 0) NOT NULL,
    payment_type VARCHAR(30),
    payment_installments NUMBER(38, 0),
    payment_value NUMBER(12, 2)
);

CREATE TABLE IF NOT EXISTS ORDER_REVIEWS (
    review_id CHAR(32) NOT NULL,
    order_id CHAR(32) NOT NULL,
    review_score NUMBER(3, 0),
    review_creation_date TIMESTAMP_NTZ(0),
    review_answer_timestamp TIMESTAMP_NTZ(0)
);

CREATE TABLE IF NOT EXISTS PRODUCTS (
    product_id CHAR(32) NOT NULL,
    product_category_name VARCHAR(100),
    product_name_lenght NUMBER(38, 0),
    product_description_lenght NUMBER(38, 0),
    product_photos_qty NUMBER(38, 0),
    product_weight_g NUMBER(38, 0),
    product_length_cm NUMBER(38, 0),
    product_height_cm NUMBER(38, 0),
    product_width_cm NUMBER(38, 0)
);

CREATE TABLE IF NOT EXISTS SELLERS (
    seller_id CHAR(32) NOT NULL,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

CREATE TABLE IF NOT EXISTS PRODUCT_CATEGORY_TRANSLATION (
    product_category_name VARCHAR(100) NOT NULL,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS GEOLOCATION (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat NUMBER(11, 8),
    geolocation_lng NUMBER(11, 8),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);

CREATE TABLE IF NOT EXISTS ZIP_CODE_PREFIXES (
    zip_code_prefix VARCHAR(5) NOT NULL
);

CREATE TABLE IF NOT EXISTS BRAZIL_HOLIDAYS (
    calendar_year NUMBER(38, 0) NOT NULL,
    calendar_date DATE NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_type VARCHAR(30) NOT NULL,
    country_code CHAR(2) NOT NULL
);

SHOW TABLES IN SCHEMA ECOMMERCE_ANALYTICS_DB.RAW_BATCH;
