-- Create warehouse for data ingestion and processing

CREATE WAREHOUSE IF NOT EXISTS ECOMMERCE_INGEST_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;



-- Create database and schemas
    
CREATE DATABASE IF NOT EXISTS ECOMMERCE_ANALYTICS_DB
    COMMENT = 'Database for e-commerce batch, CDC, real-time, and analytics layers';

USE DATABASE ECOMMERCE_ANALYTICS_DB;

CREATE SCHEMA IF NOT EXISTS RAW_BATCH
    COMMENT = 'Raw batch data loaded from SQL Server source tables';

CREATE SCHEMA IF NOT EXISTS RAW_CDC
    COMMENT = 'Prepared schema for future CDC change events from Debezium/Kafka';

CREATE SCHEMA IF NOT EXISTS RAW_STREAM
    COMMENT = 'Raw streaming data loaded from the real-time stream pipeline';

CREATE SCHEMA IF NOT EXISTS RAW_REALTIME
    COMMENT = 'Prepared schema for future real-time orders API events';

CREATE SCHEMA IF NOT EXISTS GOLD
    COMMENT = 'Business-ready dimensional model';



USE WAREHOUSE ECOMMERCE_INGEST_WH;
USE DATABASE ECOMMERCE_ANALYTICS_DB;
USE SCHEMA RAW_BATCH;

SHOW WAREHOUSES LIKE 'ECOMMERCE_INGEST_WH';
SHOW DATABASES LIKE 'ECOMMERCE_ANALYTICS_DB';
SHOW SCHEMAS IN DATABASE ECOMMERCE_ANALYTICS_DB;
    
