# DAX Measures Reference
## Sales Performance Dashboard — Power BI

> All measures below are written for a star-schema Power BI data model with:
> - **fact_sales** fact table
> - **dim_customer**, **dim_product**, **dim_date** dimension tables
> - A proper **Date table** (Calendar) marked as the date table, related to fact_sales[order_date_key]

---

## 1. Base KPI Measures

```dax
-- ════════════════════════════════════════════════════
-- MEASURE: Total Sales
-- Desc   : Sum of all sales revenue across all rows.
-- Format : Currency ($)
-- Usage  : KPI Cards, trend charts, all pages.
-- ════════════════════════════════════════════════════
Total Sales =
    SUM( fact_sales[sales] )


-- ════════════════════════════════════════════════════
-- MEASURE: Total Profit
-- Desc   : Sum of all profit (can be negative for loss rows).
-- Format : Currency ($)
-- ════════════════════════════════════════════════════
Total Profit =
    SUM( fact_sales[profit] )


-- ════════════════════════════════════════════════════
-- MEASURE: Total Quantity
-- Desc   : Total units sold across all line items.
-- Format : Whole number (#,##0)
-- ════════════════════════════════════════════════════
Total Quantity =
    SUM( fact_sales[quantity] )


-- ════════════════════════════════════════════════════
-- MEASURE: Total Orders
-- Desc   : Count of distinct order IDs (not line items).
-- Format : Whole number (#,##0)
-- ════════════════════════════════════════════════════
Total Orders =
    DISTINCTCOUNT( fact_sales[order_id] )


-- ════════════════════════════════════════════════════
-- MEASURE: Total Customers
-- Desc   : Count of distinct customers who placed orders.
-- Format : Whole number (#,##0)
-- ════════════════════════════════════════════════════
Total Customers =
    DISTINCTCOUNT( fact_sales[customer_id] )


-- ════════════════════════════════════════════════════
-- MEASURE: Average Order Value
-- Desc   : Average revenue per distinct order (not per line item).
--          DIVIDE used to handle zero orders gracefully.
-- Format : Currency ($)
-- ════════════════════════════════════════════════════
Average Order Value =
    DIVIDE(
        [Total Sales],
        [Total Orders],
        0
    )


-- ════════════════════════════════════════════════════
-- MEASURE: Profit Margin %
-- Desc   : Aggregate-level margin = Total Profit / Total Sales.
--          IMPORTANT: This is NOT the average of row-level margins,
--          which would produce a misleading result (~15.85% vs 6.75%).
-- Format : Percentage (0.00%)
-- Expected: ~6.75% overall
-- ════════════════════════════════════════════════════
Profit Margin % =
    DIVIDE(
        [Total Profit],
        [Total Sales],
        0
    )
```

---

## 2. Time Intelligence Measures

> **Prerequisite:** The Calendar table must be marked as a Date Table in Power BI
> (Table Tools → Mark as date table → date column = `Calendar[Date]`).

```dax
-- ════════════════════════════════════════════════════
-- MEASURE: Previous Month Sales
-- Desc   : Sales in the calendar month immediately preceding
--          the current filter context month.
-- Format : Currency ($)
-- ════════════════════════════════════════════════════
Previous Month Sales =
    CALCULATE(
        [Total Sales],
        DATEADD( 'Calendar'[Date], -1, MONTH )
    )


-- ════════════════════════════════════════════════════
-- MEASURE: MoM Growth %
-- Desc   : Month-over-Month percentage change in sales.
--          Returns BLANK() when there is no prior month data
--          (e.g. January 2021) to avoid divide-by-zero errors.
-- Format : Percentage (0.00%)
-- ════════════════════════════════════════════════════
MoM Growth % =
    VAR PrevSales = [Previous Month Sales]
    RETURN
        IF(
            ISBLANK( PrevSales ) || PrevSales = 0,
            BLANK(),
            DIVIDE(
                [Total Sales] - PrevSales,
                PrevSales,
                BLANK()
            )
        )


-- ════════════════════════════════════════════════════
-- MEASURE: Previous Year Sales
-- Desc   : Sales in the same period one year ago.
-- Format : Currency ($)
-- ════════════════════════════════════════════════════
Previous Year Sales =
    CALCULATE(
        [Total Sales],
        SAMEPERIODLASTYEAR( 'Calendar'[Date] )
    )


-- ════════════════════════════════════════════════════
-- MEASURE: YoY Growth %
-- Desc   : Year-over-Year percentage change in sales.
--          Returns BLANK() for 2021 (no prior year available).
-- Format : Percentage (0.00%)
-- ════════════════════════════════════════════════════
YoY Growth % =
    VAR PrevYearSales = [Previous Year Sales]
    RETURN
        IF(
            ISBLANK( PrevYearSales ) || PrevYearSales = 0,
            BLANK(),
            DIVIDE(
                [Total Sales] - PrevYearSales,
                PrevYearSales,
                BLANK()
            )
        )


-- ════════════════════════════════════════════════════
-- MEASURE: YTD Sales
-- Desc   : Year-to-date cumulative sales within the selected year.
-- Format : Currency ($)
-- ════════════════════════════════════════════════════
YTD Sales =
    TOTALYTD(
        [Total Sales],
        'Calendar'[Date]
    )


-- ════════════════════════════════════════════════════
-- MEASURE: Running Total Sales
-- Desc   : Cumulative sales from the first date in context
--          to the current date — useful for trend area charts.
-- Format : Currency ($)
-- ════════════════════════════════════════════════════
Running Total Sales =
    CALCULATE(
        [Total Sales],
        FILTER(
            ALL( 'Calendar'[Date] ),
            'Calendar'[Date] <= MAX( 'Calendar'[Date] )
        )
    )
```

---

## 3. Contribution & Ranking Measures

```dax
-- ════════════════════════════════════════════════════
-- MEASURE: Sales Contribution % by Region
-- Desc   : What percentage of total sales does the current
--          region (or other dimension in context) represent?
--          ALL() removes the region filter to get the grand total.
-- Format : Percentage (0.00%)
-- ════════════════════════════════════════════════════
Sales Contribution % =
    DIVIDE(
        [Total Sales],
        CALCULATE( [Total Sales], ALL( fact_sales[region] ) ),
        0
    )


-- ════════════════════════════════════════════════════
-- MEASURE: Sales Rank by Product
-- Desc   : Ranks each product by descending total sales.
--          Ties receive the same rank (RANKX dense mode).
-- Format : Whole number
-- ════════════════════════════════════════════════════
Sales Rank by Product =
    RANKX(
        ALL( dim_product[product_name] ),
        [Total Sales],
        ,
        DESC,
        Dense
    )


-- ════════════════════════════════════════════════════
-- MEASURE: Profit Contribution % (Category)
-- Desc   : Share of total profit for each category.
-- Format : Percentage (0.00%)
-- ════════════════════════════════════════════════════
Profit Contribution % =
    DIVIDE(
        [Total Profit],
        CALCULATE( [Total Profit], ALL( dim_product[category] ) ),
        0
    )
```

---

## 4. Sales Target Measures (Illustrative)

> **Disclosure:** The targets below are ILLUSTRATIVE ONLY. They are not derived
> from real business data. Replace with actual targets from a targets table
> if available.

```dax
-- ════════════════════════════════════════════════════
-- Illustrative Sales Target (10% growth over prior year)
-- ════════════════════════════════════════════════════
Sales Target (Illustrative) =
    [Previous Year Sales] * 1.10


-- ════════════════════════════════════════════════════
-- MEASURE: Sales Target Attainment %
-- Desc   : Actual sales vs illustrative target.
-- Format : Percentage (0.00%)
-- ════════════════════════════════════════════════════
Sales Target Attainment % =
    DIVIDE(
        [Total Sales],
        [Sales Target (Illustrative)],
        BLANK()
    )
```

---

## 5. Calendar Table DAX

> Create this calculated table in Power BI: **Modeling → New Table**

```dax
-- ════════════════════════════════════════════════════
-- CALCULATED TABLE: Calendar
-- Desc   : Full date table covering dataset range.
--          After creating, go to:
--          Table Tools → Mark as date table → Date column = [Date]
-- ════════════════════════════════════════════════════
Calendar =
ADDCOLUMNS(
    CALENDAR( DATE(2021,1,1), DATE(2023,12,31) ),
    "Year",        YEAR([Date]),
    "Quarter",     QUARTER([Date]),
    "QuarterLabel", "Q" & QUARTER([Date]) & "-" & YEAR([Date]),
    "Month",       MONTH([Date]),
    "MonthName",   FORMAT([Date], "MMM"),
    "MonthSort",   YEAR([Date]) * 100 + MONTH([Date]),
    "Week",        WEEKNUM([Date], 2),
    "DayOfWeek",   WEEKDAY([Date], 2),
    "DayName",     FORMAT([Date], "ddd"),
    "IsWeekend",   IF( WEEKDAY([Date], 2) >= 6, TRUE, FALSE ),
    "DateKey",     YEAR([Date]) * 10000 + MONTH([Date]) * 100 + DAY([Date])
)
```

---

## 6. Formatting Guidelines

| Measure | Power BI Format String | Display Example |
|:--------|:----------------------|:----------------|
| Total Sales | `"$"#,##0.00` | $3,333,386.08 |
| Total Profit | `"$"#,##0.00` | $224,989.95 |
| Total Orders | `#,##0` | 4,360 |
| Profit Margin % | `0.00%` | 6.75% |
| MoM Growth % | `+0.00%;-0.00%;"—"` | +5.23% / -3.10% |
| YoY Growth % | `+0.00%;-0.00%;"—"` | +8.91% |
| Avg Order Value | `"$"#,##0.00` | $764.54 |
| Sales Rank | `#,##0` | 1 |

---

## 7. Common Mistakes to Avoid

| ❌ Wrong | ✅ Correct | Why |
|:---------|:-----------|:----|
| `AVERAGE(fact_sales[profit] / fact_sales[sales])` | `DIVIDE(SUM(profit), SUM(sales))` | Row-average margin is misleading |
| `COUNT(fact_sales[order_id])` | `DISTINCTCOUNT(fact_sales[order_id])` | Count includes duplicate line items |
| Hardcoding sales targets | Use a documented targets table | Transparency and reproducibility |
| Using `DIVIDE(x, y)` with `0` as alternate | Use `BLANK()` for percentages | Avoids misleading 0% growth |
