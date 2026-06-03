USE WAREHOUSE ECOMMERCE_INGEST_WH;
USE DATABASE ECOMMERCE_ANALYTICS_DB;

CREATE SCHEMA IF NOT EXISTS RAW_STREAM
    COMMENT = 'Raw streaming data loaded from the real-time stream pipeline';

USE SCHEMA RAW_STREAM;


create or replace TABLE ECOMMERCE_ANALYTICS_DB.RAW_STREAM.RAW_CUSTOMERS (
	"customer_id" VARCHAR(16777216),
	"customer_unique_id" VARCHAR(16777216),
	"customer_zip_code_prefix" NUMBER(38,0),
	"customer_city" VARCHAR(16777216),
	"customer_state" VARCHAR(16777216),
	"ingested_at" TIMESTAMP_NTZ(9)
);

create or replace TABLE ECOMMERCE_ANALYTICS_DB.RAW_STREAM.RAW_ORDERS (
	"event_type" VARCHAR(16777216),
	"order_id" VARCHAR(16777216),
	"customer_id" VARCHAR(16777216),
	"order_status" VARCHAR(16777216),
	"event_timestamp" TIMESTAMP_NTZ(9),
	"order_purchase_timestamp" TIMESTAMP_NTZ(9),
	"order_approved_at" TIMESTAMP_NTZ(9),
	"order_delivered_carrier_date" TIMESTAMP_NTZ(9),
	"order_delivered_customer_date" TIMESTAMP_NTZ(9),
	"order_estimated_delivery_date" TIMESTAMP_NTZ(9),
	"ingested_at" TIMESTAMP_NTZ(9)
);


create or replace TABLE ECOMMERCE_ANALYTICS_DB.RAW_STREAM.RAW_ORDER_ITEMS (
	"order_id" VARCHAR(16777216),
	"order_item_id" NUMBER(38,0),
	"product_id" VARCHAR(16777216),
	"seller_id" VARCHAR(16777216),
	"shipping_limit_date" TIMESTAMP_NTZ(9),
	"price" FLOAT,
	"freight_value" FLOAT,
	"ingested_at" TIMESTAMP_NTZ(9)
);

create or replace TABLE ECOMMERCE_ANALYTICS_DB.RAW_STREAM.RAW_PAYMENTS (
	"order_id" VARCHAR(16777216),
	"payment_sequential" NUMBER(38,0),
	"payment_type" VARCHAR(16777216),
	"payment_installments" NUMBER(38,0),
	"payment_value" FLOAT,
	"ingested_at" TIMESTAMP_NTZ(9)
);

create or replace TABLE ECOMMERCE_ANALYTICS_DB.RAW_STREAM.RAW_REVIEWS (
	"review_id" VARCHAR(16777216),
	"order_id" VARCHAR(16777216),
	"review_score" NUMBER(38,0),
	"review_comment_title" VARCHAR(16777216),
	"review_comment_message" VARCHAR(16777216),
	"review_creation_date" TIMESTAMP_NTZ(9),
	"review_answer_timestamp" TIMESTAMP_NTZ(9),
	"ingested_at" TIMESTAMP_NTZ(9) NOT NULL
);
