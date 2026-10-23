-- =============================================================================
-- 01_create_database.sql
-- Purpose : Create the sales_performance database.
-- Target  : MySQL 8.0
-- Note    : Run as a MySQL user with CREATE DATABASE privilege.
--           Never store passwords in SQL files. Use environment variables
--           or MySQL Workbench's secure credential store.
-- =============================================================================

-- Drop and recreate for a clean setup (comment out in production)
DROP DATABASE IF EXISTS sales_performance;

CREATE DATABASE sales_performance
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Select the new database for subsequent scripts
USE sales_performance;

SELECT 'Database sales_performance created successfully.' AS status;
