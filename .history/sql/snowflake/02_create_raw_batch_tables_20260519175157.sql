/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Create the SQL Server source database.
*/

IF DB_ID('Ecommerce_Source_DB') IS NULL
BEGIN
    CREATE DATABASE Ecommerce_Source_DB;
END;
GO

ALTER DATABASE Ecommerce_Source_DB SET RECOVERY SIMPLE;
GO