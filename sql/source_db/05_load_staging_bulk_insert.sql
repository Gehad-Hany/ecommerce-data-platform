USE Ecommerce_Source_DB;
GO

TRUNCATE TABLE staging.olist_customers;
TRUNCATE TABLE staging.olist_orders;
TRUNCATE TABLE staging.olist_order_items;
TRUNCATE TABLE staging.olist_order_payments;
TRUNCATE TABLE staging.olist_order_reviews;
TRUNCATE TABLE staging.olist_products;
TRUNCATE TABLE staging.olist_sellers;
TRUNCATE TABLE staging.product_category_translation;
TRUNCATE TABLE staging.olist_geolocation;
TRUNCATE TABLE staging.brazil_holidays_weekends;
GO

DECLARE @olist_data_folder NVARCHAR(4000) = N'D:\ITI_tasks\ecommerce-data-platform\data\raw\olist\data_set\';
DECLARE @geolocation_file NVARCHAR(4000) = N'D:\ITI_tasks\ecommerce-data-platform\data\raw\geolocation\olist_geolocation_dataset.csv';
DECLARE @calendar_file NVARCHAR(4000) = N'D:\ITI_tasks\ecommerce-data-platform\data\raw\calendar\brazil_holidays_weekends_2016_2018.csv';

DECLARE @sql NVARCHAR(MAX);
DECLARE @bulk_options NVARCHAR(MAX) = N'
WITH (
    FORMAT = ''CSV'',
    FIRSTROW = 2,
    FIELDQUOTE = ''"'',
    FIELDTERMINATOR = '','',
    ROWTERMINATOR = ''0x0a'',
    CODEPAGE = ''65001'',
    TABLOCK
);';

PRINT 'Loading staging.olist_customers';
SET @sql = N'BULK INSERT staging.olist_customers FROM ''' + REPLACE(@olist_data_folder + N'olist_customers_dataset.csv', '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;

PRINT 'Loading staging.olist_orders';
SET @sql = N'BULK INSERT staging.olist_orders FROM ''' + REPLACE(@olist_data_folder + N'olist_orders_dataset.csv', '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;

PRINT 'Loading staging.olist_order_items';
SET @sql = N'BULK INSERT staging.olist_order_items FROM ''' + REPLACE(@olist_data_folder + N'olist_order_items_dataset.csv', '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;

PRINT 'Loading staging.olist_order_payments';
SET @sql = N'BULK INSERT staging.olist_order_payments FROM ''' + REPLACE(@olist_data_folder + N'olist_order_payments_dataset.csv', '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;

PRINT 'Loading staging.olist_order_reviews';
SET @sql = N'BULK INSERT staging.olist_order_reviews FROM ''' + REPLACE(@olist_data_folder + N'olist_order_reviews_dataset.csv', '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;

PRINT 'Loading staging.olist_products';
SET @sql = N'BULK INSERT staging.olist_products FROM ''' + REPLACE(@olist_data_folder + N'olist_products_dataset.csv', '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;

PRINT 'Loading staging.olist_sellers';
SET @sql = N'BULK INSERT staging.olist_sellers FROM ''' + REPLACE(@olist_data_folder + N'olist_sellers_dataset.csv', '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;

PRINT 'Loading staging.product_category_translation';
SET @sql = N'BULK INSERT staging.product_category_translation FROM ''' + REPLACE(@olist_data_folder + N'product_category_name_translation.csv', '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;

PRINT 'Loading staging.olist_geolocation';
SET @sql = N'BULK INSERT staging.olist_geolocation FROM ''' + REPLACE(@geolocation_file, '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;

PRINT 'Loading staging.brazil_holidays_weekends';
SET @sql = N'BULK INSERT staging.brazil_holidays_weekends FROM ''' + REPLACE(@calendar_file, '''', '''''') + N''' ' + @bulk_options;
EXEC sys.sp_executesql @sql;
GO

SELECT 'staging.olist_customers' AS table_name, COUNT(*) AS row_count FROM staging.olist_customers
UNION ALL
SELECT 'staging.olist_orders', COUNT(*) FROM staging.olist_orders
UNION ALL
SELECT 'staging.olist_order_items', COUNT(*) FROM staging.olist_order_items
UNION ALL
SELECT 'staging.olist_order_payments', COUNT(*) FROM staging.olist_order_payments
UNION ALL
SELECT 'staging.olist_order_reviews', COUNT(*) FROM staging.olist_order_reviews
UNION ALL
SELECT 'staging.olist_products', COUNT(*) FROM staging.olist_products
UNION ALL
SELECT 'staging.olist_sellers', COUNT(*) FROM staging.olist_sellers
UNION ALL
SELECT 'staging.product_category_translation', COUNT(*) FROM staging.product_category_translation
UNION ALL
SELECT 'staging.olist_geolocation', COUNT(*) FROM staging.olist_geolocation
UNION ALL
SELECT 'staging.brazil_holidays_weekends', COUNT(*) FROM staging.brazil_holidays_weekends
ORDER BY table_name;
GO


