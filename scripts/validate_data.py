"""
validate_data.py
================
Comprehensive data validation script for the Sales Performance Dashboard.
Runs all validation checks and generates a validation results report.

Usage:
    python scripts/validate_data.py

Output:
    reports/validation_results.md
"""

import os
import sys
import pandas as pd
import numpy as np
from datetime import datetime

BASE_DIR    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLEAN_PATH  = os.path.join(BASE_DIR, "data", "processed", "sales_clean.csv")
RAW_PATH    = os.path.join(BASE_DIR, "data", "raw",       "sales_raw.csv")
REPORT_PATH = os.path.join(BASE_DIR, "reports", "validation_results.md")

PASS = "PASS"
FAIL = "FAIL"
WARN = "WARN"

results = []

def check(name: str, status: str, detail: str, value=None):
    results.append({"check": name, "status": status, "detail": detail, "value": value})
    icon = {"PASS": "[PASS]", "FAIL": "[FAIL]", "WARN": "[WARN]"}[status]
    print(f"  {icon} {name}: {detail}")


def run_validation():
    print("=" * 65)
    print("  Sales Performance Dashboard — Data Validation Script")
    print("=" * 65)

    # ── Load data ────────────────────────────────────────────────────────
    print("\n[1] Loading datasets...")
    if not os.path.exists(CLEAN_PATH):
        check("File: sales_clean.csv", FAIL, "File not found. Run generate_dataset.py first.")
        return
    if not os.path.exists(RAW_PATH):
        check("File: sales_raw.csv",   FAIL, "File not found. Run generate_dataset.py first.")
        return

    raw   = pd.read_csv(RAW_PATH)
    clean = pd.read_csv(CLEAN_PATH)
    clean["order_date"] = pd.to_datetime(clean["order_date"])
    clean["ship_date"]  = pd.to_datetime(clean["ship_date"])

    # ── Section A: Record Counts ─────────────────────────────────────────
    print("\n[2] Section A — Record Counts")

    raw_count   = len(raw)
    clean_count = len(clean)
    check("A1: Raw record count",   PASS if raw_count   == 7500 else WARN,
          f"Rows: {raw_count:,} (expected 7,500)", raw_count)
    check("A2: Clean record count", PASS if clean_count == 7500 else WARN,
          f"Rows: {clean_count:,} (expected 7,500)", clean_count)

    dup_removed = raw_count - clean_count
    check("A3: Duplicates removed", PASS if dup_removed == 0 else WARN,
          f"Removed: {dup_removed}", dup_removed)

    # ── Section B: Null Checks ───────────────────────────────────────────
    print("\n[3] Section B — Null Checks")
    critical_cols = ["row_id", "order_id", "order_date", "ship_date",
                     "customer_id", "product_id", "sales", "quantity", "profit"]
    for col in critical_cols:
        nulls = clean[col].isnull().sum()
        check(f"B: Null check [{col}]",
              PASS if nulls == 0 else FAIL,
              f"{nulls} nulls", nulls)

    # ── Section C: Data Type Validation ──────────────────────────────────
    print("\n[4] Section C — Data Type Validation")
    check("C1: sales dtype",    PASS if clean["sales"].dtype    in [float, "float64"] else FAIL,
          str(clean["sales"].dtype))
    check("C2: profit dtype",   PASS if clean["profit"].dtype   in [float, "float64"] else FAIL,
          str(clean["profit"].dtype))
    check("C3: quantity dtype", PASS if clean["quantity"].dtype in [int, "int64"]      else FAIL,
          str(clean["quantity"].dtype))
    check("C4: discount dtype", PASS if clean["discount"].dtype in [float, "float64"] else FAIL,
          str(clean["discount"].dtype))

    # ── Section D: Range Validation ──────────────────────────────────────
    print("\n[5] Section D — Range Validation")
    neg_sales = (clean["sales"] <= 0).sum()
    neg_qty   = (clean["quantity"] <= 0).sum()
    bad_disc  = ((clean["discount"] < 0) | (clean["discount"] > 1)).sum()

    check("D1: Sales > 0",           PASS if neg_sales == 0 else FAIL,
          f"Violations: {neg_sales}", neg_sales)
    check("D2: Quantity >= 1",        PASS if neg_qty == 0   else FAIL,
          f"Violations: {neg_qty}",   neg_qty)
    check("D3: Discount in [0, 1]",   PASS if bad_disc == 0  else FAIL,
          f"Violations: {bad_disc}",  bad_disc)

    loss_rows = (clean["profit"] < 0).sum()
    check("D4: Loss-making rows (informational)",
          WARN if loss_rows > 0 else PASS,
          f"{loss_rows} rows with negative profit (expected for discounted items)",
          loss_rows)

    # ── Section E: Date Validation ───────────────────────────────────────
    print("\n[6] Section E — Date Validation")
    bad_dates = (clean["ship_date"] < clean["order_date"]).sum()
    check("E1: Ship date >= Order date", PASS if bad_dates == 0 else FAIL,
          f"Violations: {bad_dates}", bad_dates)

    min_date = clean["order_date"].min().date()
    max_date = clean["order_date"].max().date()
    date_ok  = (min_date >= pd.Timestamp("2021-01-01").date() and
                max_date <= pd.Timestamp("2023-12-31").date())
    check("E2: Dates in 2021-2023",
          PASS if date_ok else FAIL,
          f"{min_date} → {max_date}", f"{min_date} to {max_date}")

    # ── Section F: Uniqueness Checks ─────────────────────────────────────
    print("\n[7] Section F — Uniqueness Checks")
    dup_rowids = clean["row_id"].duplicated().sum()
    check("F1: row_id uniqueness",     PASS if dup_rowids == 0 else FAIL,
          f"Duplicates: {dup_rowids}", dup_rowids)

    unique_products = clean["product_id"].nunique()
    unique_customers = clean["customer_id"].nunique()
    check("F2: Unique products",   PASS if unique_products  == 80  else WARN,
          f"{unique_products} (expected 80)",  unique_products)
    check("F3: Unique customers",  PASS if unique_customers == 795 else WARN,
          f"{unique_customers} (expected 795)", unique_customers)

    # ── Section G: KPI Reconciliation ────────────────────────────────────
    print("\n[8] Section G — KPI Reconciliation")
    total_sales  = round(clean["sales"].sum(), 2)
    total_profit = round(clean["profit"].sum(), 2)
    total_qty    = int(clean["quantity"].sum())
    total_orders = clean["order_id"].nunique()
    margin       = round(total_profit / total_sales * 100, 2)
    avg_ov       = round(clean.groupby("order_id")["sales"].sum().mean(), 2)

    EXPECTED = {
        "total_sales":   3333386.08,
        "total_profit":  224989.95,
        "total_qty":     20968,
        "total_orders":  4360,
        "avg_ov":        764.54,
        "margin":        6.75,
    }

    def tol_check(name, actual, expected, tol=1.0):
        ok = abs(actual - expected) <= tol
        check(f"G: {name}",
              PASS if ok else FAIL,
              f"Actual: {actual:,.2f} | Expected: {expected:,.2f}",
              actual)

    tol_check("Total Sales",          total_sales,  EXPECTED["total_sales"],  1.0)
    tol_check("Total Profit",         total_profit, EXPECTED["total_profit"], 1.0)
    tol_check("Total Quantity",       total_qty,    EXPECTED["total_qty"],    0)
    tol_check("Total Orders",         total_orders, EXPECTED["total_orders"], 0)
    tol_check("Avg Order Value",      avg_ov,       EXPECTED["avg_ov"],       1.0)
    tol_check("Profit Margin %",      margin,       EXPECTED["margin"],       0.05)

    # ── Section H: Profit Margin Calculation Method ───────────────────────
    print("\n[9] Section H — Profit Margin Method")
    correct_margin    = round(clean["profit"].sum() / clean["sales"].sum() * 100, 2)
    misleading_margin = round(
        (clean["profit"] / clean["sales"]).mean() * 100, 2
    )
    check("H1: Correct aggregate margin",
          PASS,
          f"{correct_margin}% (SUM(profit)/SUM(sales)) — CORRECT method")
    check("H2: Row-average margin (misleading)",
          WARN,
          f"{misleading_margin}% (AVG of row margins) — DO NOT USE for KPIs")

    # ── Section I: Category / Region Coverage ────────────────────────────
    print("\n[10] Section I — Coverage Checks")
    regions    = sorted(clean["region"].unique().tolist())
    categories = sorted(clean["category"].unique().tolist())
    check("I1: Regions present", PASS if len(regions) == 4 else FAIL,
          str(regions))
    check("I2: Categories present", PASS if len(categories) == 3 else FAIL,
          str(categories))
    check("I3: Segments present",
          PASS if clean["segment"].nunique() == 3 else FAIL,
          str(sorted(clean["segment"].unique().tolist())))

    # ── Generate Report ───────────────────────────────────────────────────
    os.makedirs(os.path.dirname(REPORT_PATH), exist_ok=True)
    passed  = sum(1 for r in results if r["status"] == PASS)
    failed  = sum(1 for r in results if r["status"] == FAIL)
    warned  = sum(1 for r in results if r["status"] == WARN)
    total   = len(results)

    lines = [
        "# Data Validation Results",
        f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"\n**Dataset:** `data/processed/sales_clean.csv`\n",
        f"| Metric       | Count |",
        f"|:-------------|------:|",
        f"| Total Checks | {total} |",
        f"| PASS         | {passed} |",
        f"| FAIL         | {failed} |",
        f"| WARN         | {warned} |",
        "",
        "## Detailed Results",
        "",
        "| # | Check | Status | Detail |",
        "|---|-------|--------|--------|",
    ]
    for i, r in enumerate(results, 1):
        icon = {"PASS": "✅", "FAIL": "❌", "WARN": "⚠️"}[r["status"]]
        lines.append(f"| {i} | {r['check']} | {icon} {r['status']} | {r['detail']} |")

    lines += [
        "",
        "## Key Baseline Metrics (from validated dataset)",
        "",
        f"| Metric | Value |",
        f"|:-------|------:|",
        f"| Total Records | 7,500 |",
        f"| Total Sales | $3,333,386.08 |",
        f"| Total Profit | $224,989.95 |",
        f"| Profit Margin | 6.75% |",
        f"| Total Quantity | 20,968 |",
        f"| Total Orders | 4,360 |",
        f"| Unique Customers | 795 |",
        f"| Unique Products | 80 |",
        f"| Date Range | 2021-01-01 to 2023-12-31 |",
        f"| Loss-Making Rows | 811 |",
        "",
        "## Notes",
        "",
        "> [!IMPORTANT]",
        "> **Profit Margin Calculation:** Always use `SUM(profit) / SUM(sales)`",
        "> (aggregate method), NOT `AVG(profit/sales)` (row-average method).",
        "> The row-average method produces misleading results when order sizes vary.",
        "",
        "> [!NOTE]",
        "> **MySQL validation:** SQL query results cannot be auto-tested because",
        "> MySQL is not installed in this environment. After setting up MySQL,",
        "> run 04_kpi_analysis.sql Q1 and compare against the baseline above.",
        "",
        "> [!NOTE]",
        "> **Power BI validation:** Power BI Desktop must be installed and the",
        "> MySQL connector configured to test DAX measures against SQL results.",
    ]

    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"\n{'='*65}")
    print(f"  Validation Complete: {passed} PASS | {failed} FAIL | {warned} WARN")
    print(f"  Report saved → {REPORT_PATH}")
    print(f"{'='*65}\n")

    if failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    run_validation()
