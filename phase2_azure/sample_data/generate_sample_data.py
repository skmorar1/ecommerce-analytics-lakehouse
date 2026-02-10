import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

np.random.seed(42)
random.seed(42)

print("Generating sample data...\n")

# =============================================
# 1. CUSTOMERS
# =============================================

customer_ids = range(1, 101)  # 100 customers
regions = ['North', 'South', 'East', 'West']
statuses = ['Active', 'Inactive', 'Churned']

customers_data = {
    'customer_id': customer_ids,
    'customer_name': [f'Customer_{i}' for i in customer_ids],
    'email': [f'customer{i}@company.com' for i in customer_ids],
    'region': [random.choice(regions) for _ in customer_ids],
    'status': [random.choice(statuses) for _ in customer_ids],
    'customer_lifetime_value': np.random.uniform(100, 50000, len(customer_ids)),
    'created_date': [
        (datetime.now() - timedelta(days=random.randint(1, 365))).strftime('%Y-%m-%d %H:%M:%S')
        for _ in customer_ids
    ],
    'updated_date': [
        (datetime.now() - timedelta(days=random.randint(0, 30))).strftime('%Y-%m-%d %H:%M:%S')
        for _ in customer_ids
    ]
}

df_customers = pd.DataFrame(customers_data)
df_customers.to_csv('phase2_azure/sample_data/customers_full.csv', index=False)
print(f"Done - Created customers_full.csv ({len(df_customers)} rows)")


# =============================================
# 2. PRODUCTS
# =============================================

product_ids = range(1, 51)  # 50 products
categories = ['Electronics', 'Clothing', 'Home & Garden', 'Sports', 'Books']

products_data = {
    'product_id': product_ids,
    'product_name': [f'Product_{i}' for i in product_ids],
    'category': [random.choice(categories) for _ in product_ids],
    'unit_price': np.random.uniform(10, 500, len(product_ids)),
    'stock_quantity': np.random.randint(0, 1000, len(product_ids)),
    'created_date': [
        (datetime.now() - timedelta(days=random.randint(1, 365))).strftime('%Y-%m-%d %H:%M:%S')
        for _ in product_ids
    ],
    'updated_at': [
        (datetime.now() - timedelta(days=random.randint(0, 30))).strftime('%Y-%m-%d %H:%M:%S')
        for _ in product_ids
    ]
}

df_products = pd.DataFrame(products_data)
df_products.to_csv('phase2_azure/sample_data/products_full.csv', index=False)
print(f"Done - Created products_full.csv ({len(df_products)} rows)")

# =============================================
# 3. ORDERS
# =============================================

order_ids = range(1, 501)  # 500 orders
order_statuses = ['Completed', 'Pending', 'Cancelled', 'Shipped']
quantities = np.random.randint(1, 10, len(order_ids))
unit_prices = np.random.uniform(10, 200, len(order_ids)).round(2)


orders_data = {
    'order_id': order_ids,
    'customer_id': [random.randint(1, 100) for _ in order_ids],
    'product_id': [random.randint(1, 50) for _ in order_ids],
    'order_date': [
        (datetime.now() - timedelta(days=random.randint(1, 180))).strftime('%Y-%m-%d %H:%M:%S')
        for _ in order_ids
    ],

    'quantity': quantities,
    'unit_price': unit_prices,

    'order_amount': [round(q * p, 2) for q, p in zip(quantities, unit_prices)],
    'order_status': [random.choice(order_statuses) for _ in order_ids],
    'last_modified_date': [
        (datetime.now() - timedelta(days=random.randint(0, 30))).strftime('%Y-%m-%d %H:%M:%S')
        for _ in order_ids
    ]
}

df_orders = pd.DataFrame(orders_data)
today = datetime.now().strftime('%Y-%m-%d')
orders_file = f'phase2_azure/sample_data/orders_{today}.csv'
df_orders.to_csv(orders_file, index=False)
print(f"Done - Created {orders_file} ({len(df_orders)} rows)")

print("\n" + "="*50)
print("Sample data generation complete!")
print("="*50)
print("Next: Upload to Azure Storage (/raw container)")
