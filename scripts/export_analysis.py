"""
export_analysis.py
==================
Generates a multi-sheet Excel workbook for the Sales Performance Dashboard.
Uses openpyxl for full formatting control.

Output: data/excel/Sales_Performance_Dashboard.xlsx

Usage:
    python scripts/export_analysis.py

Requirements:
    pip install pandas openpyxl
"""

import os
import pandas as pd
import numpy as np
from openpyxl import Workbook
from openpyxl.styles import (
    Font, PatternFill, Alignment, Border, Side, numbers
)
from openpyxl.utils import get_column_letter
from openpyxl.chart import BarChart, LineChart, Reference
from openpyxl.chart.series import DataPoint

BASE_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLEAN_PATH = os.path.join(BASE_DIR, "data", "processed", "sales_clean.csv")
OUT_PATH   = os.path.join(BASE_DIR, "data", "excel", "Sales_Performance_Dashboard.xlsx")

# ── Colour palette ────────────────────────────────────────────────────────────
NAVY       = "1A2744"
LIGHT_BLUE = "2E6DA4"
ACCENT     = "3498DB"
LIGHT_GREY = "F2F4F8"
DARK_GREY  = "555555"
WHITE      = "FFFFFF"
GREEN      = "27AE60"
RED        = "E74C3C"
YELLOW     = "F39C12"


# ── Style helpers ─────────────────────────────────────────────────────────────
def header_font(bold=True, color=WHITE, size=11):
    return Font(name="Calibri", bold=bold, color=color, size=size)

def data_font(bold=False, color="000000", size=10):
    return Font(name="Calibri", bold=bold, color=color, size=size)

def header_fill(hex_color=NAVY):
    return PatternFill("solid", fgColor=hex_color)

def row_fill(hex_color=LIGHT_GREY):
    return PatternFill("solid", fgColor=hex_color)

def thin_border():
    side = Side(style="thin", color="CCCCCC")
    return Border(left=side, right=side, top=side, bottom=side)

def center():
    return Alignment(horizontal="center", vertical="center", wrap_text=True)

def right():
    return Alignment(horizontal="right", vertical="center")

def format_header_row(ws, row: int, ncols: int):
    for col in range(1, ncols + 1):
        cell = ws.cell(row=row, column=col)
        cell.font      = header_font()
        cell.fill      = header_fill()
        cell.alignment = center()
        cell.border    = thin_border()

def auto_width(ws, padding=4):
    for col in ws.columns:
        max_len = 0
        col_letter = get_column_letter(col[0].column)
        for cell in col:
            try:
                max_len = max(max_len, len(str(cell.value)))
            except Exception:
                pass
        ws.column_dimensions[col_letter].width = min(max_len + padding, 45)

def write_df_to_sheet(ws, df: pd.DataFrame, start_row=1):
    """Write DataFrame to worksheet with styled headers and alternating rows."""
    ncols = len(df.columns)
    # Header
    for ci, col_name in enumerate(df.columns, 1):
        ws.cell(row=start_row, column=ci, value=col_name)
    format_header_row(ws, start_row, ncols)

    # Data rows
    for ri, row in enumerate(df.itertuples(index=False), start_row + 1):
        fill = row_fill(LIGHT_GREY) if ri % 2 == 0 else PatternFill("solid", fgColor=WHITE)
        for ci, val in enumerate(row, 1):
            cell = ws.cell(row=ri, column=ci, value=val)
            cell.font      = data_font()
            cell.fill      = fill
            cell.border    = thin_border()
            cell.alignment = Alignment(vertical="center")

            # Number formatting
            col_name = df.columns[ci - 1].lower()
            if any(k in col_name for k in ["sales", "profit", "value", "monetary"]):
                cell.number_format = '"$"#,##0.00'
            elif "pct" in col_name or "margin" in col_name or "growth" in col_name:
                cell.number_format = '0.00"%"'
            elif "discount" in col_name and "pct" not in col_name:
                cell.number_format = '0.00"%"'
            elif any(k in col_name for k in ["qty", "quantity", "orders", "units", "rows", "count", "customers"]):
                cell.number_format = "#,##0"


# ── Load data ─────────────────────────────────────────────────────────────────
def load_data():
    df = pd.read_csv(CLEAN_PATH)
    df["order_date"] = pd.to_datetime(df["order_date"])
    df["ship_date"]  = pd.to_datetime(df["ship_date"])
    df["year"]       = df["order_date"].dt.year
    df["month"]      = df["order_date"].dt.month
    df["month_name"] = df["order_date"].dt.strftime("%b")
    df["year_month"] = df["order_date"].dt.to_period("M").astype(str)
    return df


# ── Sheet builders ────────────────────────────────────────────────────────────
def build_raw_data_sheet(wb, df):
    ws = wb.create_sheet("Raw_Data")
    ws.sheet_view.showGridLines = True
    ws.freeze_panes = "A2"

    # Write headers and data
    write_df_to_sheet(ws, df[["row_id","order_id","order_date","ship_date",
                               "ship_mode","customer_id","customer_name",
                               "segment","country","state","city","region",
                               "product_id","category","sub_category",
                               "product_name","sales","quantity","discount","profit"]])

    # Format date columns
    for row in ws.iter_rows(min_row=2, max_row=ws.max_row):
        for cell in row:
            if ws.cell(1, cell.column).value in ("order_date", "ship_date"):
                cell.number_format = "YYYY-MM-DD"

    auto_width(ws)
    ws.column_dimensions["A"].width = 7
    print("[OK] Sheet: Raw_Data")


def build_cleaned_data_sheet(wb, df):
    ws = wb.create_sheet("Cleaned_Data")
    ws.freeze_panes = "A2"

    # Same as raw but with formatting applied
    write_df_to_sheet(ws, df[["row_id","order_id","order_date","ship_date",
                               "ship_mode","customer_id","customer_name",
                               "segment","country","state","city","region",
                               "product_id","category","sub_category",
                               "product_name","sales","quantity","discount","profit"]])

    # Add data validation flags column
    max_row = ws.max_row
    ws.cell(1, 21, "data_quality_flag")
    ws.cell(1, 21).font = header_font()
    ws.cell(1, 21).fill = header_fill(LIGHT_BLUE)
    ws.cell(1, 21).alignment = center()

    for row in ws.iter_rows(min_row=2, max_row=max_row):
        profit_cell = row[19]  # profit column (index 19 = col 20)
        disc_cell   = row[18]  # discount column
        flag_cell   = ws.cell(row=profit_cell.row, column=21)
        flag_cell.font   = data_font()
        flag_cell.border = thin_border()
        # We can't evaluate Python values here; use Excel formula
        flag_cell.value = (
            f'=IF(T{profit_cell.row}<0,"Loss-Making",'
            f'IF(S{profit_cell.row}>0.3,"High Discount","OK"))'
        )

    auto_width(ws)
    print("[OK] Sheet: Cleaned_Data")


def build_data_quality_sheet(wb, df):
    ws = wb.create_sheet("Data_Quality")
    ws.sheet_view.showGridLines = False

    def title(row, col, text, color=NAVY):
        c = ws.cell(row=row, column=col, value=text)
        c.font = Font(name="Calibri", bold=True, size=13, color=WHITE)
        c.fill = PatternFill("solid", fgColor=color)
        c.alignment = center()
        return c

    def kv(row, key, val, val_fmt=None):
        kc = ws.cell(row=row, column=1, value=key)
        kc.font = Font(name="Calibri", bold=True, size=10, color=DARK_GREY)
        kc.fill = PatternFill("solid", fgColor=LIGHT_GREY)
        kc.border = thin_border()
        kc.alignment = Alignment(vertical="center")

        vc = ws.cell(row=row, column=2, value=val)
        vc.font = Font(name="Calibri", size=10)
        vc.border = thin_border()
        vc.alignment = right()
        if val_fmt:
            vc.number_format = val_fmt

    r = 1
    ws.merge_cells(f"A{r}:D{r}")
    title(r, 1, "DATA QUALITY REPORT — Sales Performance Dashboard")
    ws.row_dimensions[r].height = 30
    r += 1

    ws.cell(r, 1, f"Generated: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M')}").font = data_font(color=DARK_GREY)
    r += 2

    # Summary section
    ws.merge_cells(f"A{r}:D{r}")
    title(r, 1, "Dataset Overview", LIGHT_BLUE)
    r += 1
    kv(r, "Total Records",   len(df), "#,##0"); r += 1
    kv(r, "Unique Orders",   df["order_id"].nunique(),  "#,##0"); r += 1
    kv(r, "Unique Customers",df["customer_id"].nunique(),"#,##0"); r += 1
    kv(r, "Unique Products", df["product_id"].nunique(), "#,##0"); r += 1
    kv(r, "Date Range Start",str(df["order_date"].min().date())); r += 1
    kv(r, "Date Range End",  str(df["order_date"].max().date())); r += 1
    kv(r, "Total Sales",     df["sales"].sum(),  '"$"#,##0.00'); r += 1
    kv(r, "Total Profit",    df["profit"].sum(), '"$"#,##0.00'); r += 1
    kv(r, "Profit Margin %", round(df["profit"].sum()/df["sales"].sum()*100, 2), '0.00"%"'); r += 1
    r += 1

    # Null counts
    ws.merge_cells(f"A{r}:D{r}")
    title(r, 1, "Null Value Counts", LIGHT_BLUE)
    r += 1
    for col in df.columns:
        nulls = df[col].isnull().sum()
        kv(r, col, nulls, "#,##0")
        if nulls == 0:
            ws.cell(r, 2).fill = PatternFill("solid", fgColor="D5F5E3")
        else:
            ws.cell(r, 2).fill = PatternFill("solid", fgColor="FADBD8")
        r += 1
    r += 1

    # Data issues
    ws.merge_cells(f"A{r}:D{r}")
    title(r, 1, "Data Quality Checks", LIGHT_BLUE)
    r += 1
    checks = [
        ("Duplicate row_ids", df["row_id"].duplicated().sum()),
        ("Negative/zero sales", (df["sales"] <= 0).sum()),
        ("Negative/zero quantity", (df["quantity"] <= 0).sum()),
        ("Invalid discount (>1 or <0)", ((df["discount"] < 0) | (df["discount"] > 1)).sum()),
        ("Ship before order date", (df["ship_date"] < df["order_date"]).sum()),
        ("Loss-making rows", (df["profit"] < 0).sum()),
    ]
    for name, count in checks:
        kv(r, name, count, "#,##0")
        fill_color = "D5F5E3" if count == 0 else ("FFF9C4" if count < 100 else "FADBD8")
        ws.cell(r, 2).fill = PatternFill("solid", fgColor=fill_color)
        r += 1

    ws.column_dimensions["A"].width = 35
    ws.column_dimensions["B"].width = 18
    print("[OK] Sheet: Data_Quality")


def build_sales_summary_sheet(wb, df):
    ws = wb.create_sheet("Sales_Summary")
    ws.sheet_view.showGridLines = False
    ws.freeze_panes = "A2"

    summary = df.groupby("year").agg(
        total_orders   =("order_id",    "nunique"),
        total_customers=("customer_id", "nunique"),
        total_sales    =("sales",        "sum"),
        total_profit   =("profit",       "sum"),
        total_quantity =("quantity",     "sum"),
    ).reset_index()
    summary["profit_margin_pct"] = (summary["total_profit"] / summary["total_sales"] * 100).round(2)
    summary.columns = ["Year","Total Orders","Total Customers",
                        "Total Sales ($)","Total Profit ($)","Total Quantity","Profit Margin (%)"]
    for col in ["Total Sales ($)", "Total Profit ($)"]:
        summary[col] = summary[col].round(2)

    # Segment summary
    seg = df.groupby("segment").agg(
        total_orders=("order_id", "nunique"),
        total_sales =("sales",    "sum"),
        total_profit=("profit",   "sum"),
    ).reset_index()
    seg["profit_margin_pct"] = (seg["total_profit"] / seg["total_sales"] * 100).round(2)

    r = 1
    ws.merge_cells("A1:G1")
    c = ws.cell(1, 1, "SALES SUMMARY — By Year")
    c.font = Font(name="Calibri", bold=True, size=14, color=WHITE)
    c.fill = PatternFill("solid", fgColor=NAVY)
    c.alignment = center()
    ws.row_dimensions[1].height = 28
    r = 2

    write_df_to_sheet(ws, summary, start_row=r)
    r += len(summary) + 3

    ws.cell(r, 1, "SALES SUMMARY — By Segment").font = Font(name="Calibri", bold=True, size=14, color=WHITE)
    ws.merge_cells(f"A{r}:E{r}")
    ws.cell(r, 1).fill = PatternFill("solid", fgColor=NAVY)
    ws.cell(r, 1).alignment = center()
    ws.row_dimensions[r].height = 28
    r += 1

    seg.columns = ["Segment","Total Orders","Total Sales ($)","Total Profit ($)","Profit Margin (%)"]
    seg["Total Sales ($)"]  = seg["Total Sales ($)"].round(2)
    seg["Total Profit ($)"] = seg["Total Profit ($)"].round(2)
    write_df_to_sheet(ws, seg, start_row=r)

    auto_width(ws)
    print("[OK] Sheet: Sales_Summary")


def build_monthly_trends_sheet(wb, df):
    ws = wb.create_sheet("Monthly_Trends")
    ws.freeze_panes = "A3"

    monthly = df.groupby(["year", "month", "month_name"]).agg(
        orders =("order_id", "nunique"),
        sales  =("sales",    "sum"),
        profit =("profit",   "sum"),
        qty    =("quantity", "sum"),
    ).reset_index().sort_values(["year", "month"])

    monthly["profit_margin_pct"] = (monthly["profit"] / monthly["sales"] * 100).round(2)
    monthly["sales"]  = monthly["sales"].round(2)
    monthly["profit"] = monthly["profit"].round(2)
    monthly["mom_growth_pct"] = (
        monthly["sales"].pct_change() * 100
    ).round(2)
    monthly.columns = ["Year","Month","Month Name","Orders",
                        "Sales ($)","Profit ($)","Quantity","Profit Margin (%)","MoM Growth (%)"]

    write_df_to_sheet(ws, monthly, start_row=1)

    # Add a line chart
    data_rows = len(monthly) + 1
    chart = LineChart()
    chart.title  = "Monthly Sales Trend"
    chart.style  = 10
    chart.y_axis.title = "Sales ($)"
    chart.x_axis.title = "Month"
    chart.width  = 28
    chart.height = 14

    sales_data = Reference(ws, min_col=5, min_row=1, max_row=data_rows)
    months_ref = Reference(ws, min_col=3, min_row=2, max_row=data_rows)
    chart.add_data(sales_data, titles_from_data=True)
    chart.set_categories(months_ref)
    chart.series[0].graphicalProperties.line.solidFill = ACCENT
    chart.series[0].graphicalProperties.line.width = 25000

    ws.add_chart(chart, f"K2")

    auto_width(ws)
    print("[OK] Sheet: Monthly_Trends")


def build_regional_analysis_sheet(wb, df):
    ws = wb.create_sheet("Regional_Analysis")
    ws.sheet_view.showGridLines = False

    regional = df.groupby("region").agg(
        orders   =("order_id",    "nunique"),
        customers=("customer_id", "nunique"),
        sales    =("sales",       "sum"),
        profit   =("profit",      "sum"),
        qty      =("quantity",    "sum"),
    ).reset_index().sort_values("sales", ascending=False)
    regional["margin_pct"]       = (regional["profit"] / regional["sales"] * 100).round(2)
    regional["sales_share_pct"]  = (regional["sales"]  / regional["sales"].sum() * 100).round(2)
    regional["sales"]            = regional["sales"].round(2)
    regional["profit"]           = regional["profit"].round(2)
    regional.columns = ["Region","Orders","Customers","Total Sales ($)",
                         "Total Profit ($)","Quantity","Profit Margin (%)","Sales Share (%)"]

    state_df = df.groupby(["region","state"]).agg(
        orders=("order_id",  "nunique"),
        sales =("sales",     "sum"),
        profit=("profit",    "sum"),
    ).reset_index().sort_values("sales", ascending=False)
    state_df["margin_pct"] = (state_df["profit"] / state_df["sales"] * 100).round(2)
    state_df["sales"]  = state_df["sales"].round(2)
    state_df["profit"] = state_df["profit"].round(2)
    state_df.columns = ["Region","State","Orders","Total Sales ($)","Total Profit ($)","Profit Margin (%)"]

    r = 1
    ws.merge_cells("A1:H1")
    c = ws.cell(1, 1, "REGIONAL ANALYSIS")
    c.font = Font(name="Calibri", bold=True, size=14, color=WHITE)
    c.fill = PatternFill("solid", fgColor=NAVY)
    c.alignment = center()
    ws.row_dimensions[1].height = 28
    r = 2

    write_df_to_sheet(ws, regional, start_row=r)
    r += len(regional) + 3

    ws.merge_cells(f"A{r}:F{r}")
    c = ws.cell(r, 1, "STATE-LEVEL BREAKDOWN (Top 20 by Sales)")
    c.font = Font(name="Calibri", bold=True, size=13, color=WHITE)
    c.fill = PatternFill("solid", fgColor=LIGHT_BLUE)
    c.alignment = center()
    ws.row_dimensions[r].height = 25
    r += 1

    write_df_to_sheet(ws, state_df.head(20), start_row=r)

    # Bar chart for regional sales
    bar = BarChart()
    bar.title  = "Sales by Region"
    bar.style  = 10
    bar.type   = "col"
    bar.grouping = "clustered"
    bar.y_axis.title = "Sales ($)"
    bar.width  = 20
    bar.height = 12

    data_ref = Reference(ws, min_col=4, min_row=2, max_row=6)
    cats_ref = Reference(ws, min_col=1, min_row=3, max_row=6)
    bar.add_data(data_ref, titles_from_data=True)
    bar.set_categories(cats_ref)
    ws.add_chart(bar, "J2")

    auto_width(ws)
    print("[OK] Sheet: Regional_Analysis")


def build_category_analysis_sheet(wb, df):
    ws = wb.create_sheet("Category_Analysis")
    ws.sheet_view.showGridLines = False

    cat = df.groupby("category").agg(
        orders=("order_id", "nunique"),
        sales =("sales",    "sum"),
        profit=("profit",   "sum"),
        qty   =("quantity", "sum"),
    ).reset_index().sort_values("sales", ascending=False)
    cat["margin_pct"]      = (cat["profit"] / cat["sales"] * 100).round(2)
    cat["sales_share_pct"] = (cat["sales"]  / cat["sales"].sum() * 100).round(2)
    cat["sales"]  = cat["sales"].round(2)
    cat["profit"] = cat["profit"].round(2)
    cat.columns = ["Category","Orders","Total Sales ($)","Total Profit ($)",
                   "Quantity","Profit Margin (%)","Sales Share (%)"]

    sub = df.groupby(["category","sub_category"]).agg(
        orders=("order_id",  "nunique"),
        sales =("sales",     "sum"),
        profit=("profit",    "sum"),
        qty   =("quantity",  "sum"),
        avg_discount=("discount", "mean"),
    ).reset_index().sort_values("profit", ascending=False)
    sub["margin_pct"]    = (sub["profit"] / sub["sales"] * 100).round(2)
    sub["avg_disc_pct"]  = (sub["avg_discount"] * 100).round(2)
    sub["sales"]  = sub["sales"].round(2)
    sub["profit"] = sub["profit"].round(2)
    sub = sub[["category","sub_category","orders","sales","profit","qty","margin_pct","avg_disc_pct"]]
    sub.columns = ["Category","Sub-Category","Orders","Total Sales ($)",
                   "Total Profit ($)","Quantity","Profit Margin (%)","Avg Discount (%)"]

    r = 1
    ws.merge_cells("A1:G1")
    c = ws.cell(1, 1, "CATEGORY ANALYSIS")
    c.font = Font(name="Calibri", bold=True, size=14, color=WHITE)
    c.fill = PatternFill("solid", fgColor=NAVY)
    c.alignment = center()
    ws.row_dimensions[1].height = 28
    r = 2

    write_df_to_sheet(ws, cat, start_row=r)
    r += len(cat) + 3

    ws.merge_cells(f"A{r}:H{r}")
    c = ws.cell(r, 1, "SUB-CATEGORY BREAKDOWN")
    c.font = Font(name="Calibri", bold=True, size=13, color=WHITE)
    c.fill = PatternFill("solid", fgColor=LIGHT_BLUE)
    c.alignment = center()
    ws.row_dimensions[r].height = 25
    r += 1

    write_df_to_sheet(ws, sub, start_row=r)

    # Colour loss-making rows red
    for row in ws.iter_rows(min_row=r + 1, max_row=r + len(sub)):
        margin_cell = ws.cell(row=row[0].row, column=7)
        try:
            if isinstance(margin_cell.value, (int, float)) and margin_cell.value < 0:
                for cell in row:
                    cell.fill = PatternFill("solid", fgColor="FADBD8")
        except Exception:
            pass

    auto_width(ws)
    print("[OK] Sheet: Category_Analysis")


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("  Sales Performance Dashboard — Excel Workbook Generator")
    print("=" * 60 + "\n")

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    df = load_data()
    print(f"Loaded {len(df):,} records from {CLEAN_PATH}\n")

    wb = Workbook()
    wb.remove(wb.active)   # remove default empty sheet

    build_raw_data_sheet(wb, df)
    build_cleaned_data_sheet(wb, df)
    build_data_quality_sheet(wb, df)
    build_sales_summary_sheet(wb, df)
    build_monthly_trends_sheet(wb, df)
    build_regional_analysis_sheet(wb, df)
    build_category_analysis_sheet(wb, df)

    wb.save(OUT_PATH)
    print(f"\n[OK] Excel workbook saved → {OUT_PATH}")
    print("     Sheets: Raw_Data | Cleaned_Data | Data_Quality |")
    print("             Sales_Summary | Monthly_Trends |")
    print("             Regional_Analysis | Category_Analysis\n")


if __name__ == "__main__":
    main()
