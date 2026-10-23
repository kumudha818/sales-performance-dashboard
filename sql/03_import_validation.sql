-- =============================================================================
-- 03_import_validation.sql
-- Purpose : Import CSV data into the star schema and validate record counts.
-- Target  : MySQL 8.0
-- Run after: 02_create_tables.sql
--
-- IMPORTANT WINDOWS SETUP STEPS:
-- 1. Enable LOCAL INFILE in MySQL Workbench:
--    Edit → Preferences → SQL Editor → "Allow loading local data"  ✓
--    OR connect with:  mysql --local-infile=1 -u root -p sales_performance
-- 2. In MySQL server my.ini add: local_infile=ON
-- 3. Restart MySQL service after my.ini change.
-- 4. Replace <YOUR_ABSOLUTE_PATH> below with the actual Windows path.
--    Use forward slashes:  C:/Users/.../data/processed/sales_clean.csv
-- =============================================================================

USE sales_performance;

-- ── Step 1: Staging table (mirrors CSV exactly) ───────────────────────────────
DROP TABLE IF EXISTS stg_sales;
CREATE TABLE stg_sales (
    row_id        INT,
    order_id      VARCHAR(30),
    order_date    VARCHAR(20),   -- imported as VARCHAR, cast later
    ship_date     VARCHAR(20),
    ship_mode     VARCHAR(30),
    customer_id   VARCHAR(20),
    customer_name VARCHAR(100),
    segment       VARCHAR(30),
    country       VARCHAR(50),
    state         VARCHAR(50),
    city          VARCHAR(100),
    region        VARCHAR(20),
    product_id    VARCHAR(20),
    category      VARCHAR(50),
    sub_category  VARCHAR(50),
    product_name  VARCHAR(200),
    sales         VARCHAR(20),
    quantity      VARCHAR(10),
    discount      VARCHAR(10),
    profit        VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Step 2: LOAD from CSV ─────────────────────────────────────────────────────
-- Replace <YOUR_ABSOLUTE_PATH> with the full Windows path, forward slashes:
LOAD DATA LOCAL INFILE '<YOUR_ABSOLUTE_PATH>/data/processed/sales_clean.csv'
INTO TABLE stg_sales
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(row_id, order_id, order_date, ship_date, ship_mode, customer_id,
 customer_name, segment, country, state, city, region, product_id,
 category, sub_category, product_name, sales, quantity, discount, profit);

-- ── Step 3: Verify staging load ──────────────────────────────────────────────
SELECT COUNT(*) AS stg_row_count FROM stg_sales;
-- Expected: 7500

-- ── Step 4: Populate dim_date (all dates in dataset) ─────────────────────────
-- Build a calendar spanning the date range of our data
INSERT IGNORE INTO dim_date (date_key, full_date, year, quarter, month, month_name, week, day_of_week, is_weekend)
WITH RECURSIVE calendar AS (
    SELECT DATE('2021-01-01') AS d
    UNION ALL
    SELECT DATE_ADD(d, INTERVAL 1 DAY)
    FROM calendar
    WHERE d < DATE('2024-01-31')
)
SELECT
    DATE_FORMAT(d, '%Y%m%d')   AS date_key,
    d                          AS full_date,
    YEAR(d)                    AS year,
    QUARTER(d)                 AS quarter,
    MONTH(d)                   AS month,
    DATE_FORMAT(d, '%M')       AS month_name,
    WEEK(d, 3)                 AS week,
    DAYOFWEEK(d)               AS day_of_week,
    IF(DAYOFWEEK(d) IN (1,7), 1, 0) AS is_weekend
FROM calendar;

SELECT COUNT(*) AS dim_date_rows FROM dim_date;
-- Expected: ~1127 (2021-01-01 to 2024-01-31)

-- ── Step 5: Populate dim_customer ────────────────────────────────────────────
INSERT IGNORE INTO dim_customer (customer_id, customer_name, segment)
SELECT DISTINCT customer_id, customer_name, segment
FROM stg_sales;

SELECT COUNT(*) AS dim_customer_rows FROM dim_customer;
-- Expected: 795

-- ── Step 6: Populate dim_product ─────────────────────────────────────────────
INSERT IGNORE INTO dim_product (product_id, category, sub_category, product_name)
SELECT DISTINCT product_id, category, sub_category, product_name
FROM stg_sales;

SELECT COUNT(*) AS dim_product_rows FROM dim_product;
-- Expected: 80

-- ── Step 7: Populate fact_sales ──────────────────────────────────────────────
INSERT INTO fact_sales
    (row_id, order_id, order_date_key, ship_date_key, ship_mode,
     customer_id, country, state, city, region,
     product_id, sales, quantity, discount, profit)
SELECT
    row_id,
    order_id,
    DATE_FORMAT(STR_TO_DATE(order_date, '%Y-%m-%d'), '%Y%m%d') AS order_date_key,
    DATE_FORMAT(STR_TO_DATE(ship_date,  '%Y-%m-%d'), '%Y%m%d') AS ship_date_key,
    ship_mode,
    customer_id,
    country,
    state,
    city,
    region,
    product_id,
    CAST(sales    AS DECIMAL(12,2)),
    CAST(quantity AS SIGNED),
    CAST(discount AS DECIMAL(5,4)),
    CAST(profit   AS DECIMAL(12,2))
FROM stg_sales;

SELECT COUNT(*) AS fact_sales_rows FROM fact_sales;
-- Expected: 7500

-- ── Step 8: Validation checks ────────────────────────────────────────────────
-- 8a. Totals should match Python baseline exactly
SELECT
    COUNT(*)                   AS total_rows,
    COUNT(DISTINCT order_id)   AS total_orders,
    COUNT(DISTINCT customer_id)AS total_customers,
    COUNT(DISTINCT product_id) AS total_products,
    ROUND(SUM(sales),  2)      AS total_sales,
    ROUND(SUM(profit), 2)      AS total_profit,
    SUM(quantity)              AS total_quantity
FROM fact_sales;
-- Expected: rows=7500, orders=4360, customers=795, products=80
--           sales≈3333386.08, profit≈224989.95, qty=20968

-- 8b. Orphan checks (should return 0 rows each)
SELECT 'Orphan customers' AS check_name, COUNT(*) AS cnt
FROM fact_sales f LEFT JOIN dim_customer c USING(customer_id)
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'Orphan products', COUNT(*)
FROM fact_sales f LEFT JOIN dim_product p USING(product_id)
WHERE p.product_id IS NULL
UNION ALL
SELECT 'Orphan order dates', COUNT(*)
FROM fact_sales f LEFT JOIN dim_date d ON f.order_date_key = d.date_key
WHERE d.date_key IS NULL
UNION ALL
SELECT 'Orphan ship dates', COUNT(*)
FROM fact_sales f LEFT JOIN dim_date d ON f.ship_date_key = d.date_key
WHERE d.date_key IS NULL;

-- 8c. Data sanity
SELECT
    SUM(CASE WHEN sales    <= 0 THEN 1 ELSE 0 END) AS negative_or_zero_sales,
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS negative_or_zero_qty,
    SUM(CASE WHEN discount < 0 OR discount > 1 THEN 1 ELSE 0 END) AS bad_discounts
FROM fact_sales;
-- Expected: all zeros

-- Clean up staging table (optional — keep for re-validation if needed)
-- DROP TABLE IF EXISTS stg_sales;

SELECT 'Import and validation complete.' AS status;
