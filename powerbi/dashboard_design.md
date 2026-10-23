# Dashboard Design Guide
## Sales Performance Dashboard — Power BI Layout Specification

---

## Design Principles

| Principle | Implementation |
|:----------|:--------------|
| Clean background | White (#FFFFFF) or very light grey (#F8F9FA) |
| Primary accent | Navy blue (#1A2744) |
| Secondary accent | Steel blue (#2E6DA4) |
| Positive values | Green (#27AE60) |
| Negative/alert | Red (#E74C3C) |
| Neutral | Medium grey (#6C757D) |
| Typography | Segoe UI (Power BI default) |
| Card border radius | 8px |
| Consistent padding | 12px |

---

## Page 1: Executive Overview

**Canvas Size:** 1280 × 720 px

```
┌──────────────────────────────────────────────────────────────────┐
│  SALES PERFORMANCE DASHBOARD         [Nav: Overview|Regional|Product|Trends]│
├──────────────────────────────────────────────────────────────────┤
│ SLICERS: [Date Range ▼] [Year ▼] [Region ▼] [Category ■ ■ ■]    │
├────────────┬──────────────┬──────────────┬───────────────────────┤
│ KPI: TOTAL │ KPI: PROFIT  │ KPI: ORDERS  │ KPI: PROFIT MARGIN    │
│ SALES      │              │              │                       │
│ $3.33M     │ $224,990     │ 4,360        │ 6.75%                 │
│ ↑ YoY      │ ↑ YoY        │              │                       │
├────────────┴──────────────┴──────────────┴───────────────────────┤
│                                          │                       │
│  Monthly Sales & Profit Trend (Line)     │  Sales by Region      │
│  2021-2023                               │  (Clustered Bar)      │
│                                          │                       │
├──────────────────────────┬───────────────┴───────────────────────┤
│                          │                                       │
│  Sales by Category       │  Top 10 Products by Sales             │
│  (Donut / Pie chart)     │  (Horizontal Bar)                     │
│                          │                                       │
└──────────────────────────┴───────────────────────────────────────┘
```

### KPI Card Configuration
- **Visual:** Card
- **Value field:** `[Total Sales]`, `[Total Profit]`, `[Total Orders]`, `[Profit Margin %]`
- **Trend indicator:** Add `[YoY Growth %]` as a reference line or secondary label
- **Background:** White with navy border (#1A2744), 2px
- **Value font:** Segoe UI Semibold, 28pt, Navy
- **Label font:** Segoe UI, 10pt, Grey

### Monthly Trend (Line Chart)
- **X-axis:** `Calendar[MonthSort]` sorted by MonthSort ascending
- **Y-axis (primary):** `[Total Sales]`
- **Y-axis (secondary):** `[Total Profit]`
- **Line color:** Sales = #2E6DA4, Profit = #27AE60
- **Data labels:** ON for year-end points only
- **Title:** "Monthly Sales & Profit Trend (2021–2023)"

### Regional Sales Bar (Clustered Bar)
- **Y-axis:** `fact_sales[region]`
- **X-axis:** `[Total Sales]`, `[Total Profit]`
- **Sort:** Descending by Total Sales
- **Data labels:** ON, currency format

### Sales by Category (Donut)
- **Legend:** `dim_product[category]`
- **Values:** `[Total Sales]`
- **Colors:** Technology=#1A2744, Furniture=#2E6DA4, Office Supplies=#3498DB

### Top 10 Products (Horizontal Bar)
- **Y-axis:** `dim_product[product_name]`
- **X-axis:** `[Total Sales]`
- **Filter:** Top N = 10 by `[Total Sales]`
- **Sort:** Descending
- **Conditional formatting:** Color bars by `[Profit Margin %]` (green-to-red)

---

## Page 2: Regional Analysis

**Canvas Size:** 1280 × 720 px

```
┌──────────────────────────────────────────────────────────────────┐
│  REGIONAL ANALYSIS               [Nav] SLICERS: Date | Category  │
├────────────────────────────────────┬─────────────────────────────┤
│                                    │  Sales & Profit by Region   │
│   US State Filled Map              │  (Clustered Column)         │
│   (Color = Total Sales)            │                             │
│   Tooltip: State, Sales, Profit,   │                             │
│            Margin %                │                             │
│                                    │                             │
├────────────────────────────────────┼─────────────────────────────┤
│                                    │                             │
│  State Ranking Table               │  Regional Contribution %    │
│  (Top 15 by Sales)                 │  (100% Stacked Bar)         │
│  Columns: State | Sales | Profit   │  or Pie/Donut               │
│           | Margin % | Rank        │                             │
│                                    │                             │
└────────────────────────────────────┴─────────────────────────────┘
```

### Filled Map Configuration
- **Location:** `fact_sales[state]` — set **Data Category = State/Province**
  - Right-click column in Data pane → Data Category → State or Province
- **Values:** `[Total Sales]` (controls bubble size or fill intensity)
- **Color saturation:** `[Profit Margin %]` — diverging red-to-green
- **Tooltips:** State, Total Sales, Total Profit, Profit Margin %
- **Filter:** Country = "United States"

> **Note:** If the map shows incorrect geography, verify that Power BI
> has recognised US state names. You may need to add `country = "United States"`
> as a column and set `Data Category = Country` on it.

### State Ranking Table
- **Columns:** Region, State, Orders, Sales, Profit, Margin %, Rank
- **Sort:** Sales descending
- **Conditional formatting on Margin %:** Red (<0%) to Green (>15%)
- **Top N filter:** Top 20 states by Sales

---

## Page 3: Product & Profitability Analysis

**Canvas Size:** 1280 × 720 px

```
┌──────────────────────────────────────────────────────────────────┐
│  PRODUCT & PROFITABILITY         [Nav]  SLICERS: Category | Sub-Category│
├────────────────┬─────────────────┬──────────────────────────────┤
│  Top 10        │  Bottom 10      │   Category Margin (Bar)      │
│  Products      │  Products by    │   Sub-cat Margin (Bar)       │
│  by Profit     │  Profit (Loss)  │                              │
│  (Horiz Bar)   │  (Horiz Bar)    │                              │
├────────────────┴─────────────────┴──────────────────────────────┤
│                                          │                       │
│  Discount vs Profit Scatter              │  Sub-Category         │
│  (X=Avg Discount%, Y=Profit Margin%)     │  Treemap              │
│  Size=Total Sales, Color=Category        │  (Size=Sales,         │
│                                          │   Color=Margin)       │
├──────────────────────────────────────────┴───────────────────────┤
│  Category Profitability Band Table                               │
│  Columns: Category | Sub-Cat | Sales | Profit | Margin | Band   │
└──────────────────────────────────────────────────────────────────┘
```

### Scatter Chart (Discount vs Profit)
- **X-axis:** `AVERAGE(fact_sales[discount])` — format as %
- **Y-axis:** `[Profit Margin %]`
- **Size:** `[Total Sales]`
- **Color:** `dim_product[category]`
- **Title:** "Discount Level vs Profit Margin (by Sub-Category)"
- **Reference line:** Y=0 (break-even margin line)

> **Interpretation note:** This shows correlation, not causation.
> High discounts are associated with lower margins, but some high-discount
> items (e.g., Office Supplies) remain profitable due to higher base margins.

### Treemap
- **Group:** `dim_product[category]`, `dim_product[sub_category]`
- **Values:** `[Total Sales]`
- **Color:** `[Profit Margin %]` — diverging palette

---

## Page 4: Trends & Growth

**Canvas Size:** 1280 × 720 px

```
┌──────────────────────────────────────────────────────────────────┐
│  TRENDS & GROWTH                 [Nav]  SLICERS: Year | Category │
├──────────────────────────────────────────────────────────────────┤
│  MoM Growth % (Column Chart)    │   YoY Growth % (Column Chart) │
│  X=Month, Y=MoM Growth %        │   X=Month, Y=YoY Growth %     │
│  Conditional color: +green/-red │   2022 vs 2021, 2023 vs 2022  │
├─────────────────────────────────┴──────────────────────────────── │
│                                                                   │
│  Monthly Sales Trend — 2021, 2022, 2023 Overlay (Multi-line)     │
│  X=Month (1-12), Y=Sales, Line per Year                          │
│  Shows seasonality: Q4 Nov/Dec peak clearly visible              │
│                                                                   │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Running Total Sales (Area Chart)  │  Quarterly Summary Table    │
│  X=Month, Y=YTD Sales              │  Q | Sales | Profit | Margin│
│  Color per year                    │                             │
└────────────────────────────────────┴────────────────────────────┘
```

### Multi-Year Overlay Line Chart
- **X-axis:** Calendar[Month] (1–12), labeled with month abbreviations
- **Lines:** One per year (2021, 2022, 2023)
- **Legend:** Year
- **Title:** "Monthly Sales by Year — Seasonality Comparison"
- **Insight to highlight:** November and December consistently peak each year

### MoM Growth Column Chart
- **X-axis:** `Calendar[MonthSort]` (sorted)
- **Y-axis:** `[MoM Growth %]`
- **Conditional formatting:** Positive = #27AE60 (green), Negative = #E74C3C (red)
- **Reference line:** Y = 0

---

## Theme JSON Location

The custom Power BI theme is stored at `powerbi/theme.json`.
To apply it in Power BI Desktop:
1. **View → Themes → Browse for themes**
2. Select `powerbi/theme.json`

---

## Accessibility Checklist

- [ ] All visuals have descriptive titles
- [ ] Color coding is NOT the sole indicator (use labels)
- [ ] Contrast ratio meets WCAG AA (4.5:1 minimum)
- [ ] Alt text added to all visuals (Format → Alt text)
- [ ] Tab order set logically for each page
- [ ] Currency and percentage formatting consistent throughout
