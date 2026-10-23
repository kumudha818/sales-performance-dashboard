-- =============================================================================
-- 08_category_profitability.sql
-- Purpose : Deep-dive into category, sub-category profit margin analysis,
--           and the relationship between discounts and profitability.
-- Target  : MySQL 8.0
-- Business: Directly supports pricing and discount-policy decisions.
-- =============================================================================

USE sales_performance;

-- ---------------------------------------------------------------------------
-- Q1: Profit Margin by Category and Sub-Category
-- Note: Profit margin = SUM(profit) / SUM(sales), NOT AVG of row-level margins.
--       Using AVG row-level margin would be misleading due to varying order sizes.
-- Business: Tables sub-category is loss-making (≈-2.08%); requires attention.
-- ---------------------------------------------------------------------------
SELECT
    p.category,
    p.sub_category,
    COUNT(DISTINCT f.order_id)                          AS orders,
    SUM(f.quantity)                                     AS total_units,
    ROUND(SUM(f.sales),  2)                             AS total_sales,
    ROUND(SUM(f.profit), 2)                             AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    CASE
        WHEN SUM(f.profit) / NULLIF(SUM(f.sales), 0) >= 0.15 THEN 'High'
        WHEN SUM(f.profit) / NULLIF(SUM(f.sales), 0) >= 0.05 THEN 'Medium'
        WHEN SUM(f.profit) / NULLIF(SUM(f.sales), 0) >= 0     THEN 'Low'
        ELSE 'Loss-Making'
    END AS profitability_band
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.category, p.sub_category
ORDER BY p.category, profit_margin_pct DESC;


-- ---------------------------------------------------------------------------
-- Q2: Discount Buckets vs Average Profit Margin
-- Business: Quantifies how each discount level erodes profit.
--   CORRELATION ≠ CAUSATION: Some high-discount orders may still be profitable
--   (e.g., high-margin Office Supplies). This shows aggregate tendencies.
-- ---------------------------------------------------------------------------
SELECT
    CASE
        WHEN discount = 0          THEN '0% (No Discount)'
        WHEN discount <= 0.10      THEN '1-10%'
        WHEN discount <= 0.20      THEN '11-20%'
        WHEN discount <= 0.30      THEN '21-30%'
        WHEN discount <= 0.40      THEN '31-40%'
        ELSE '41%+'
    END AS discount_bucket,
    COUNT(*)                                             AS order_lines,
    ROUND(SUM(f.sales),  2)                              AS total_sales,
    ROUND(SUM(f.profit), 2)                              AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(f.discount) * 100, 2)                      AS actual_avg_discount_pct,
    SUM(CASE WHEN f.profit < 0 THEN 1 ELSE 0 END)        AS loss_making_lines
FROM fact_sales f
GROUP BY discount_bucket
ORDER BY actual_avg_discount_pct;


-- ---------------------------------------------------------------------------
-- Q3: Discount vs Profit — By Category and Discount Bucket
-- Business: Furniture items have very thin margins; even 10% discount
--           can push them into loss territory.
-- ---------------------------------------------------------------------------
SELECT
    p.category,
    CASE
        WHEN f.discount = 0      THEN '0%'
        WHEN f.discount <= 0.10  THEN '≤10%'
        WHEN f.discount <= 0.20  THEN '≤20%'
        ELSE '>20%'
    END AS discount_bucket,
    COUNT(*)                                             AS order_lines,
    ROUND(SUM(f.sales),  2)                              AS total_sales,
    ROUND(SUM(f.profit), 2)                              AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.category, discount_bucket
ORDER BY p.category, f.discount;


-- ---------------------------------------------------------------------------
-- Q4: Identify Loss-Making Orders
-- Business: Each loss-making transaction is a real cash outflow.
--   Filtering to discount > 0.20 to focus on heavily discounted orders.
-- ---------------------------------------------------------------------------
SELECT
    f.order_id,
    f.order_date_key,
    c.customer_name,
    c.segment,
    p.product_name,
    p.category,
    f.state,
    f.region,
    ROUND(f.sales,    2) AS sales,
    ROUND(f.profit,   2) AS profit,
    ROUND(f.discount * 100, 2) AS discount_pct,
    ROUND(f.profit / NULLIF(f.sales, 0) * 100, 2) AS row_margin_pct
FROM fact_sales   f
JOIN dim_customer c USING(customer_id)
JOIN dim_product  p USING(product_id)
WHERE f.profit < 0
  AND f.discount > 0.20
ORDER BY f.profit ASC
LIMIT 30;


-- ---------------------------------------------------------------------------
-- Q5: Sub-Category Contribution to Category Profit
-- Business: Within each category, which sub-categories drive or drain profit?
-- ---------------------------------------------------------------------------
SELECT
    p.category,
    p.sub_category,
    ROUND(SUM(f.profit), 2)  AS sub_profit,
    ROUND(
        SUM(f.profit) * 100.0
        / NULLIF(
            SUM(SUM(f.profit)) OVER (PARTITION BY p.category)
        , 0)
    , 2)                     AS sub_profit_share_of_category_pct
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.category, p.sub_category
ORDER BY p.category, sub_profit DESC;


-- ---------------------------------------------------------------------------
-- Q6: Segment × Category Profitability
-- Business: Does Corporate segment generate better margins than Consumer?
-- ---------------------------------------------------------------------------
SELECT
    c.segment,
    p.category,
    ROUND(SUM(f.sales),  2)                              AS total_sales,
    ROUND(SUM(f.profit), 2)                              AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales   f
JOIN dim_customer c USING(customer_id)
JOIN dim_product  p USING(product_id)
GROUP BY c.segment, p.category
ORDER BY c.segment, total_profit DESC;
