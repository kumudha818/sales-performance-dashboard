-- =============================================================================
-- 09_advanced_analysis.sql
-- Purpose : Advanced SQL techniques — CTEs, multi-level window functions,
--           conditional aggregation, customer behaviour analysis.
-- Target  : MySQL 8.0
-- Business: Interview-ready showcase of advanced SQL skills.
-- =============================================================================

USE sales_performance;

-- ---------------------------------------------------------------------------
-- Q1: Customer RFM Segmentation (Recency, Frequency, Monetary)
-- Business: Identifies high-value customers for loyalty programmes.
-- Technique: CTEs, DATEDIFF, NTILE window function.
-- ---------------------------------------------------------------------------
WITH customer_rfm AS (
    SELECT
        f.customer_id,
        c.customer_name,
        c.segment,
        DATEDIFF(
            (SELECT MAX(full_date) FROM dim_date WHERE date_key <= 20231231),
            MAX(d.full_date)
        )                             AS recency_days,
        COUNT(DISTINCT f.order_id)    AS frequency,
        ROUND(SUM(f.sales), 2)        AS monetary
    FROM fact_sales   f
    JOIN dim_customer c USING(customer_id)
    JOIN dim_date     d ON f.order_date_key = d.date_key
    GROUP BY f.customer_id, c.customer_name, c.segment
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,  -- lower days = better
        NTILE(5) OVER (ORDER BY frequency DESC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
    FROM customer_rfm
)
SELECT
    customer_id,
    customer_name,
    segment,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score)                 AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 12  THEN 'Champions'
        WHEN (r_score + f_score + m_score) >= 9   THEN 'Loyal Customers'
        WHEN (r_score + f_score + m_score) >= 6   THEN 'At Risk'
        ELSE 'Lost'
    END AS customer_segment_label
FROM rfm_scores
ORDER BY rfm_total DESC
LIMIT 20;


-- ---------------------------------------------------------------------------
-- Q2: Sales Performance vs Prior Period using Conditional Aggregation
-- Business: Compact pivot — shows 2022 vs 2023 comparison in a single row.
-- Technique: SUM(CASE WHEN ...) conditional aggregation.
-- ---------------------------------------------------------------------------
SELECT
    f.region,
    ROUND(SUM(CASE WHEN d.year = 2021 THEN f.sales ELSE 0 END), 2) AS sales_2021,
    ROUND(SUM(CASE WHEN d.year = 2022 THEN f.sales ELSE 0 END), 2) AS sales_2022,
    ROUND(SUM(CASE WHEN d.year = 2023 THEN f.sales ELSE 0 END), 2) AS sales_2023,
    ROUND(
        (SUM(CASE WHEN d.year = 2023 THEN f.sales ELSE 0 END) -
         SUM(CASE WHEN d.year = 2022 THEN f.sales ELSE 0 END))
        / NULLIF(SUM(CASE WHEN d.year = 2022 THEN f.sales ELSE 0 END), 0) * 100
    , 2) AS yoy_growth_2022_2023_pct
FROM fact_sales f
JOIN dim_date   d ON f.order_date_key = d.date_key
GROUP BY f.region
ORDER BY sales_2023 DESC;


-- ---------------------------------------------------------------------------
-- Q3: Running Profit Total Across All Time
-- Business: Shows cumulative profitability trend — is the business
--           consistently profitable month over month?
-- Technique: SUM() OVER (ORDER BY ...) running window.
-- ---------------------------------------------------------------------------
WITH monthly_profit AS (
    SELECT
        d.year,
        d.month,
        CONCAT(d.year, '-', LPAD(d.month, 2, '0')) AS year_month,
        ROUND(SUM(f.sales),  2)                      AS monthly_sales,
        ROUND(SUM(f.profit), 2)                      AS monthly_profit
    FROM fact_sales f
    JOIN dim_date   d ON f.order_date_key = d.date_key
    GROUP BY d.year, d.month
)
SELECT
    year_month,
    monthly_sales,
    monthly_profit,
    SUM(monthly_profit) OVER (ORDER BY year, month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    SUM(monthly_sales)  OVER (ORDER BY year, month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM monthly_profit
ORDER BY year, month;


-- ---------------------------------------------------------------------------
-- Q4: Product Sales Rank within Each Category (DENSE_RANK + PARTITION BY)
-- Business: Shows which product is #1 in each category for marketing focus.
-- ---------------------------------------------------------------------------
WITH product_sales AS (
    SELECT
        p.category,
        p.sub_category,
        p.product_name,
        ROUND(SUM(f.sales),  2) AS total_sales,
        ROUND(SUM(f.profit), 2) AS total_profit
    FROM fact_sales  f
    JOIN dim_product p USING(product_id)
    GROUP BY p.category, p.sub_category, p.product_name
)
SELECT
    category,
    sub_category,
    product_name,
    total_sales,
    total_profit,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) AS rank_in_category,
    DENSE_RANK() OVER (ORDER BY total_sales DESC)                       AS overall_sales_rank
FROM product_sales
ORDER BY category, rank_in_category
LIMIT 30;


-- ---------------------------------------------------------------------------
-- Q5: Orders with Multiple Line Items (Multi-product orders)
-- Business: Multi-item orders indicate customers who buy diverse products.
-- Technique: HAVING, subquery.
-- ---------------------------------------------------------------------------
SELECT
    f.order_id,
    d.full_date                                      AS order_date,
    c.customer_name,
    c.segment,
    f.region,
    COUNT(f.row_id)                                  AS line_items,
    COUNT(DISTINCT p.category)                       AS categories_purchased,
    ROUND(SUM(f.sales),  2)                          AS order_sales,
    ROUND(SUM(f.profit), 2)                          AS order_profit
FROM fact_sales   f
JOIN dim_date     d ON f.order_date_key = d.date_key
JOIN dim_customer c USING(customer_id)
JOIN dim_product  p USING(product_id)
GROUP BY f.order_id, d.full_date, c.customer_name, c.segment, f.region
HAVING line_items >= 3
ORDER BY order_sales DESC
LIMIT 20;


-- ---------------------------------------------------------------------------
-- Q6: Identifying Outlier Orders (sales > 2 standard deviations above mean)
-- Business: Large orders can skew metrics; worth flagging for review.
-- Technique: Subquery with AVG and STDDEV.
-- ---------------------------------------------------------------------------
SELECT
    f.order_id,
    p.product_name,
    p.category,
    f.state,
    f.region,
    ROUND(f.sales,  2)                                AS order_line_sales,
    ROUND(f.profit, 2)                                AS order_line_profit,
    ROUND(f.discount * 100, 2)                        AS discount_pct
FROM fact_sales  f
JOIN dim_product p USING(product_id)
WHERE f.sales > (
    SELECT AVG(sales) + 2 * STDDEV(sales) FROM fact_sales
)
ORDER BY f.sales DESC
LIMIT 20;


-- ---------------------------------------------------------------------------
-- Q7: Profitability Quartile Analysis
-- Business: Classifies every product into performance quartiles.
-- Technique: NTILE window function.
-- ---------------------------------------------------------------------------
WITH product_metrics AS (
    SELECT
        p.product_name,
        p.category,
        ROUND(SUM(f.sales),  2)   AS total_sales,
        ROUND(SUM(f.profit), 2)   AS total_profit
    FROM fact_sales  f
    JOIN dim_product p USING(product_id)
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT
    product_name,
    category,
    total_sales,
    total_profit,
    NTILE(4) OVER (ORDER BY total_profit DESC) AS profit_quartile,
    CASE NTILE(4) OVER (ORDER BY total_profit DESC)
        WHEN 1 THEN 'Top Performer'
        WHEN 2 THEN 'Above Average'
        WHEN 3 THEN 'Below Average'
        WHEN 4 THEN 'Poor Performer'
    END AS performance_label
FROM product_metrics
ORDER BY total_profit DESC;
