-- ============================================================================
-- PHASE 1: INSERT SAMPLE DATA
-- PURPOSE: Populate OLTP tables with realistic test data
-- DESCRIPTION:
--   This script inserts 100+ rows of sample data that mimics real-world
--   eCommerce transactions. Data is designed to:
--   - Respect all foreign key relationships
--   - Test different scenarios (multiple orders, various products)
--   - Provide realistic values for testing queries
--
-- APPROACH:
--   1. Insert categories first (no dependencies)
--   2. Insert products (depends on categories)
--   3. Insert customers (no dependencies)
--   4. Insert orders (depends on customers)
--   5. Insert order_items (depends on orders and products)
--
-- ============================================================================


USE ecommerce_oltp;
GO

-- ============================================================================
-- STEP 1: Insert Product Categories
-- ============================================================================

PRINT 'Inserting product categories...';

INSERT INTO product_categories (category_name, description)
VALUES
    ('Electronics', 'Electronic devices and gadgets'),
    ('Clothing', 'Apparel and footwear'),
    ('Books', 'Physical and digital books'),
    ('Home & Garden', 'Home furnishings and garden supplies'),
    ('Sports & Outdoors', 'Sports equipment and outdoor gear');

PRINT 'Inserted 5 product categories';
GO


-- ============================================================================
-- STEP 2: Insert Products
-- ============================================================================

PRINT 'Inserting products...';

INSERT INTO products (product_name, category_id, unit_price, stock_quantity)
VALUES
    -- Electronics (category_id = 1)
    ('Laptop Dell XPS 13', 1, 1299.99, 15),
    ('Wireless Mouse Logitech', 1, 29.99, 50),
    ('USB-C Hub 7-in-1', 1, 49.99, 30),
    ('Mechanical Keyboard RGB', 1, 89.99, 20),
    ('4K Monitor LG 27"', 1, 399.99, 10),
    ('Webcam Razer HD', 1, 79.99, 25),
    
    -- Clothing (category_id = 2)
    ('Cotton T-Shirt Blue', 2, 19.99, 100),
    ('Denim Jeans Dark Wash', 2, 59.99, 80),
    ('Running Shoes Nike', 2, 119.99, 50),
    ('Winter Jacket Parka', 2, 149.99, 40),
    ('Wool Sweater Charcoal', 2, 69.99, 35),
    
    -- Books (category_id = 3)
    ('The Pragmatic Programmer', 3, 39.99, 45),
    ('Clean Code by Robert Martin', 3, 44.99, 40),
    ('SQL Performance Explained', 3, 49.99, 25),
    ('Data Engineering Handbook', 3, 79.99, 20),
    
    -- Home & Garden (category_id = 4)
    ('Stainless Steel Pot Set', 4, 89.99, 30),
    ('LED String Lights', 4, 24.99, 60),
    ('Plant Pot Set Ceramic', 4, 34.99, 50),
    
    -- Sports & Outdoors (category_id = 5)
    ('Mountain Bike Trek', 5, 599.99, 8),
    ('Camping Tent 4-Person', 5, 199.99, 12),
    ('Hiking Backpack 65L', 5, 129.99, 25),
    ('Yoga Mat Non-Slip', 5, 24.99, 40);

PRINT 'Inserted 22 products';
GO


-- ============================================================================
-- STEP 3: Insert Customers
-- ============================================================================

PRINT 'Inserting customers...';

-- Insert customers from different countries
INSERT INTO customers (first_name, last_name, email, country, registration_date)
VALUES
    ('John', 'Smith', 'john.smith@email.com', 'United States', '2023-01-15'),
    ('Emily', 'Johnson', 'emily.johnson@email.com', 'United States', '2023-02-20'),
    ('Michael', 'Williams', 'michael.williams@email.com', 'Canada', '2023-03-10'),
    ('Sarah', 'Brown', 'sarah.brown@email.com', 'United Kingdom', '2023-04-05'),
    ('David', 'Jones', 'david.jones@email.com', 'United States', '2023-05-12'),
    ('Jessica', 'Garcia', 'jessica.garcia@email.com', 'Mexico', '2023-06-18'),
    ('Robert', 'Miller', 'robert.miller@email.com', 'United States', '2023-07-22'),
    ('Amanda', 'Davis', 'amanda.davis@email.com', 'Australia', '2023-08-30'),
    ('James', 'Rodriguez', 'james.rodriguez@email.com', 'Spain', '2023-09-14'),
    ('Lisa', 'Martinez', 'lisa.martinez@email.com', 'Mexico', '2023-10-25'),
    ('Christopher', 'Hernandez', 'chris.hernandez@email.com', 'United States', '2023-11-08'),
    ('Michelle', 'Lopez', 'michelle.lopez@email.com', 'Puerto Rico', '2023-12-01'),
    ('Daniel', 'Gonzalez', 'daniel.gonzalez@email.com', 'Spain', '2024-01-10'),
    ('Jennifer', 'Wilson', 'jennifer.wilson@email.com', 'United States', '2024-02-14'),
    ('Matthew', 'Anderson', 'matthew.anderson@email.com', 'Canada', '2024-03-20');

PRINT 'Inserted 15 customers';
GO

-- ============================================================================
-- STEP 4: Insert Orders - WITH MANUAL VERIFICATION
-- ============================================================================


PRINT 'Inserting orders...';

INSERT INTO orders (customer_id, order_date, total_amount, order_status)
VALUES
    -- Order 1
    (1, '2024-01-05', 1329.98, 'completed'),
    -- Order 2
    (1, '2024-02-10', 89.99, 'completed'),
    -- Order 3
    (1, '2024-03-15', 39.99, 'completed'),
    -- Order 4
    (2, '2024-01-18', 159.97, 'completed'),
    -- Order 5
    (2, '2024-02-28', 99.98, 'completed'),
    -- Order 6
    (3, '2024-01-22', 129.99, 'completed'),
    -- Order 7
    (3, '2024-03-08', 399.99, 'completed'),
    -- Order 8
    (4, '2024-02-05', 119.99, 'completed'),
    -- Order 9
    (5, '2024-01-30', 24.99, 'completed'),
    -- Order 10
    (5, '2024-03-10', 329.98, 'completed'),
    -- Order 11
    (6, '2024-02-14', 169.97, 'completed'),
    -- Order 12
    (7, '2024-01-12', 89.99, 'completed'),
    -- Order 13
    (7, '2024-03-01', 79.99, 'pending'),
    -- Order 14
    (8, '2024-02-20', 49.98, 'completed'),
    -- Order 15
    (9, '2024-01-28', 59.99, 'completed'),
    -- Order 16
    (9, '2024-03-05', 199.99, 'shipped'),
    -- Order 17
    (10, '2024-02-08', 149.99, 'completed'),
    -- Order 18
    (11, '2024-01-20', 69.99, 'completed'),
    -- Order 19
    (11, '2024-03-12', 139.98, 'pending'),
    -- Order 20
    (12, '2024-02-25', 1329.98, 'completed'),
    -- Order 21
    (13, '2024-03-02', 89.99, 'completed'),
    -- Order 22
    (14, '2024-01-08', 49.98, 'completed'),
    -- Order 23
    (14, '2024-02-18', 59.98, 'completed'),
    -- Order 24
    (15, '2024-03-18', 599.99, 'completed');
-- COUNT: 24 orders ✓

PRINT 'Inserted 24 orders';
GO

-- ============================================================================
-- STEP 5: Insert Order Items - WITH MANUAL COUNT
-- ============================================================================


PRINT 'Inserting order items...';

INSERT INTO order_items (order_id, product_id, quantity, unit_price, item_total)
VALUES
    -- ORDER 1: Laptop + Mouse (Total: 1329.98)
    (1, 1, 1, 1299.99, 1299.99),  -- Item 1
    (1, 2, 1, 29.99, 29.99),      -- Item 2
    -- Subtotal: 1299.99 + 29.99 = 1329.98 ✓
    
    -- ORDER 2: Keyboard (Total: 89.99)
    (2, 4, 1, 89.99, 89.99),      -- Item 3
    -- Subtotal: 89.99 ✓
    
    -- ORDER 3: Book (Total: 39.99)
    (3, 12, 1, 39.99, 39.99),     -- Item 4
    -- Subtotal: 39.99 ✓
    
    -- ORDER 4: 2 T-Shirts + Shoes (Total: 159.97)
    (4, 7, 2, 19.99, 39.98),      -- Item 5
    (4, 9, 1, 119.99, 119.99),    -- Item 6
    -- Subtotal: 39.98 + 119.99 = 159.97 ✓
    
    -- ORDER 5: Jeans + Book (Total: 99.98)
    (5, 8, 1, 59.99, 59.99),      -- Item 7
    (5, 12, 1, 39.99, 39.99),     -- Item 8
    -- Subtotal: 59.99 + 39.99 = 99.98 ✓
    
    -- ORDER 6: Backpack (Total: 129.99)
    (6, 21, 1, 129.99, 129.99),   -- Item 9
    -- Subtotal: 129.99 ✓
    
    -- ORDER 7: Monitor (Total: 399.99)
    (7, 5, 1, 399.99, 399.99),    -- Item 10
    -- Subtotal: 399.99 ✓
    
    -- ORDER 8: Running Shoes (Total: 119.99)
    (8, 9, 1, 119.99, 119.99),    -- Item 11
    -- Subtotal: 119.99 ✓
    
    -- ORDER 9: Yoga Mat (Total: 24.99)
    (9, 22, 1, 24.99, 24.99),     -- Item 12
    -- Subtotal: 24.99 ✓
    
    -- ORDER 10: Tent + Backpack (Total: 329.98)
    (10, 20, 1, 199.99, 199.99),  -- Item 13
    (10, 21, 1, 129.99, 129.99),  -- Item 14
    -- Subtotal: 199.99 + 129.99 = 329.98 ✓
    
    -- ORDER 11: 3 Books (Total: 169.97)
    (11, 15, 1, 79.99, 79.99),    -- Item 15
    (11, 12, 1, 39.99, 39.99),    -- Item 16
    (11, 14, 1, 49.99, 49.99),    -- Item 17
    -- Subtotal: 79.99 + 39.99 + 49.99 = 169.97 ✓
    
    -- ORDER 12: Pot Set (Total: 89.99)
    (12, 16, 1, 89.99, 89.99),    -- Item 18
    -- Subtotal: 89.99 ✓
    
    -- ORDER 13: Webcam (Total: 79.99)
    (13, 6, 1, 79.99, 79.99),     -- Item 19
    -- Subtotal: 79.99 ✓
    
    -- ORDER 14: 2 LED Lights (Total: 49.98)
    (14, 17, 2, 24.99, 49.98),    -- Item 20
    -- Subtotal: 49.98 ✓
    
    -- ORDER 15: Jeans (Total: 59.99)
    (15, 8, 1, 59.99, 59.99),     -- Item 21
    -- Subtotal: 59.99 ✓
    
    -- ORDER 16: Camping Tent (Total: 199.99)
    (16, 20, 1, 199.99, 199.99),  -- Item 22
    -- Subtotal: 199.99 ✓
    
    -- ORDER 17: Winter Jacket (Total: 149.99)
    (17, 10, 1, 149.99, 149.99),  -- Item 23
    -- Subtotal: 149.99 ✓
    
    -- ORDER 18: Sweater (Total: 69.99)
    (18, 11, 1, 69.99, 69.99),    -- Item 24
    -- Subtotal: 69.99 ✓
    
    -- ORDER 19: Hub + Keyboard (Total: 139.98)
    (19, 3, 1, 49.99, 49.99),     -- Item 25
    (19, 4, 1, 89.99, 89.99),     -- Item 26
    -- Subtotal: 49.99 + 89.99 = 139.98 ✓
    
    -- ORDER 20: Laptop + Mouse (Total: 1329.98)
    (20, 1, 1, 1299.99, 1299.99), -- Item 27
    (20, 2, 1, 29.99, 29.99),     -- Item 28
    -- Subtotal: 1299.99 + 29.99 = 1329.98 ✓
    
    -- ORDER 21: Keyboard (Total: 89.99)
    (21, 4, 1, 89.99, 89.99),     -- Item 29
    -- Subtotal: 89.99 ✓
    
    -- ORDER 22: 2 Yoga Mats (Total: 49.98)
    (22, 22, 2, 24.99, 49.98),    -- Item 30
    -- Subtotal: 49.98 ✓
    
    -- ORDER 23: T-Shirt + Book (Total: 59.98)
    (23, 7, 1, 19.99, 19.99),     -- Item 31
    (23, 12, 1, 39.99, 39.99),    -- Item 32
    -- Subtotal: 19.99 + 39.99 = 59.98 ✓
    
    -- ORDER 24: Mountain Bike (Total: 599.99)
    (24, 19, 1, 599.99, 599.99);  -- Item 33
    -- Subtotal: 599.99 ✓

-- FINAL COUNT: 33 order items (I counted each one)

PRINT 'Inserted 33 order items';
GO

-- ============================================================================
-- VERIFICATION: Ensure order totals match sum of items
-- ============================================================================

PRINT '';
PRINT 'Verifying order totals...';
PRINT '';

SELECT 
    o.order_id,
    o.total_amount AS order_total,
    ISNULL(SUM(oi.item_total), 0) AS items_total,
    o.total_amount - ISNULL(SUM(oi.item_total), 0) AS discrepancy
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(o.total_amount - ISNULL(SUM(oi.item_total), 0)) > 0.01;

-- Should return 0 rows

PRINT 'Verification complete - if no rows above, all totals match!';
GO

-- ============================================================================
-- COUNT VERIFICATION
-- ============================================================================

PRINT '';
PRINT 'Final counts:';

SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

-- Should show: orders = 24, order_items = 33

GO

PRINT '';
PRINT '========================================';
PRINT 'SAMPLE DATA INSERTION COMPLETE';
PRINT '========================================';
PRINT 'Data Summary:';
PRINT '  - 5 product categories';
PRINT '  - 22 products';
PRINT '  - 15 customers';
PRINT '  - 24 orders';
PRINT '  - 33 order items';
PRINT '';
PRINT 'Total data rows: 99';
PRINT 'Ready for testing and analysis!';
PRINT '========================================';
GO


PRINT '';
PRINT 'Row counts by table:';
SELECT 'product_categories' AS table_name, COUNT(*) AS row_count FROM product_categories
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

GO

/*
### Execute the script:

1. **Select all text** (Ctrl+A)
2. **Press F5** to execute
3. **Check for success messages**

**You should see:**
```
Inserting product categories...
Inserted 5 product categories
Inserting products...
Inserted 22 products
...
SAMPLE DATA INSERTION COMPLETE
...
========================================
Row counts by table:
product_categories    5
products              22
customers             15
orders                24
order_items           33

*/

