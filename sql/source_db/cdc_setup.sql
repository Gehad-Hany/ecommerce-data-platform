USE Ecommerce_Source_DB;
GO

EXEC sys.sp_cdc_enable_db;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = 'sales',
    @source_name          = 'customers',
    @capture_instance     = 'sales_customers',
    @role_name            = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = 'sales',
    @source_name          = 'orders',
    @capture_instance     = 'sales_orders',
    @role_name            = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = 'sales',
    @source_name          = 'order_items',
    @capture_instance     = 'sales_order_items',
    @role_name            = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = 'sales',
    @source_name          = 'order_payments',
    @capture_instance     = 'sales_order_payments',
    @role_name            = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = 'sales',
    @source_name          = 'order_reviews',
    @capture_instance     = 'sales_order_reviews',
    @role_name            = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = 'sales',
    @source_name          = 'products',
    @capture_instance     = 'sales_products',
    @role_name            = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = 'sales',
    @source_name          = 'sellers',
    @capture_instance     = 'sales_sellers',
    @role_name            = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = 'sales',
    @source_name          = 'product_category_translation',
    @capture_instance     = 'sales_product_category_translation',
    @role_name            = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema        = 'calendar',
    @source_name          = 'brazil_holidays',
    @capture_instance     = 'calendar_brazil_holidays',
    @role_name            = NULL,
    @supports_net_changes = 0;
GO

CREATE LOGIN debezium_user
    WITH PASSWORD    = 'Debezium123!',
         CHECK_POLICY = OFF;
GO

CREATE USER debezium_user FOR LOGIN debezium_user;
GO

EXEC sp_addrolemember 'db_datareader', 'debezium_user';
GO

GRANT VIEW DATABASE STATE TO debezium_user;
GO

GRANT SELECT ON SCHEMA::cdc TO debezium_user;
GO

GRANT EXECUTE ON SCHEMA::sys TO debezium_user;
GO
