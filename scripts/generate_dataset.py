"""
generate_dataset.py
===================
Generates a reproducible synthetic retail sales dataset for the
Sales Performance Dashboard portfolio project.

DISCLOSURE: This dataset is entirely synthetic. It does NOT represent
any real business, company, or individual. Generated with a fixed
random seed for full reproducibility.

Output files:
  data/raw/sales_raw.csv          — original generated records
  data/processed/sales_clean.csv  — validated, cleaned records

Usage:
  python scripts/generate_dataset.py

Requirements:
  pip install pandas numpy faker openpyxl
"""

import os
import random
import numpy as np
import pandas as pd
from datetime import date, timedelta

# ── Reproducibility ──────────────────────────────────────────────────────────
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

# ── Output paths ─────────────────────────────────────────────────────────────
BASE_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_PATH   = os.path.join(BASE_DIR, "data", "raw",       "sales_raw.csv")
CLEAN_PATH = os.path.join(BASE_DIR, "data", "processed", "sales_clean.csv")

# ── Lookup tables ─────────────────────────────────────────────────────────────
REGIONS_STATES = {
    "West":    ["California", "Washington", "Oregon", "Nevada", "Arizona",
                "Colorado", "Utah", "Montana", "Idaho", "Wyoming"],
    "East":    ["New York", "Pennsylvania", "New Jersey", "Virginia",
                "Massachusetts", "Connecticut", "Maryland", "North Carolina",
                "Georgia", "Florida"],
    "Central": ["Texas", "Illinois", "Ohio", "Michigan", "Indiana",
                "Wisconsin", "Missouri", "Minnesota", "Iowa", "Kansas"],
    "South":   ["Alabama", "Mississippi", "Louisiana", "Arkansas",
                "Tennessee", "Kentucky", "South Carolina", "West Virginia",
                "Oklahoma", "Delaware"],
}

STATE_CITIES = {
    "California":       ["Los Angeles", "San Francisco", "San Diego", "Sacramento", "Fresno"],
    "Washington":       ["Seattle", "Spokane", "Tacoma", "Bellevue"],
    "Oregon":           ["Portland", "Eugene", "Salem"],
    "Nevada":           ["Las Vegas", "Reno", "Henderson"],
    "Arizona":          ["Phoenix", "Tucson", "Mesa", "Scottsdale"],
    "Colorado":         ["Denver", "Colorado Springs", "Aurora"],
    "Utah":             ["Salt Lake City", "Provo", "Ogden"],
    "Montana":          ["Billings", "Missoula", "Great Falls"],
    "Idaho":            ["Boise", "Nampa", "Meridian"],
    "Wyoming":          ["Cheyenne", "Casper", "Laramie"],
    "New York":         ["New York City", "Buffalo", "Rochester", "Albany"],
    "Pennsylvania":     ["Philadelphia", "Pittsburgh", "Allentown"],
    "New Jersey":       ["Newark", "Jersey City", "Trenton"],
    "Virginia":         ["Virginia Beach", "Norfolk", "Chesapeake", "Richmond"],
    "Massachusetts":    ["Boston", "Worcester", "Springfield"],
    "Connecticut":      ["Bridgeport", "New Haven", "Hartford"],
    "Maryland":         ["Baltimore", "Frederick", "Gaithersburg"],
    "North Carolina":   ["Charlotte", "Raleigh", "Greensboro", "Durham"],
    "Georgia":          ["Atlanta", "Augusta", "Columbus", "Macon"],
    "Florida":          ["Jacksonville", "Miami", "Tampa", "Orlando"],
    "Texas":            ["Houston", "San Antonio", "Dallas", "Austin", "Fort Worth"],
    "Illinois":         ["Chicago", "Aurora", "Rockford", "Joliet"],
    "Ohio":             ["Columbus", "Cleveland", "Cincinnati", "Toledo"],
    "Michigan":         ["Detroit", "Grand Rapids", "Warren", "Sterling Heights"],
    "Indiana":          ["Indianapolis", "Fort Wayne", "Evansville"],
    "Wisconsin":        ["Milwaukee", "Madison", "Green Bay"],
    "Missouri":         ["Kansas City", "St. Louis", "Springfield"],
    "Minnesota":        ["Minneapolis", "Saint Paul", "Rochester"],
    "Iowa":             ["Des Moines", "Cedar Rapids", "Davenport"],
    "Kansas":           ["Wichita", "Overland Park", "Kansas City"],
    "Alabama":          ["Birmingham", "Montgomery", "Huntsville"],
    "Mississippi":      ["Jackson", "Gulfport", "Southaven"],
    "Louisiana":        ["New Orleans", "Baton Rouge", "Shreveport"],
    "Arkansas":         ["Little Rock", "Fort Smith", "Fayetteville"],
    "Tennessee":        ["Nashville", "Memphis", "Knoxville", "Chattanooga"],
    "Kentucky":         ["Louisville", "Lexington", "Bowling Green"],
    "South Carolina":   ["Columbia", "Charleston", "North Charleston"],
    "West Virginia":    ["Charleston", "Huntington", "Parkersburg"],
    "Oklahoma":         ["Oklahoma City", "Tulsa", "Norman"],
    "Delaware":         ["Wilmington", "Dover", "Newark"],
}

SEGMENTS = ["Consumer", "Corporate", "Home Office"]
SEGMENT_WEIGHTS = [0.52, 0.30, 0.18]

SHIP_MODES = ["Second Class", "Standard Class", "First Class", "Same Day"]
SHIP_WEIGHTS = [0.20, 0.60, 0.15, 0.05]

CATEGORIES = {
    "Technology":       {
        "sub_categories": {
            "Phones":       [("Apple iPhone 13", 699, 0.12),
                             ("Samsung Galaxy S21", 649, 0.11),
                             ("Motorola Moto G", 199, 0.08),
                             ("OnePlus 9", 499, 0.10),
                             ("Google Pixel 6", 599, 0.13)],
            "Accessories":  [("Logitech MX Master Mouse", 99, 0.18),
                             ("Anker USB-C Hub", 45, 0.22),
                             ("Belkin Surge Protector", 35, 0.15),
                             ("AmazonBasics HDMI Cable", 12, 0.25),
                             ("TP-Link WiFi Extender", 39, 0.16)],
            "Computers":    [("Dell XPS 15 Laptop", 1299, 0.09),
                             ("HP Spectre x360", 1199, 0.08),
                             ("Lenovo ThinkPad X1", 1099, 0.10),
                             ("Apple MacBook Air M1", 999, 0.11),
                             ("Microsoft Surface Pro 8", 1099, 0.09)],
            "Copiers":      [("Canon PIXMA MG3620", 89, 0.14),
                             ("Epson EcoTank ET-2720", 199, 0.16),
                             ("HP LaserJet Pro M15w", 149, 0.12),
                             ("Brother HL-L2350DW", 129, 0.13),
                             ("Xerox B210 Printer", 169, 0.11)],
        },
        "base_margin": 0.15,
    },
    "Furniture":        {
        "sub_categories": {
            "Chairs":       [("HON Ignition 2.0 Chair", 399, 0.10),
                             ("Ergonomic Mesh Chair", 249, 0.08),
                             ("IKEA MARKUS Chair", 229, 0.06),
                             ("Flash Furniture Gaming Chair", 199, -0.02),
                             ("Modway Articulate Chair", 179, 0.07)],
            "Tables":       [("Sauder Beginnings Desk", 189, 0.05),
                             ("Bush Furniture Cabot Desk", 249, 0.04),
                             ("Safco Products Mayline Desk", 499, 0.03),
                             ("Lifetime 6-Foot Table", 129, -0.03),
                             ("Flash Furniture Folding Table", 99, -0.05)],
            "Bookcases":    [("Bush Furniture Cabot Bookcase", 199, 0.09),
                             ("Sauder 5-Shelf Bookcase", 139, 0.07),
                             ("IKEA BILLY Bookcase", 79, 0.06),
                             ("Prepac 6-Shelf Bookcase", 149, 0.08),
                             ("Mainstays 5-Shelf Bookcase", 59, 0.05)],
            "Furnishings":  [("IKEA RIBBA Frame", 12, 0.20),
                             ("OttLite LED Desk Lamp", 49, 0.18),
                             ("IKEA KALLAX Storage Unit", 99, 0.15),
                             ("Rubbermaid Drawer Organizer", 19, 0.22),
                             ("3M Command Strips", 8, 0.30)],
        },
        "base_margin": 0.05,
    },
    "Office Supplies":  {
        "sub_categories": {
            "Binders":      [("Avery Heavy-Duty Binder", 8, 0.28),
                             ("Wilson Jones View Binder", 6, 0.25),
                             ("Cardinal EasyOpen Binder", 7, 0.30),
                             ("Acco Brands Binder", 5, 0.22),
                             ("Five Star Flex Binder", 9, 0.27)],
            "Paper":        [("Hammermill Copy Plus Paper", 45, 0.20),
                             ("HP Printer Paper 8.5x11", 39, 0.18),
                             ("Amazon Basics Copy Paper", 29, 0.22),
                             ("Georgia-Pacific Copy Paper", 35, 0.19),
                             ("Xerox Vitality Multipurpose Paper", 42, 0.21)],
            "Envelopes":    [("Mead Business Envelopes", 12, 0.35),
                             ("TOPS Business Envelopes", 10, 0.33),
                             ("Quality Park Catalog Envelopes", 14, 0.32),
                             ("Columbian Gummed Flap Envelopes", 8, 0.38),
                             ("Smead Manila File Folders", 9, 0.36)],
            "Art":          [("Fiskars Scissors Set", 15, 0.32),
                             ("Elmer's Glue Sticks", 6, 0.40),
                             ("Scotch Magic Tape", 8, 0.38),
                             ("Sharpie Permanent Markers", 12, 0.35),
                             ("Post-it Notes Variety Pack", 18, 0.37)],
            "Fasteners":    [("Swingline Stapler Combo", 25, 0.28),
                             ("Bostitch Staple Remover", 7, 0.35),
                             ("ACCO Paper Clips", 5, 0.42),
                             ("Pentel EnerGel Pens", 14, 0.33),
                             ("Sharpie Pens Fine Point", 11, 0.31)],
            "Labels":       [("Avery Address Labels 5160", 22, 0.30),
                             ("Amazon Basics Address Labels", 18, 0.28),
                             ("Avery Shipping Labels", 19, 0.29),
                             ("MACO Laser/Inkjet Labels", 16, 0.32),
                             ("Pres-a-ply Address Labels", 14, 0.34)],
            "Supplies":     [("Fellowes Paper Shredder", 89, 0.15),
                             ("Swingline Electric Stapler", 49, 0.20),
                             ("IRIS Weathertight Storage", 35, 0.22),
                             ("Advantus Cubicle Hooks", 12, 0.38),
                             ("Deflect-O Stackable Tray", 18, 0.30)],
            "Storage":      [("Storex Portable File Box", 25, 0.25),
                             ("Bankers Box Stor/File", 18, 0.28),
                             ("Sterilite 3-Drawer Storage", 29, 0.22),
                             ("Fellowes Bankers Box", 22, 0.26),
                             ("Advantus Corrugated Box", 15, 0.30)],
        },
        "base_margin": 0.28,
    },
}

# ── Helper functions ──────────────────────────────────────────────────────────

def random_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


def ship_delay(ship_mode: str) -> int:
    delays = {
        "Same Day":      (0, 1),
        "First Class":   (1, 3),
        "Second Class":  (3, 6),
        "Standard Class":(5, 10),
    }
    lo, hi = delays[ship_mode]
    return random.randint(lo, hi)


def region_for_state(state: str) -> str:
    for region, states in REGIONS_STATES.items():
        if state in states:
            return region
    return "Unknown"


def seasonal_multiplier(order_date: date) -> float:
    """Simulate real-world seasonality: Q4 peak, Q1 dip."""
    month = order_date.month
    season_map = {
        1: 0.75, 2: 0.80, 3: 0.90, 4: 0.95,
        5: 1.00, 6: 1.05, 7: 1.00, 8: 1.05,
        9: 1.10, 10: 1.20, 11: 1.35, 12: 1.30,
    }
    return season_map[month]


# ── Build customer pool ───────────────────────────────────────────────────────
def build_customers(n: int = 800) -> pd.DataFrame:
    first_names = [
        "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael",
        "Linda", "William", "Barbara", "David", "Elizabeth", "Richard",
        "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles", "Karen",
        "Christopher", "Lisa", "Daniel", "Nancy", "Matthew", "Betty",
        "Anthony", "Margaret", "Mark", "Sandra", "Donald", "Ashley",
        "Steven", "Emily", "Paul", "Dorothy", "Andrew", "Kimberly",
        "Joshua", "Carol", "Kenneth", "Michelle", "Kevin", "Amanda",
        "Brian", "Melissa", "George", "Deborah", "Timothy", "Stephanie",
    ]
    last_names = [
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia",
        "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez",
        "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore",
        "Jackson", "Martin", "Lee", "Perez", "Thompson", "White", "Harris",
        "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker",
        "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen",
        "Hill", "Flores", "Green", "Adams", "Nelson", "Baker", "Hall",
        "Rivera", "Campbell", "Mitchell", "Carter", "Roberts",
    ]
    rows = []
    seen = set()
    cid = 1
    while len(rows) < n:
        fn = random.choice(first_names)
        ln = random.choice(last_names)
        name = f"{fn} {ln}"
        if name in seen:
            continue
        seen.add(name)
        seg = random.choices(SEGMENTS, weights=SEGMENT_WEIGHTS)[0]
        rows.append({
            "customer_id":   f"CUST-{cid:04d}",
            "customer_name": name,
            "segment":       seg,
        })
        cid += 1
    return pd.DataFrame(rows)


# ── Build product pool ────────────────────────────────────────────────────────
def build_products() -> pd.DataFrame:
    rows = []
    pid = 1
    for cat, cat_data in CATEGORIES.items():
        for sub, products in cat_data["sub_categories"].items():
            for pname, base_price, base_margin in products:
                rows.append({
                    "product_id":    f"PROD-{pid:04d}",
                    "category":      cat,
                    "sub_category":  sub,
                    "product_name":  pname,
                    "base_price":    base_price,
                    "base_margin":   base_margin,
                })
                pid += 1
    return pd.DataFrame(rows)


# ── Generate orders ───────────────────────────────────────────────────────────
def generate_orders(
    customers: pd.DataFrame,
    products: pd.DataFrame,
    n_records: int = 7500,
    start_date: date = date(2021, 1, 1),
    end_date:   date = date(2023, 12, 31),
) -> pd.DataFrame:

    all_states = [s for states in REGIONS_STATES.values() for s in states]
    # Weight states by rough population proxy
    state_weights = [len(STATE_CITIES.get(s, ["x"])) * 2 for s in all_states]

    rows = []
    order_counter = 1
    row_id = 1

    # Pre-sample some order IDs to share (multi-line orders)
    # Realistic: ~60% of orders have 1 line, 30% have 2, 10% have 3+
    while len(rows) < n_records:
        n_lines = random.choices([1, 2, 3, 4], weights=[55, 25, 15, 5])[0]
        order_id = f"ORD-{2021 + (order_counter % 3)}-{order_counter:05d}"
        order_date = random_date(start_date, end_date)
        ship_mode  = random.choices(SHIP_MODES, weights=SHIP_WEIGHTS)[0]
        ship_date  = order_date + timedelta(days=ship_delay(ship_mode))
        state      = random.choices(all_states, weights=state_weights)[0]
        city       = random.choice(STATE_CITIES.get(state, [state + " City"]))
        region     = region_for_state(state)
        customer   = customers.sample(1).iloc[0]
        mult       = seasonal_multiplier(order_date)

        for _ in range(n_lines):
            if len(rows) >= n_records:
                break
            product = products.sample(1).iloc[0]

            # Quantity: 1–10, skewed low
            qty = random.choices(
                range(1, 11), weights=[30, 25, 18, 10, 7, 4, 3, 1, 1, 1]
            )[0]

            # Discount: mostly 0, sometimes 10–20%, rarely higher
            discount = random.choices(
                [0, 0.05, 0.10, 0.15, 0.20, 0.30, 0.40, 0.50],
                weights=[55, 8, 14, 8, 6, 5, 3, 1],
            )[0]

            # Unit price with seasonal and random noise
            unit_price = round(
                product["base_price"] * mult * random.uniform(0.92, 1.08), 2
            )
            sales = round(unit_price * qty * (1 - discount), 2)

            # Profit: base_margin penalised by discount
            # Heavy discounts often cause losses on low-margin items
            # Factor of 0.6 creates realistic losses only on high discounts
            effective_margin = product["base_margin"] - (discount * 0.6)
            profit = round(sales * effective_margin, 2)

            rows.append({
                "row_id":        row_id,
                "order_id":      order_id,
                "order_date":    order_date,
                "ship_date":     ship_date,
                "ship_mode":     ship_mode,
                "customer_id":   customer["customer_id"],
                "customer_name": customer["customer_name"],
                "segment":       customer["segment"],
                "country":       "United States",
                "state":         state,
                "city":          city,
                "region":        region,
                "product_id":    product["product_id"],
                "category":      product["category"],
                "sub_category":  product["sub_category"],
                "product_name":  product["product_name"],
                "sales":         sales,
                "quantity":      qty,
                "discount":      discount,
                "profit":        profit,
            })
            row_id += 1

        order_counter += 1

    df = pd.DataFrame(rows[:n_records])
    df["order_date"] = pd.to_datetime(df["order_date"])
    df["ship_date"]  = pd.to_datetime(df["ship_date"])
    return df


# ── Save & summarise ──────────────────────────────────────────────────────────
def save_and_summarise(df_raw: pd.DataFrame) -> pd.DataFrame:
    os.makedirs(os.path.dirname(RAW_PATH),   exist_ok=True)
    os.makedirs(os.path.dirname(CLEAN_PATH), exist_ok=True)

    df_raw.to_csv(RAW_PATH, index=False)
    print(f"[✓] Raw dataset saved  → {RAW_PATH}")

    # --- Basic cleaning ---
    df = df_raw.copy()

    # Drop exact duplicates
    before = len(df)
    df = df.drop_duplicates(subset=["row_id"])
    after = len(df)
    print(f"[✓] Duplicate rows removed: {before - after}")

    # Ensure no nulls in critical columns
    critical = ["order_id", "order_date", "ship_date", "customer_id",
                "product_id", "sales", "quantity", "profit"]
    null_counts = df[critical].isnull().sum()
    if null_counts.any():
        print(f"[!] Nulls found:\n{null_counts[null_counts > 0]}")
        df = df.dropna(subset=critical)
    else:
        print("[✓] No nulls in critical columns")

    # Type enforcement
    df["sales"]    = df["sales"].astype(float).round(2)
    df["profit"]   = df["profit"].astype(float).round(2)
    df["quantity"] = df["quantity"].astype(int)
    df["discount"] = df["discount"].astype(float).round(2)

    # Validate ranges
    assert (df["quantity"] >= 1).all(),  "Quantity must be >= 1"
    assert (df["discount"] >= 0).all(),  "Discount must be >= 0"
    assert (df["discount"] <= 1).all(),  "Discount must be <= 1"
    assert (df["sales"]    >  0).all(),  "Sales must be positive"

    df.to_csv(CLEAN_PATH, index=False)
    print(f"[✓] Clean dataset saved → {CLEAN_PATH}")

    # --- Summary stats ---
    print("\n── Dataset Summary ──────────────────────────────────────────")
    print(f"  Total records   : {len(df):,}")
    print(f"  Unique orders   : {df['order_id'].nunique():,}")
    print(f"  Unique customers: {df['customer_id'].nunique():,}")
    print(f"  Unique products : {df['product_id'].nunique():,}")
    print(f"  Date range      : {df['order_date'].min().date()} → {df['order_date'].max().date()}")
    print(f"  Total Sales     : ${df['sales'].sum():,.2f}")
    print(f"  Total Profit    : ${df['profit'].sum():,.2f}")
    print(f"  Profit Margin   : {df['profit'].sum() / df['sales'].sum() * 100:.2f}%")
    print(f"  Loss-making rows: {(df['profit'] < 0).sum():,}")
    print("────────────────────────────────────────────────────────────\n")

    return df


# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 60)
    print("  Sales Performance Dashboard — Dataset Generator")
    print("  SYNTHETIC DATA — not a real business dataset")
    print("=" * 60 + "\n")

    customers = build_customers(800)
    products  = build_products()

    print(f"[✓] Customer pool    : {len(customers)} customers")
    print(f"[✓] Product pool     : {len(products)} products\n")

    df_raw = generate_orders(
        customers,
        products,
        n_records=7500,
        start_date=date(2021, 1, 1),
        end_date=date(2023, 12, 31),
    )

    df_clean = save_and_summarise(df_raw)
    print("[✓] Dataset generation complete.")
