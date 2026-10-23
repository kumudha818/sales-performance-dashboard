-- =============================================================================
-- 10_views.sql
-- Purpose : Create reusable SQL views for frequently used KPI and trend queries.
--           These views are used as direct data sources for Power BI.
-- Target  : MySQL 8.0
-- =============================================================================

USE sales_performance;

-- ---------------------------------------------------------------------------
-- VIEW 1: v_overall_kpis
-- Returns a single-row summary of the key business metrics.
-- Power BI Usage: Source for KPI card visuals on Executive Overview page.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_overall_kpis;
CREATE VIEW v_overall_kpis AS
SELECT
    COUNT(*)                                          AS total_records,
    COUNT(DISTINCT order_id)                          AS total_orders,
    COUNT(DISTINCT customer_id)                       AS total_customers,
    COUNT(DISTINCT product_id)                        AS total_products,
    ROUND(SUM(sales),  2)                             AS total_sales,
    ROUND(SUM(profit), 2)                             AS total_profit,
    SUM(quantity)                                     AS total_quantity,
    ROUND(SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100,  2)       AS profit_margin_pct
FROM fact_sales;


-- ---------------------------------------------------------------------------
-- VIEW 2: v_monthly_sales
-- Monthly sales and profit with MoM and YoY growth.
-- Power BI Usage: Line charts on Trends page.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_monthly_sales;
CREATE VIEW v_monthly_sales AS
WITH base AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        d.quarter,
        CONCAT(d.year, '-', LPAD(d.month, 2, '0')) AS year_month,
        ROUND(SUM(f.sales),  2)                      AS monthly_sales,
        ROUND(SUM(f.profit), 2)                      AS monthly_profit,
        COUNT(DISTINCT f.order_id)                   AS monthly_orders
    FROM fact_sales f
    JOIN dim_date   d ON f.order_date_key = d.date_key
    GROUP BY d.year, d.month, d.month_name, d.quarter
)
SELECT
    year,
    month,
    month_name,
    quarter,
    year_month,
    monthly_sales,
    monthly_profit,
    monthly_orders,
    LAG(monthly_sales) OVER (ORDER BY year, month) AS prev_month_sales,
    ROUND(
        (monthly_sales - LAG(monthly_sales) OVER (ORDER BY year, month))
        / NULLIF(LAG(monthly_sales) OVER (ORDER BY year, month), 0) * 100
    , 2)                                           AS mom_growth_pct,
    SUM(monthly_sales) OVER (
        PARTITION BY year ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                              AS ytd_sales
FROM base;


-- ---------------------------------------------------------------------------
-- VIEW 3: v_regional_performance
-- Sales and profit by region with contribution percentages.
-- Power BI Usage: Bar/column charts on Regional Analysis page.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_regional_performance;
CREATE VIEW v_regional_performance AS
SELECT
    f.region,
    COUNT(DISTINCT f.order_id)                        AS total_orders,
    COUNT(DISTINCT f.customer_id)                     AS total_customers,
    ROUND(SUM(f.sales),  2)                           AS total_sales,
    ROUND(SUM(f.profit), 2)                           AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(SUM(f.sales) * 100.0 /
        (SELECT SUM(sales) FROM fact_sales), 2)       AS sales_contribution_pct,
    RANK() OVER (ORDER BY SUM(f.sales) DESC)          AS sales_rank
FROM fact_sales f
GROUP BY f.region;


-- ---------------------------------------------------------------------------
-- VIEW 4: v_state_performance
-- State-level metrics for Power BI map visual.
-- Power BI Usage: Filled map on Regional page (set Location = state, Values = total_sales).
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_state_performance;
CREATE VIEW v_state_performance AS
SELECT
    f.region,
    f.state,
    f.country,
    COUNT(DISTINCT f.order_id)                         AS total_orders,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales f
GROUP BY f.region, f.state, f.country;


-- ---------------------------------------------------------------------------
-- VIEW 5: v_product_performance
-- Complete product-level metrics.
-- Power BI Usage: Bar charts on Product page; slicer-driven filtering.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_product_performance;
CREATE VIEW v_product_performance AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    COUNT(DISTINCT f.order_id)                         AS orders,
    SUM(f.quantity)                                    AS total_qty,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(f.discount) * 100, 2)                    AS avg_discount_pct,
    RANK() OVER (ORDER BY SUM(f.sales)  DESC)          AS sales_rank,
    RANK() OVER (ORDER BY SUM(f.profit) DESC)          AS profit_rank
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.product_id, p.product_name, p.category, p.sub_category;


-- ---------------------------------------------------------------------------
-- VIEW 6: v_category_summary
-- Category and sub-category profit margin analysis.
-- Power BI Usage: Treemap and stacked bar on Product page.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_category_summary;
CREATE VIEW v_category_summary AS
SELECT
    p.category,
    p.sub_category,
    COUNT(DISTINCT f.order_id)                          AS orders,
    ROUND(SUM(f.sales),  2)                             AS total_sales,
    ROUND(SUM(f.profit), 2)                             AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(f.discount) * 100, 2)                     AS avg_discount_pct,
    SUM(CASE WHEN f.profit < 0 THEN 1 ELSE 0 END)       AS loss_making_lines
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.category, p.sub_category;


-- ---------------------------------------------------------------------------
-- VIEW 7: v_discount_impact
-- Discount bucket analysis for scatter / bar charts.
-- Power BI Usage: Bar chart showing margin vs discount level.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_discount_impact;
CREATE VIEW v_discount_impact AS
SELECT
    CASE
        WHEN discount = 0         THEN '0% No Discount'
        WHEN discount <= 0.10     THEN '1-10%'
        WHEN discount <= 0.20     THEN '11-20%'
        WHEN discount <= 0.30     THEN '21-30%'
        WHEN discount <= 0.40     THEN '31-40%'
        ELSE '41%+'
    END AS discount_bucket,
    ROUND(AVG(discount) * 100, 2)                        AS avg_discount_pct,
    COUNT(*)                                             AS order_lines,
    ROUND(SUM(sales),  2)                                AS total_sales,
    ROUND(SUM(profit), 2)                                AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)          AS loss_making_lines
FROM fact_sales
GROUP BY discount_bucket;


-- Confirm all views created
SHOW FULL TABLES IN sales_performance WHERE Table_type = 'VIEW';
