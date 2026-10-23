import pandas as pd
df = pd.read_csv('data/processed/sales_clean.csv')
df['order_date'] = pd.to_datetime(df['order_date'])

print('=== BASELINE METRICS ===')
print('Total Records :', len(df))
print('Total Sales   :', round(df['sales'].sum(), 2))
print('Total Profit  :', round(df['profit'].sum(), 2))
print('Total Qty     :', int(df['quantity'].sum()))
print('Unique Orders :', df['order_id'].nunique())
print('Unique Cust   :', df['customer_id'].nunique())
avg_ov = df.groupby('order_id')['sales'].sum().mean()
print('Avg Order Val :', round(avg_ov, 2))
margin = df['profit'].sum() / df['sales'].sum() * 100
print('Profit Margin :', round(margin, 2), '%')

print('\n=== BY REGION ===')
r = df.groupby('region')[['sales','profit']].sum()
r['margin_pct'] = (r['profit'] / r['sales'] * 100).round(2)
print(r.round(2).to_string())

print('\n=== BY CATEGORY ===')
c = df.groupby('category')[['sales','profit']].sum()
c['margin_pct'] = (c['profit'] / c['sales'] * 100).round(2)
print(c.round(2).to_string())

print('\n=== BY SUB-CATEGORY ===')
sc = df.groupby('sub_category')[['sales','profit']].sum()
sc['margin_pct'] = (sc['profit'] / sc['sales'] * 100).round(2)
print(sc.sort_values('profit', ascending=False).round(2).to_string())

print('\n=== MONTHLY SALES 2023 ===')
df['month'] = df['order_date'].dt.to_period('M')
m23 = df[df['order_date'].dt.year == 2023].groupby('month')[['sales','profit']].sum()
print(m23.round(2).to_string())

print('\n=== TOP 5 BY SALES ===')
print(df.groupby('product_name')['sales'].sum().sort_values(ascending=False).head().round(2).to_string())

print('\n=== TOP 5 BY PROFIT ===')
print(df.groupby('product_name')['profit'].sum().sort_values(ascending=False).head().round(2).to_string())

print('\n=== BOTTOM 5 BY PROFIT ===')
print(df.groupby('product_name')['profit'].sum().sort_values().head().round(2).to_string())

print('\n=== LOSS-MAKING ROWS BY CATEGORY ===')
loss = df[df['profit'] < 0].groupby('category')['profit'].agg(['count','sum'])
print(loss.round(2).to_string())
