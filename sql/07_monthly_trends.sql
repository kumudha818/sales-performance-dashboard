-- =============================================================================
-- 07_monthly_trends.sql
-- Purpose : Monthly and year-over-year sales/profit trends.
-- Target  : MySQL 8.0
-- Business: Supports seasonal planning and growth forecasting.
-- =============================================================================

USE sales_performance;

-- ---------------------------------------------------------------------------
-- Q1: Monthly Sales and Profit (all years)
-- Business: Reveals seasonality — Q4 spikes in November/December.
-- ---------------------------------------------------------------------------
SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT f.order_id)                               AS orders,
    ROUND(SUM(f.sales),  2)                                  AS monthly_sales,
    ROUND(SUM(f.profit), 2)                                  AS monthly_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales f
JOIN dim_date   d  ON f.order_date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;


-- ---------------------------------------------------------------------------
-- Q2: Month-over-Month Sales Growth using LAG()
-- Business: Identifies accelerating and decelerating months for ops planning.
-- Interpretation: Positive MoM% = growth vs prior month; NULL = first month.
-- ---------------------------------------------------------------------------
WITH monthly AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        ROUND(SUM(f.sales),  2) AS monthly_sales,
        ROUND(SUM(f.profit), 2) AS monthly_profit
    FROM fact_sales f
    JOIN dim_date   d  ON f.order_date_key = d.date_key
    GROUP BY d.year, d.month, d.month_name
)
SELECT
    year,
    month,
    month_name,
    monthly_sales,
    monthly_profit,
    LAG(monthly_sales)  OVER (ORDER BY year, month)      AS prev_month_sales,
    ROUND(
        (monthly_sales - LAG(monthly_sales) OVER (ORDER BY year, month))
        / NULLIF(LAG(monthly_sales) OVER (ORDER BY year, month), 0) * 100
    , 2)                                                  AS mom_sales_growth_pct
FROM monthly
ORDER BY year, month;


-- ---------------------------------------------------------------------------
-- Q3: Year-over-Year Growth (compare same month across years)
-- Business: Strips seasonality to show true business growth.
-- ---------------------------------------------------------------------------
WITH monthly AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        ROUND(SUM(f.sales),  2) AS monthly_sales,
        ROUND(SUM(f.profit), 2) AS monthly_profit
    FROM fact_sales f
    JOIN dim_date   d  ON f.order_date_key = d.date_key
    GROUP BY d.year, d.month, d.month_name
)
SELECT
    m.year,
    m.month,
    m.month_name,
    m.monthly_sales                                           AS current_sales,
    py.monthly_sales                                          AS prior_year_sales,
    ROUND(
        (m.monthly_sales - py.monthly_sales)
        / NULLIF(py.monthly_sales, 0) * 100
    , 2)                                                      AS yoy_sales_growth_pct
FROM monthly m
LEFT JOIN monthly py
    ON py.year  = m.year - 1
   AND py.month = m.month
ORDER BY m.year, m.month;


-- ---------------------------------------------------------------------------
-- Q4: Running Total of Sales by Year
-- Business: Cumulative sales helps track progress toward annual targets.
-- ---------------------------------------------------------------------------
WITH monthly AS (
    SELECT
        d.year,
        d.month,
        ROUND(SUM(f.sales), 2) AS monthly_sales
    FROM fact_sales f
    JOIN dim_date   d  ON f.order_date_key = d.date_key
    GROUP BY d.year, d.month
)
SELECT
    year,
    month,
    monthly_sales,
    SUM(monthly_sales) OVER (
        PARTITION BY year
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                         AS ytd_sales_running_total
FROM monthly
ORDER BY year, month;


-- ---------------------------------------------------------------------------
-- Q5: Best and Worst Months (by average profit margin)
-- Business: Identifies structurally weak or strong months across all years.
-- ---------------------------------------------------------------------------
WITH monthly AS (
    SELECT
        d.month,
        d.month_name,
        ROUND(SUM(f.sales),  2) AS total_sales,
        ROUND(SUM(f.profit), 2) AS total_profit
    FROM fact_sales f
    JOIN dim_date   d  ON f.order_date_key = d.date_key
    GROUP BY d.month, d.month_name
)
SELECT
    month,
    month_name,
    total_sales,
    total_profit,
    ROUND(total_profit / NULLIF(total_sales, 0) * 100, 2) AS avg_margin_pct,
    RANK() OVER (ORDER BY total_profit / NULLIF(total_sales, 0) DESC) AS margin_rank
FROM monthly
ORDER BY avg_margin_pct DESC;


-- ---------------------------------------------------------------------------
-- Q6: Quarterly Sales Summary (for Power BI bar/column charts)
-- ---------------------------------------------------------------------------
SELECT
    d.year,
    d.quarter,
    CONCAT('Q', d.quarter, '-', d.year)               AS quarter_label,
    COUNT(DISTINCT f.order_id)                         AS orders,
    ROUND(SUM(f.sales),  2)                            AS quarterly_sales,
    ROUND(SUM(f.profit), 2)                            AS quarterly_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales f
JOIN dim_date   d  ON f.order_date_key = d.date_key
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;
