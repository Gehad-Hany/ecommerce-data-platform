/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Enable SQL Server CDC for selected source tables only.

    Scope:
        This script only enables CDC.
        It does not insert, update, delete, or test CDC changes.

    CDC-enabled tables:
        sales.customers
        sales.products
        sales.sellers
*/

USE Ecommerce_Source_DB;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = DB_NAME()
      AND is_cdc_enabled = 1
)
BEGIN
    EXEC sys.sp_cdc_enable_db;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE capture_instance = 'sales_customers'
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'sales',
        @source_name = N'customers',
        @role_name = NULL,
        @capture_instance = N'sales_customers',
        @supports_net_changes = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE capture_instance = 'sales_products'
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'sales',
        @source_name = N'products',
        @role_name = NULL,
        @capture_instance = N'sales_products',
        @supports_net_changes = 1;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM cdc.change_tables
    WHERE capture_instance = 'sales_sellers'
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'sales',
        @source_name = N'sellers',
        @role_name = NULL,
        @capture_instance = N'sales_sellers',
        @supports_net_changes = 1;
END;
GO

SELECT
    name AS database_name,
    is_cdc_enabled
FROM sys.databases
WHERE name = DB_NAME();
GO

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.is_tracked_by_cdc
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name = 'sales'
  AND t.name IN ('customers', 'products', 'sellers')
ORDER BY
    s.name,
    t.name;
GO

SELECT
    capture_instance,
    source_object_id,
    start_lsn,
    supports_net_changes
FROM cdc.change_tables
WHERE capture_instance IN (
    'sales_customers',
    'sales_products',
    'sales_sellers'
)
ORDER BY capture_instance;
GO