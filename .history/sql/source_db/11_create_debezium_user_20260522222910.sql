/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Create SQL Server login/user for Debezium CDC connector.

    Important:
        Change the password before running this script.
        Do not commit real passwords to GitHub.
*/

USE master;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.sql_logins
    WHERE name = 'debezium_user'
)
BEGIN
    CREATE LOGIN debezium_user
    WITH PASSWORD = 'ChangeMe_StrongPassword_12345',
         CHECK_POLICY = OFF,
         CHECK_EXPIRATION = OFF;
END;
GO

USE Ecommerce_Source_DB;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = 'debezium_user'
)
BEGIN
    CREATE USER debezium_user FOR LOGIN debezium_user;
END;
GO

ALTER ROLE db_datareader ADD MEMBER debezium_user;
GO

GRANT SELECT ON SCHEMA::sales TO debezium_user;
GRANT SELECT ON SCHEMA::cdc TO debezium_user;
GRANT VIEW DATABASE STATE TO debezium_user;
GO

SELECT
    dp.name AS database_user,
    dp.type_desc,
    dp.create_date
FROM sys.database_principals dp
WHERE dp.name = 'debezium_user';
GO