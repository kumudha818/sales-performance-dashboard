-- =============================================================================
-- 04_kpi_analysis.sql
-- Purpose : Compute overall business KPIs used on the Executive Overview page.
-- Target  : MySQL 8.0
-- Business: These figures are the headline numbers appearing in KPI cards.
-- =============================================================================

USE sales_performance;

-- ---------------------------------------------------------------------------
-- Q1: Overall KPI Summary
-- Expected (from validated dataset):
--   total_records=7500, total_orders=4360, total_customers=795
--   total_sales≈3,333,386, total_profit≈224,990, total_quantity=20,968
--   avg_order_value≈764.54, profit_margin_pct≈6.75
-- Interpretation: Profit margin of 6.75% is modest; discount analysis may
--   reveal opportunities to improve margin by reducing high-discount orders.
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                         AS total_records,
    COUNT(DISTINCT f.order_id)                       AS total_orders,
    COUNT(DISTINCT f.customer_id)                    AS total_customers,
    COUNT(DISTINCT f.product_id)                     AS total_products,
    ROUND(SUM(f.sales),    2)                        AS total_sales,
    ROUND(SUM(f.profit),   2)                        AS total_profit,
    SUM(f.quantity)                                  AS total_quantity,
    ROUND(SUM(f.sales) / NULLIF(COUNT(DISTINCT f.order_id), 0), 2) AS avg_order_value,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2)       AS profit_margin_pct
FROM fact_sales f;


-- ---------------------------------------------------------------------------
-- Q2: KPIs Broken Down by Year
-- Business: Shows whether the business is growing year-over-year.
-- ---------------------------------------------------------------------------
SELECT
    d.year,
    COUNT(DISTINCT f.order_id)                       AS orders,
    COUNT(DISTINCT f.customer_id)                    AS customers,
    ROUND(SUM(f.sales),    2)                        AS total_sales,
    ROUND(SUM(f.profit),   2)                        AS total_profit,
    SUM(f.quantity)                                  AS total_quantity,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales   f
JOIN dim_date     d  ON f.order_date_key = d.date_key
GROUP BY d.year
ORDER BY d.year;


-- ---------------------------------------------------------------------------
-- Q3: KPIs by Customer Segment
-- Business: Identifies which segment drives the most revenue and profit.
-- ---------------------------------------------------------------------------
SELECT
    c.segment,
    COUNT(DISTINCT f.order_id)                       AS orders,
    ROUND(SUM(f.sales),  2)                          AS total_sales,
    ROUND(SUM(f.profit), 2)                          AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(SUM(f.sales) / NULLIF(
        (SELECT SUM(sales) FROM fact_sales), 0) * 100, 2)    AS sales_contribution_pct
FROM fact_sales   f
JOIN dim_customer c USING(customer_id)
GROUP BY c.segment
ORDER BY total_sales DESC;


-- ---------------------------------------------------------------------------
-- Q4: KPIs by Ship Mode
-- Business: Understand shipping preference distribution and cost impact.
-- ---------------------------------------------------------------------------
SELECT
    f.ship_mode,
    COUNT(DISTINCT f.order_id)                       AS orders,
    ROUND(SUM(f.sales),  2)                          AS total_sales,
    ROUND(SUM(f.profit), 2)                          AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(COUNT(DISTINCT f.order_id) * 100.0 /
        NULLIF((SELECT COUNT(DISTINCT order_id) FROM fact_sales), 0), 2) AS order_share_pct
FROM fact_sales f
GROUP BY f.ship_mode
ORDER BY orders DESC;
