# Data Validation Results

Generated: 2026-10-23 08:16:42

**Dataset:** `data/processed/sales_clean.csv`

| Metric       | Count |
|:-------------|------:|
| Total Checks | 36 |
| PASS         | 34 |
| FAIL         | 0 |
| WARN         | 2 |

## Detailed Results

| # | Check | Status | Detail |
|---|-------|--------|--------|
| 1 | A1: Raw record count | ✅ PASS | Rows: 7,500 (expected 7,500) |
| 2 | A2: Clean record count | ✅ PASS | Rows: 7,500 (expected 7,500) |
| 3 | A3: Duplicates removed | ✅ PASS | Removed: 0 |
| 4 | B: Null check [row_id] | ✅ PASS | 0 nulls |
| 5 | B: Null check [order_id] | ✅ PASS | 0 nulls |
| 6 | B: Null check [order_date] | ✅ PASS | 0 nulls |
| 7 | B: Null check [ship_date] | ✅ PASS | 0 nulls |
| 8 | B: Null check [customer_id] | ✅ PASS | 0 nulls |
| 9 | B: Null check [product_id] | ✅ PASS | 0 nulls |
| 10 | B: Null check [sales] | ✅ PASS | 0 nulls |
| 11 | B: Null check [quantity] | ✅ PASS | 0 nulls |
| 12 | B: Null check [profit] | ✅ PASS | 0 nulls |
| 13 | C1: sales dtype | ✅ PASS | float64 |
| 14 | C2: profit dtype | ✅ PASS | float64 |
| 15 | C3: quantity dtype | ✅ PASS | int64 |
| 16 | C4: discount dtype | ✅ PASS | float64 |
| 17 | D1: Sales > 0 | ✅ PASS | Violations: 0 |
| 18 | D2: Quantity >= 1 | ✅ PASS | Violations: 0 |
| 19 | D3: Discount in [0, 1] | ✅ PASS | Violations: 0 |
| 20 | D4: Loss-making rows (informational) | ⚠️ WARN | 811 rows with negative profit (expected for discounted items) |
| 21 | E1: Ship date >= Order date | ✅ PASS | Violations: 0 |
| 22 | E2: Dates in 2021-2023 | ✅ PASS | 2021-01-01 → 2023-12-31 |
| 23 | F1: row_id uniqueness | ✅ PASS | Duplicates: 0 |
| 24 | F2: Unique products | ✅ PASS | 80 (expected 80) |
| 25 | F3: Unique customers | ✅ PASS | 795 (expected 795) |
| 26 | G: Total Sales | ✅ PASS | Actual: 3,333,386.08 | Expected: 3,333,386.08 |
| 27 | G: Total Profit | ✅ PASS | Actual: 224,989.95 | Expected: 224,989.95 |
| 28 | G: Total Quantity | ✅ PASS | Actual: 20,968.00 | Expected: 20,968.00 |
| 29 | G: Total Orders | ✅ PASS | Actual: 4,360.00 | Expected: 4,360.00 |
| 30 | G: Avg Order Value | ✅ PASS | Actual: 764.54 | Expected: 764.54 |
| 31 | G: Profit Margin % | ✅ PASS | Actual: 6.75 | Expected: 6.75 |
| 32 | H1: Correct aggregate margin | ✅ PASS | 6.75% (SUM(profit)/SUM(sales)) — CORRECT method |
| 33 | H2: Row-average margin (misleading) | ⚠️ WARN | 15.85% (AVG of row margins) — DO NOT USE for KPIs |
| 34 | I1: Regions present | ✅ PASS | ['Central', 'East', 'South', 'West'] |
| 35 | I2: Categories present | ✅ PASS | ['Furniture', 'Office Supplies', 'Technology'] |
| 36 | I3: Segments present | ✅ PASS | ['Consumer', 'Corporate', 'Home Office'] |

## Key Baseline Metrics (from validated dataset)

| Metric | Value |
|:-------|------:|
| Total Records | 7,500 |
| Total Sales | $3,333,386.08 |
| Total Profit | $224,989.95 |
| Profit Margin | 6.75% |
| Total Quantity | 20,968 |
| Total Orders | 4,360 |
| Unique Customers | 795 |
| Unique Products | 80 |
| Date Range | 2021-01-01 to 2023-12-31 |
| Loss-Making Rows | 811 |

## Notes

> [!IMPORTANT]
> **Profit Margin Calculation:** Always use `SUM(profit) / SUM(sales)`
> (aggregate method), NOT `AVG(profit/sales)` (row-average method).
> The row-average method produces misleading results when order sizes vary.

> [!NOTE]
> **MySQL validation:** SQL query results cannot be auto-tested because
> MySQL is not installed in this environment. After setting up MySQL,
> run 04_kpi_analysis.sql Q1 and compare against the baseline above.

> [!NOTE]
> **Power BI validation:** Power BI Desktop must be installed and the
> MySQL connector configured to test DAX measures against SQL results.