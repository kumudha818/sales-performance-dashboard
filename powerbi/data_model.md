# Power BI Data Model Documentation
## Sales Performance Dashboard

---

## Star Schema Design

```
                    dim_date
                  ┌──────────────┐
                  │ date_key (PK)│
                  │ full_date    │
                  │ year         │
                  │ quarter      │
                  │ month        │
                  │ month_name   │
                  │ week         │
                  │ day_of_week  │
                  │ is_weekend   │
                  └──────┬───────┘
                         │ 1:*  (order_date_key)
                         │
dim_customer              │              dim_product
┌──────────────┐    ┌─────▼──────────┐   ┌──────────────────┐
│customer_id(PK)│◄──│  fact_sales    │──►│ product_id (PK)  │
│customer_name │    │ ─────────────  │   │ category         │
│segment       │    │ row_id (PK)    │   │ sub_category     │
└──────────────┘    │ order_id       │   │ product_name     │
                    │ order_date_key │   └──────────────────┘
                    │ ship_date_key  │
                    │ ship_mode      │
                    │ customer_id    │
                    │ country        │
                    │ state          │
                    │ city           │
                    │ region         │
                    │ product_id     │
                    │ sales          │
                    │ quantity       │
                    │ discount       │
                    │ profit         │
                    └────────────────┘
```

---

## Table Relationships

| From Table | From Column | To Table | To Column | Cardinality | Filter Direction | Active |
|:-----------|:------------|:---------|:----------|:------------|:-----------------|:-------|
| fact_sales | customer_id | dim_customer | customer_id | Many-to-One (*:1) | Single (dim→fact) | Yes |
| fact_sales | product_id | dim_product | product_id | Many-to-One (*:1) | Single (dim→fact) | Yes |
| fact_sales | order_date_key | dim_date | date_key | Many-to-One (*:1) | Single (dim→fact) | Yes |
| fact_sales | ship_date_key | dim_date | date_key | Many-to-One (*:1) | Single (dim→fact) | No (inactive) |

> **Note on ship_date:** The relationship on `ship_date_key` is inactive because Power BI
> only allows one active relationship between two tables. Use `USERELATIONSHIP()` in DAX
> to activate it when needed (e.g., for shipping delay analysis).

---

## Power BI Connection Setup

### Option 1: MySQL Connector (Recommended for this project)

1. **Download MySQL Connector/NET** from:
   `https://dev.mysql.com/downloads/connector/net/`
   - Select **Connector/NET 8.x** for MySQL 8.0
   - Install and restart Power BI Desktop

2. **In Power BI Desktop:**
   - **Home → Get Data → More → Database → MySQL Database**
   - Server: `localhost` (or `127.0.0.1`)
   - Database: `sales_performance`
   - Enter credentials (do NOT store in file — use the Power BI credential manager)

3. **Select tables/views to import:**
   - `fact_sales`
   - `dim_customer`
   - `dim_product`
   - All views: `v_monthly_sales`, `v_regional_performance`, `v_state_performance`,
     `v_product_performance`, `v_category_summary`, `v_discount_impact`

### Option 2: CSV Import (If MySQL is not available)

1. **Home → Get Data → Text/CSV**
2. Import `data/processed/sales_clean.csv`
3. Build dimensions in Power Query using **Remove Duplicates** on key columns

---

## Import Mode vs DirectQuery

| Feature | Import Mode ✅ (Recommended) | DirectQuery |
|:--------|:---------------------------|:------------|
| Performance | Fast (data cached in memory) | Slower (queries DB on each interaction) |
| Data freshness | Snapshot at refresh time | Always live |
| DAX support | Full support | Limited |
| File size | Larger .pbix file | Smaller .pbix |
| Best for | Portfolio / small datasets | Production BI on large data |

**Recommendation:** Use **Import Mode** for this portfolio project. The dataset is
only 7,500 rows (~2 MB) and does not require live updates.

---

## Power Query Transformations

After connecting to MySQL (or CSV), apply these transformations in Power Query:

### fact_sales
```m
// Change types
= Table.TransformColumnTypes(#"Previous Step", {
    {"sales",    type number},
    {"profit",   type number},
    {"quantity", Int64.Type},
    {"discount", type number}
})
```

### Create Calendar table
```m
= List.Dates(#date(2021,1,1), 1096, #duration(1,0,0,0))
```

Or use the DAX Calendar table formula from `dax_measures.md`.

### dim_product (from CSV — if not using MySQL)
```m
= Table.Distinct(
    Table.SelectColumns(
        SalesClean,
        {"product_id", "category", "sub_category", "product_name"}
    ),
    "product_id"
)
```

---

## Slicer Configuration

| Slicer | Field | Type | Pages |
|:-------|:------|:-----|:------|
| Date Range | Calendar[Date] | Date range slider | All pages |
| Year | Calendar[Year] | Dropdown / tile | All pages |
| Region | fact_sales[region] | Dropdown | P1, P2 |
| Category | dim_product[category] | Tile (3 buttons) | P1, P3 |
| Segment | dim_customer[segment] | Dropdown | P1, P3 |
| Sub-Category | dim_product[sub_category] | Dropdown | P3 |

---

## Page Navigation Setup

1. Create a **blank button** on each page (Insert → Buttons → Blank)
2. Set **Action = Page navigation** with destination page
3. Group navigation buttons into a consistent navigation bar at the top

Navigation bar pages:
- 📊 Overview
- 🗺️ Regional
- 📦 Products
- 📈 Trends

---

## Tooltip Configuration

| Visual | Tooltip Fields |
|:-------|:--------------|
| Map | State, Sales, Profit, Margin % |
| Product bar chart | Product Name, Category, Sales Rank |
| Line chart | Month, Sales, MoM Growth %, YoY Growth % |
| Scatter (discount) | Discount %, Margin %, Order Count |
