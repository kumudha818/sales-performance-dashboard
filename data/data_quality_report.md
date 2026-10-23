# Data Quality Report
## Sales Performance Dashboard

**Generated:** 2026-10-20
**Dataset:** `data/raw/sales_raw.csv` → `data/processed/sales_clean.csv`

---

## Data Source

| Field | Value |
|:------|:------|
| Source Type | Synthetic (Python-generated) |
| Disclosure | NOT real business data |
| Random Seed | 42 (fully reproducible) |
| Generator Script | `scripts/generate_dataset.py` |
| Date Generated | 2026-10-20 |

---

## Cleaning Log

### Step 1: Remove Exact Duplicates
- **Method:** `df.drop_duplicates(subset=["row_id"])`
- **Rows removed:** 0 (dataset was generated without duplicates)
- **Reason:** row_id is assigned sequentially during generation

### Step 2: Null Value Check
- **Method:** `df[critical_cols].isnull().sum()`
- **Critical columns checked:** row_id, order_id, order_date, ship_date,
  customer_id, product_id, sales, quantity, profit
- **Nulls found:** 0 in all critical columns
- **Action:** None required

### Step 3: Data Type Enforcement
- **sales, profit, discount** → `float64` (DECIMAL in MySQL)
- **quantity** → `int64` (SMALLINT in MySQL)
- **order_date, ship_date** → `datetime64[ns]` (DATE in MySQL)

### Step 4: Range Validation
| Check | Rule | Result |
|:------|:-----|:-------|
| Sales | > 0 | PASS (0 violations) |
| Quantity | ≥ 1 | PASS (0 violations) |
| Discount | [0, 1] | PASS (0 violations) |
| Ship date | ≥ Order date | PASS (0 violations) |
| Date range | 2021–2023 | PASS |

### Step 5: Loss-Making Rows (Informational — Not Removed)
- **Count:** 811 rows (10.8% of total)
- **Total loss value:** $(profit < 0).sum() ≈ -$34,232
- **Decision:** Retained — loss-making rows are analytically valuable
  (they demonstrate the impact of high discounts on profitability)
- **Breakdown:**
  - Furniture: 550 rows
  - Technology: 208 rows
  - Office Supplies: 53 rows

---

## Transformations NOT Applied

| Transformation | Reason Not Applied |
|:---------------|:-------------------|
| Outlier removal | High-value laptop orders are legitimate; flagged in SQL outlier query |
| Imputation | No missing values requiring imputation |
| Currency conversion | Single currency (USD); no conversion needed |
| String normalisation | Product and customer names generated consistently |

---

## Excel Workflow (Manual Steps)

After opening `data/excel/Sales_Performance_Dashboard.xlsx`:

1. **Verify data loaded correctly** (Raw_Data sheet, 7,500 rows + 1 header)
2. **Convert to Table:** Select A1:T7501 → Insert → Table → "My table has headers"
   Name the table: `tblSales`
3. **Apply date format:** Select order_date column → Format Cells → Date → YYYY-MM-DD
4. **Apply currency format:** Select sales, profit columns → Format Cells → Currency
5. **Apply percentage format:** Select discount column → Format Cells → Percentage (2 decimals)
6. **Sort:** By order_date ascending to verify date range
7. **Filter test:** Filter Category = "Furniture"; verify only Furniture rows appear
8. **PivotTable:** Insert → PivotTable → New Sheet
   - Rows: Category, Sub-Category
   - Values: Sum of Sales, Sum of Profit
   - Verify totals match: Sales ≈ $3,333,386 | Profit ≈ $224,990
9. **Conditional formatting (optional):** Highlight profit < 0 rows red

---

## Summary Statistics

| Metric | Value |
|:-------|------:|
| Raw records | 7,500 |
| Clean records | 7,500 |
| Duplicates removed | 0 |
| Null values fixed | 0 |
| Type corrections | 3 (date parsing) |
| Loss-making rows | 811 |
| Date range | 2021-01-01 to 2023-12-31 |
| Unique customers | 795 |
| Unique products | 80 |
| Unique states | 40 |
| Categories | 3 |
| Sub-categories | 16 |
