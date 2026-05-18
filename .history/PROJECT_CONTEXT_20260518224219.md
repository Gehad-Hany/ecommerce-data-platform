# Project Context

## Project Title

E-Commerce Data Platform for Batch Sales Analytics and CDC-Based Change Tracking

## Business Goal

The goal of this project is to build a data engineering platform for an e-commerce business.

The platform focuses on collecting data from multiple sources, loading it into a SQL Server source database, preparing the data for batch processing, and enabling Change Data Capture (CDC) to track changes in important business entities.

This project is designed to support historical sales analysis and change tracking for business reporting.

## Current Project Scope

For now, this project focuses only on:

- Batch pipeline preparation
- SQL Server source database design
- Loading raw source data into SQL Server
- Preparing tables for CDC
- Organizing the project structure
- Preparing the foundation for future Snowflake, dbt, Kafka, Debezium, Databricks, and Power BI work

## Batch Pipeline Overview

The batch pipeline will use historical e-commerce data.

The main steps are:

1. Collect source data files
2. Store raw files inside the project data folder
3. Create a SQL Server source database
4. Create schemas and source tables
5. Load CSV data into SQL Server
6. Prepare the source database for batch extraction
7. Later, move the processed data to the data warehouse layer

## CDC Pipeline Overview

The CDC pipeline will be used to track changes in important business entities.

The main goal of CDC is to capture inserts, updates, and deletes from selected SQL Server tables.

CDC will help the project keep historical changes for entities such as:

- Products
- Customers
- Sellers

This will later support Slowly Changing Dimension Type 2 logic in the data warehouse.

## Tools

The project will use the following tools gradually:

- GitHub for version control
- Visual Studio Code for development
- SQL Server as the source database
- Python for ingestion scripts
- Docker for running services in a consistent environment
- Airflow for batch orchestration
- Snowflake for the data warehouse
- dbt for data modeling
- Kafka for streaming and CDC events
- Debezium for CDC capture
- Databricks for Spark processing
- Power BI for dashboards

## Data Sources

The project uses multiple data sources to simulate a real e-commerce business environment.

### 1. E-Commerce Sales Data — Batch Source

This source contains historical e-commerce sales data, including:

- Orders
- Order items
- Payments
- Customers
- Products
- Sellers
- Reviews

It will be used for historical sales analysis, customer behavior analysis, product performance, payment analysis, and seller performance.

### 2. Geolocation Data — Location Enrichment Source

This source contains geographic information such as:

- Zip code prefixes
- Cities
- States
- Latitude
- Longitude

It will be used to enrich customer and seller data and support geographic analysis such as sales by city and state.

### 3. Brazil Holidays / Calendar Data — External Enrichment Source

This source contains calendar and public holiday information for Brazil.

It will be used to enhance the date dimension and analyze how weekends, holidays, and special dates affect sales performance.

## SQL Server Source Database Plan

SQL Server will be used as the source operational database.

The plan is to:

1. Create the project database
2. Create separate schemas for source data
3. Create tables that match the raw source files
4. Load CSV files into SQL Server
5. Enable CDC on selected tables
6. Use the SQL Server database as the starting point for batch and CDC processing

## What Is Included Now

The current project includes:

- Initial GitHub repository
- Basic folder structure
- Documentation files
- SQL folder for source database scripts
- Data folder for raw files
- Project context file
- Agent instruction file
- Requirements file
- Environment example file

## What Is Excluded for Now

The following parts are not implemented yet:

- Real-time orders API
- Snowflake data warehouse
- dbt models
- Kafka setup
- Debezium CDC connector
- Databricks Spark jobs
- Power BI dashboards
- Full Docker environment
- Full Airflow DAGs

## Important Note

For now, this project focuses only on the Batch Pipeline and CDC preparation.

Real-time orders API, Snowflake, dbt, Kafka, Debezium, Databricks, and Power BI will be added later.