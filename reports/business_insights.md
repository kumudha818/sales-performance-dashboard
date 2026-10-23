# Business Insights Report
## Sales Performance Dashboard — Findings & Recommendations

> **Dataset:** Synthetic retail dataset, 7,500 records, 2021–2023
> **Generated:** 2026-10-20
> **Baseline Source:** `scripts/validate_data.py` — all figures verified against CSV

---

## Executive Summary

The synthetic retail business generated **$3.33M in total revenue** and
**$224,990 in profit** over three years (2021–2023), achieving an overall
profit margin of **6.75%**. While the business is profitable overall,
analysis reveals significant variance across product categories, regions,
and discount levels.

---

## Five Key Findings

### Finding 1: Technology Dominates Revenue but Has a Moderate Margin

| Metric | Technology | Furniture | Office Supplies |
|:-------|:----------:|:---------:|:---------------:|
| Total Sales | $2,392,338 (71.8%) | $742,303 (22.3%) | $198,746 (6.0%) |
| Total Profit | $165,939 | $16,183 | $42,868 |
| Profit Margin | 6.94% | 2.18% | **21.57%** |

**Interpretation:** Technology generates the bulk of revenue but at a moderate
margin. Office Supplies generate far less revenue yet achieve the highest margin.
This suggests that scaling Office Supplies volume could significantly improve
overall profitability without necessarily increasing sales headcount.

---

### Finding 2: The Furniture Category — Particularly Tables — Is Marginally Profitable

The Furniture category achieves only a **2.18% overall profit margin**.
Drilling down to sub-categories reveals the root cause:

| Sub-Category | Total Sales | Total Profit | Margin |
|:-------------|------------:|-------------:|-------:|
| Chairs | $290,964 | $8,218 | 2.82% |
| Bookcases | $152,214 | $6,883 | 4.52% |
| Furnishings | $45,755 | $6,358 | 13.90% |
| **Tables** | **$253,370** | **-$5,276** | **-2.08%** |

The **Tables sub-category is loss-making** (−$5,276 total profit) despite
$253K in sales — the 3rd largest sub-category by revenue. Products like
Flash Furniture Folding Table (−$1,958) and Lifetime 6-Foot Table (−$1,714)
are the primary drivers.

> **Caution on causation:** The tables analysis shows that higher discount
> rates are associated with losses. However, we cannot conclude that discounts
> *cause* losses without controlling for cost structures, which are not in this dataset.

---

### Finding 3: Discount Levels Above 20% Consistently Produce Losses

| Discount Band | Order Lines | Total Profit | Profit Margin |
|:-------------|:------------|:------------|:-------------|
| 0% | 4,093 | $149,981 | positive |
| 1–10% | 1,060 | ~$7,000 | positive |
| 11–20% | 1,008 | ~-$10,000 | negative |
| 21–30% | 857 | ~-$64,000 | negative |
| 31%+ | 482 | ~-$52,000 | negative |

Orders with **zero discount** account for 54.6% of line items and generate
nearly all the profit. Orders with discounts above 20% represent 17.9% of
lines but destroy profit.

> **Correlation, not causation:** Items that need discounts may already be
> slower-selling, lower-margin products. Removing discounts could reduce
> volume, not necessarily improve profit. A controlled pricing experiment
> would be needed to establish causation.

---

### Finding 4: The South Region Has the Highest Profit Margin

| Region | Total Sales | Total Profit | Profit Margin |
|:-------|:-----------:|:------------:|:------------:|
| **East** | $876,213 | $57,523 | 6.56% |
| **West** | $868,523 | $58,151 | 6.70% |
| **Central** | $803,597 | $53,597 | 6.67% |
| **South** | $785,054 | $55,719 | **7.10%** ← |

The South region has the **lowest total sales** but the **highest profit margin**
(7.10%), suggesting more disciplined discounting or better product mix.
The East has the highest sales but marginally lower margin (6.56%).

---

### Finding 5: Q4 Seasonality Is Consistent Across All Three Years

2023 monthly data shows a clear pattern:

| Month | Sales | Pattern |
|:------|------:|:--------|
| Jan–Feb | ~$76K avg | Lowest |
| May | $102K | Mid-year rise |
| Sep–Oct | ~$104K | Pre-holiday rise |
| **Nov** | **$117K** | **Peak** |
| **Dec** | **$116K** | **Peak** |

November and December are consistently the strongest months, reflecting
typical retail holiday seasonality. January is the weakest, suggesting
post-holiday slowdown.

---

## Best Performing Region

**East Region** — Highest total sales ($876,213)
**South Region** — Highest profit margin (7.10%)

---

## Most Profitable Category

**Office Supplies** — 21.57% profit margin ($42,868 profit on $198,746 sales)

*Note: Technology is the most profitable in absolute terms ($165,939)*

---

## Top Products

| Rank | Product | Total Sales | Total Profit |
|:----:|:--------|:------------|:-------------|
| 1 | Dell XPS 15 Laptop | $313,765 | $16,146 |
| 2 | Microsoft Surface Pro 8 | $288,369 | ~$15,000 |
| 3 | HP Spectre x360 | $280,263 | ~$14,000 |
| 1 (profit) | Google Pixel 6 | ~$85,000 | $19,122 |
| 2 (profit) | Lenovo ThinkPad X1 | $260,422 | $17,734 |

---

## Areas with Negative Profit

| Product | Category | Total Profit |
|:--------|:---------|:-------------|
| Flash Furniture Gaming Chair | Furniture > Chairs | -$2,622 |
| Flash Furniture Folding Table | Furniture > Tables | -$1,958 |
| Lifetime 6-Foot Table | Furniture > Tables | -$1,714 |
| Safco Products Mayline Desk | Furniture > Tables | -$1,499 |
| Bush Furniture Cabot Desk | Furniture > Tables | -$345 |

All loss-making products are in the **Furniture category**, driven by
the Tables and Chairs sub-categories with thin base margins and high
discount rates.

---

## Monthly Growth Observations

- **2023 vs 2022:** Business shows consistent growth — November 2023 ($117K)
  was the strongest single month in the dataset.
- **MoM Volatility:** Month-over-month growth swings significantly (±20–30%)
  reflecting promotional activity, not a stable underlying growth trend.
- **Q1 Dip:** January shows the sharpest MoM decline each year (post-holiday).
- **Positive Trend:** The 3-year trend is upward, with 2023 generally above 2022.

---

## Business Recommendations

### Recommendation 1: Implement a Discount Guardrail Policy
**Action:** Cap item-level discounts at 20% for Furniture and Technology products.
**Rationale:** Orders above 20% discount are consistently loss-making. A cap would
preserve margin without eliminating competitive pricing.
**Expected Impact:** Estimated recovery of $80,000–$100,000 in annual profit
from currently loss-making discounted orders.

### Recommendation 2: Review the Tables Sub-Category Pricing
**Action:** Conduct a margin review of the Tables product line.
Either reprice upward, renegotiate supplier costs, or phase out the
3 consistently loss-making SKUs (Flash Furniture Folding Table, Lifetime
6-Foot Table, Safco Mayline Desk).
**Rationale:** Tables is the only sub-category with a negative margin (−2.08%)
despite $253K in revenue.

### Recommendation 3: Scale Office Supplies Volume
**Action:** Invest in marketing and bundling for Office Supplies.
**Rationale:** Office Supplies has the highest margin (21.57%) but only 6%
revenue share. Even doubling Office Supplies volume would add ~$43K profit
without operational complexity.

### Recommendation 4: Leverage Q4 Seasonality
**Action:** Increase inventory and marketing spend in October–November
to capitalise on the consistently strong Q4 period.
**Rationale:** November and December consistently generate 20–30% above
average monthly sales. Under-stocking in Q4 leaves revenue on the table.

### Recommendation 5: Expand in the South Region
**Action:** Investigate why the South achieves the highest margin (7.10%)
despite lower absolute sales.
**Rationale:** If the South's margin advantage is due to better discount
discipline or product mix, replicating those practices in the East and
Central regions could improve overall profitability.

---

## Caveats

- This dataset is **entirely synthetic** and does not represent a real business.
- All monetary values are fictional; recommendations are illustrative of
  real-world analytical thinking.
- Causation claims (e.g., "discounts cause losses") are avoided deliberately —
  the data can only establish correlation.
- RFM segmentation and target attainment measures use constructed benchmarks.
