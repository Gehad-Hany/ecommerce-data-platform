/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Create source database schemas.
*/

USE Ecommerce_Source_DB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sales')
BEGIN
    EXEC('CREATE SCHEMA sales');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'geolocation')
BEGIN
    EXEC('CREATE SCHEMA geolocation');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'calendar')
BEGIN
    EXEC('CREATE SCHEMA calendar');
END;
GO