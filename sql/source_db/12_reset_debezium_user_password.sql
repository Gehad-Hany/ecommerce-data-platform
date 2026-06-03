/*
    Project: E-Commerce Sales Analytics and CDC Platform
    Purpose: Reset Debezium SQL Server login password and permissions.

    Important:
        Use this script if Debezium shows "Login failed for user 'debezium_user'".
        Keep the password synchronized with docker/cdc/.env.
*/

USE master;
GO

ALTER LOGIN debezium_user ENABLE;
GO

ALTER LOGIN debezium_user
WITH PASSWORD = 'ChangeMe_StrongPassword_12345',
     CHECK_POLICY = OFF,
     CHECK_EXPIRATION = OFF;
GO

USE Ecommerce_Source_DB;
GO

ALTER USER debezium_user WITH LOGIN = debezium_user;
GO

ALTER ROLE db_datareader ADD MEMBER debezium_user;
GO

GRANT SELECT ON SCHEMA::sales TO debezium_user;
GRANT SELECT ON SCHEMA::cdc TO debezium_user;
GRANT VIEW DATABASE STATE TO debezium_user;
GO