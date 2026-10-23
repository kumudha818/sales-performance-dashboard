-- =============================================================================
-- 05_regional_analysis.sql
-- Purpose : Sales and profit analysis by region and state.
-- Target  : MySQL 8.0
-- Business: Identifies the strongest geographic markets and investment opportunities.
-- =============================================================================

USE sales_performance;

-- ---------------------------------------------------------------------------
-- Q1: Sales and Profit by Region
-- Expected (from validated dataset):
--   East   ≈ 876,213 sales, 57,523 profit (6.56% margin)
--   West   ≈ 868,523 sales, 58,151 profit (6.70% margin)
--   Central≈ 803,597 sales, 53,597 profit (6.67% margin)
--   South  ≈ 785,054 sales, 55,719 profit (7.10% margin) ← highest margin
-- ---------------------------------------------------------------------------
SELECT
    f.region,
    COUNT(DISTINCT f.order_id)                         AS total_orders,
    COUNT(DISTINCT f.customer_id)                      AS total_customers,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(SUM(f.sales) * 100.0 /
        NULLIF((SELECT SUM(sales) FROM fact_sales), 0), 2)   AS sales_contribution_pct,
    RANK() OVER (ORDER BY SUM(f.sales) DESC)           AS sales_rank,
    RANK() OVER (ORDER BY SUM(f.profit) DESC)          AS profit_rank
FROM fact_sales f
GROUP BY f.region
ORDER BY total_sales DESC;


-- ---------------------------------------------------------------------------
-- Q2: Sales and Profit by State (Top 20 states by sales)
-- Business: Drill-down from region to state for map visualisation.
-- ---------------------------------------------------------------------------
SELECT
    f.region,
    f.state,
    COUNT(DISTINCT f.order_id)                        AS total_orders,
    ROUND(SUM(f.sales),  2)                           AS total_sales,
    ROUND(SUM(f.profit), 2)                           AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    RANK() OVER (ORDER BY SUM(f.sales) DESC)          AS state_sales_rank
FROM fact_sales f
GROUP BY f.region, f.state
ORDER BY total_sales DESC
LIMIT 20;


-- ---------------------------------------------------------------------------
-- Q3: All States — for Power BI map visualisation
-- Business: Complete list needed so the Power BI map populates correctly.
-- ---------------------------------------------------------------------------
SELECT
    f.region,
    f.state,
    ROUND(SUM(f.sales),  2)     AS total_sales,
    ROUND(SUM(f.profit), 2)     AS total_profit,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales f
GROUP BY f.region, f.state
ORDER BY f.region, total_sales DESC;


-- ---------------------------------------------------------------------------
-- Q4: Best and Worst Performing States (Top 5 / Bottom 5 by profit)
-- Business: Pinpoints where operational focus is most needed.
-- ---------------------------------------------------------------------------
WITH state_metrics AS (
    SELECT
        f.state,
        f.region,
        ROUND(SUM(f.sales),  2)                           AS total_sales,
        ROUND(SUM(f.profit), 2)                           AS total_profit,
        ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
    FROM fact_sales f
    GROUP BY f.state, f.region
)
SELECT 'Top 5 by Profit'  AS category, state, region, total_sales, total_profit, profit_margin_pct
FROM   state_metrics
ORDER BY total_profit DESC
LIMIT 5
UNION ALL
SELECT 'Bottom 5 by Profit', state, region, total_sales, total_profit, profit_margin_pct
FROM   state_metrics
ORDER BY total_profit ASC
LIMIT 5;


-- ---------------------------------------------------------------------------
-- Q5: Regional performance using dense ranking window function
-- Business: Shows relative standing of each region within each category.
-- ---------------------------------------------------------------------------
SELECT
    f.region,
    p.category,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    DENSE_RANK() OVER (
        PARTITION BY p.category
        ORDER BY SUM(f.sales) DESC
    )                                                  AS rank_within_category
FROM fact_sales   f
JOIN dim_product  p USING(product_id)
GROUP BY f.region, p.category
ORDER BY p.category, rank_within_category;
