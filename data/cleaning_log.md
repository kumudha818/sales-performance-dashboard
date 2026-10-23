# Cleaning Log
## Sales Performance Dashboard — Data Transformation Decisions

**Dataset:** `data/raw/sales_raw.csv` → `data/processed/sales_clean.csv`
**Date:** 2026-10-20
**Author:** generate_dataset.py + validate_data.py (automated pipeline)

---

## Transformation 1: Duplicate Removal
- **Tool:** `pandas.DataFrame.drop_duplicates(subset=["row_id"])`
- **Applied:** Yes
- **Result:** 0 rows removed (generator ensures unique row_ids)
- **Decision:** Kept as a step for pipeline completeness — real data may have duplicates

## Transformation 2: Date Parsing
- **Tool:** `pandas.to_datetime(df["order_date"])`
- **Applied:** Yes
- **Result:** Converted string "YYYY-MM-DD" to datetime64 in-memory
- **In MySQL:** Parsed via `STR_TO_DATE(order_date, '%Y-%m-%d')` in import script

## Transformation 3: Numeric Type Enforcement
- **Applied:** Yes
- **sales, profit, discount** → float64 / DECIMAL(12,2)
- **quantity** → int64 / SMALLINT
- **Reason:** Ensures accurate arithmetic aggregations

## Transformation 4: Retain Loss-Making Rows
- **Decision:** Retained all 811 rows with negative profit
- **Reason:** Loss-making rows are analytically essential — they show
  the discount-margin relationship. Removing them would bias the analysis.

## Transformation 5: No Outlier Removal
- **Decision:** High-value orders (Dell laptops, $2,000+ single orders) retained
- **Reason:** These are legitimate high-ticket items, not data errors
- **Alternative considered:** Winsorising at 99th percentile — rejected because
  it would distort the product-level sales rankings

## Transformation 6: No Imputation
- **Decision:** No imputation applied
- **Reason:** Zero nulls exist in the generated dataset
- **Real-world note:** If nulls existed in customer_name, the safest approach
  would be "Unknown Customer" rather than dropping rows

---

## Column Definitions

| Column | Type | Notes |
|:-------|:-----|:------|
| row_id | INT | Sequential line-item identifier |
| order_id | VARCHAR | Format: ORD-YYYY-NNNNN |
| order_date | DATE | Date order was placed |
| ship_date | DATE | Always ≥ order_date |
| ship_mode | VARCHAR | Second Class / Standard Class / First Class / Same Day |
| customer_id | VARCHAR | Format: CUST-NNNN |
| customer_name | VARCHAR | First Last format |
| segment | VARCHAR | Consumer / Corporate / Home Office |
| country | VARCHAR | Always "United States" |
| state | VARCHAR | US state full name |
| city | VARCHAR | City within state |
| region | VARCHAR | Central / East / South / West |
| product_id | VARCHAR | Format: PROD-NNNN |
| category | VARCHAR | Furniture / Office Supplies / Technology |
| sub_category | VARCHAR | 16 values |
| product_name | VARCHAR | Real product-inspired names |
| sales | DECIMAL | Revenue after discount applied (>0) |
| quantity | INT | Units sold (≥1) |
| discount | DECIMAL | Fraction [0, 1] — e.g., 0.20 = 20% discount |
| profit | DECIMAL | Can be negative for heavily discounted items |
