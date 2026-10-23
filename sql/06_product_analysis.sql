-- =============================================================================
-- 06_product_analysis.sql
-- Purpose : Top/bottom product performance, category and sub-category analysis.
-- Target  : MySQL 8.0
-- Business: Drives product strategy — which SKUs to promote or discontinue.
-- =============================================================================

USE sales_performance;

-- ---------------------------------------------------------------------------
-- Q1: Top 10 Products by Total Sales
-- Expected: Dell XPS 15 Laptop leads with ≈$313,765
-- ---------------------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    p.sub_category,
    COUNT(DISTINCT f.order_id)                         AS orders,
    SUM(f.quantity)                                    AS total_qty,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    RANK() OVER (ORDER BY SUM(f.sales) DESC)           AS sales_rank
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.product_id, p.product_name, p.category, p.sub_category
ORDER BY total_sales DESC
LIMIT 10;


-- ---------------------------------------------------------------------------
-- Q2: Top 10 Products by Total Profit
-- Expected: Google Pixel 6 leads with ≈$19,122 profit
-- ---------------------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    p.sub_category,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    RANK() OVER (ORDER BY SUM(f.profit) DESC)          AS profit_rank
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.product_id, p.product_name, p.category, p.sub_category
ORDER BY total_profit DESC
LIMIT 10;


-- ---------------------------------------------------------------------------
-- Q3: Bottom 10 Products by Profit (Loss Leaders)
-- Expected: Flash Furniture Gaming Chair worst at ≈-$2,622
-- Business: These products are dragging overall profit; investigate discounts.
-- ---------------------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    p.sub_category,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(f.discount) * 100, 2)                    AS avg_discount_pct
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.product_id, p.product_name, p.category, p.sub_category
ORDER BY total_profit ASC
LIMIT 10;


-- ---------------------------------------------------------------------------
-- Q4: Category Summary
-- Expected:
--   Technology    : sales≈2,392,338  profit≈165,939  margin≈6.94%
--   Furniture     : sales≈742,303    profit≈16,183   margin≈2.18%
--   Office Supplies: sales≈198,746   profit≈42,868   margin≈21.57%
-- ---------------------------------------------------------------------------
SELECT
    p.category,
    COUNT(DISTINCT f.order_id)                         AS orders,
    SUM(f.quantity)                                    AS total_qty,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(SUM(f.sales) * 100.0 /
        NULLIF((SELECT SUM(sales) FROM fact_sales), 0), 2)   AS sales_share_pct,
    RANK() OVER (ORDER BY SUM(f.profit) DESC)          AS profit_rank
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.category
ORDER BY total_sales DESC;


-- ---------------------------------------------------------------------------
-- Q5: Sub-Category Profitability (all sub-categories)
-- Business: More granular view — Tables sub-category is loss-making (≈-$5,276)
-- ---------------------------------------------------------------------------
SELECT
    p.category,
    p.sub_category,
    COUNT(DISTINCT f.order_id)                         AS orders,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(f.discount) * 100, 2)                    AS avg_discount_pct,
    RANK() OVER (ORDER BY SUM(f.profit) DESC)          AS profit_rank
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.category, p.sub_category
ORDER BY total_profit DESC;


-- ---------------------------------------------------------------------------
-- Q6: High-Sales but Low-Profit Products
-- Business: Products where heavy discounting is destroying margin.
--   Criteria: sales > 100,000 AND margin < 5%
-- ---------------------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    ROUND(SUM(f.sales),  2)                            AS total_sales,
    ROUND(SUM(f.profit), 2)                            AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(f.discount) * 100, 2)                    AS avg_discount_pct
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.product_id, p.product_name, p.category
HAVING total_sales > 100000
   AND profit_margin_pct < 5
ORDER BY profit_margin_pct ASC;


-- ---------------------------------------------------------------------------
-- Q7: Product Quantity vs Revenue Efficiency
-- Business: Which products move high volume but generate low revenue?
-- ---------------------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    SUM(f.quantity)                                    AS total_units_sold,
    ROUND(SUM(f.sales), 2)                             AS total_sales,
    ROUND(SUM(f.sales) / NULLIF(SUM(f.quantity), 0), 2) AS revenue_per_unit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.quantity), 0), 2) AS profit_per_unit
FROM fact_sales  f
JOIN dim_product p USING(product_id)
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_units_sold DESC
LIMIT 15;
