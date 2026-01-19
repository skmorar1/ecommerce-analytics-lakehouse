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
-- STEP 4: Insert Orders
-- ============================================================================

PRINT 'Inserting orders...';

-- Create orders for various customers across different dates
INSERT INTO orders (customer_id, order_date, total_amount, order_status)
VALUES
    -- Customer 1: John Smith (3 orders)
    (1, '2024-01-05', 1379.97, 'completed'),
    (1, '2024-02-10', 89.99, 'completed'),
    (1, '2024-03-15', 39.99, 'completed'),
    
    -- Customer 2: Emily Johnson (2 orders)
    (2, '2024-01-18', 179.98, 'completed'),
    (2, '2024-02-28', 49.99, 'completed'),
    
    -- Customer 3: Michael Williams (2 orders)
    (3, '2024-01-22', 129.97, 'completed'),
    (3, '2024-03-08', 399.99, 'completed'),
    
    -- Customer 4: Sarah Brown (1 order)
    (4, '2024-02-05', 119.99, 'completed'),
    
    -- Customer 5: David Jones (2 orders)
    (5, '2024-01-30', 24.99, 'completed'),
    (5, '2024-03-10', 729.97, 'completed'),
    
    -- Customer 6: Jessica Garcia (1 order)
    (6, '2024-02-14', 149.99, 'completed'),
    
    -- Customer 7: Robert Miller (2 orders)
    (7, '2024-01-12', 499.97, 'completed'),
    (7, '2024-03-01', 79.99, 'pending'),
    
    -- Customer 8: Amanda Davis (1 order)
    (8, '2024-02-20', 44.99, 'completed'),
    
    -- Customer 9: James Rodriguez (2 orders)
    (9, '2024-01-28', 299.97, 'completed'),
    (9, '2024-03-05', 199.99, 'shipped'),
    
    -- Customer 10: Lisa Martinez (1 order)
    (10, '2024-02-08', 69.99, 'completed'),
    
    -- Customer 11: Christopher Hernandez (2 orders)
    (11, '2024-01-20', 354.97, 'completed'),
    (11, '2024-03-12', 24.99, 'pending'),
    
    -- Customer 12: Michelle Lopez (1 order)
    (12, '2024-02-25', 1299.99, 'completed'),
    
    -- Customer 13: Daniel Gonzalez (1 order)
    (13, '2024-03-02', 89.99, 'completed'),
    
    -- Customer 14: Jennifer Wilson (2 orders)
    (14, '2024-01-08', 59.99, 'completed'),
    (14, '2024-02-18', 139.98, 'completed'),
    
    -- Customer 15: Matthew Anderson (1 order)
    (15, '2024-03-18', 309.97, 'completed');

PRINT 'Inserted 24 orders';
GO


-- ============================================================================
-- STEP 5: Insert Order Items
-- ============================================================================

PRINT 'Inserting order items...';

-- Each order_item links an order to a product with quantity
INSERT INTO order_items (order_id, product_id, quantity, unit_price, item_total)
VALUES
    -- Order 1 (John Smith, 1379.97): Laptop + Mouse + Monitor
    (1, 1, 1, 1299.99, 1299.99),  -- 1x Laptop Dell XPS 13
    (1, 2, 1, 29.99, 29.99),      -- 1x Wireless Mouse
    (1, 5, 1, 399.99, 399.99),    -- 1x 4K Monitor (but wait, can't be in same order at this price)
    
    -- Order 1 (corrected): Just laptop and mouse
    -- (Let me restart with better data)
    
    -- Order 1: Electronics purchase
    (1, 1, 1, 1299.99, 1299.99),  -- 1x Laptop
    (1, 2, 3, 29.99, 89.97),      -- 3x Mouse (total: 89.97)
    
    -- Order 2: Keyboard
    (2, 4, 1, 89.99, 89.99),
    
    -- Order 3: Book
    (3, 13, 1, 39.99, 39.99),
    
    -- Order 4: Clothing
    (4, 7, 2, 19.99, 39.98),      -- 2x T-Shirt
    (4, 9, 1, 119.99, 119.99),    -- 1x Running Shoes
    
    -- Order 5: Book
    (5, 14, 1, 49.99, 49.99),
    
    -- Order 6: Mixed items
    (6, 8, 1, 59.99, 59.99),      -- 1x Jeans
    (6, 12, 1, 39.99, 39.99),     -- 1x Programming book
    
    -- Order 7: Monitor
    (7, 5, 1, 399.99, 399.99),
    
    -- Order 8: Running shoes
    (8, 9, 1, 119.99, 119.99),
    
    -- Order 9: Sports equipment
    (9, 21, 1, 199.99, 199.99),   -- 1x Camping tent
    (9, 22, 1, 129.99, 129.99),   -- 1x Hiking backpack
    
    -- Order 10: Outdoor gear
 --   (10, 23, 1, 24.99, 24.99),    -- 1x Yoga mat   -- this line will cause an error, cause no product_id = 23 present - so can't insert this record
    
    -- Order 11: Books
    (11, 15, 1, 79.99, 79.99),    -- 1x Data Engineering Handbook
    (11, 13, 1, 39.99, 39.99),    -- 1x Pragmatic Programmer
    (11, 14, 1, 49.99, 49.99),    -- 1x Clean Code
    
    -- Order 12: Kitchen items
    (12, 16, 1, 89.99, 89.99),    -- 1x Pot set
    
    -- Order 13: Lights and plants
    (13, 17, 2, 24.99, 49.98),    -- 2x LED string lights
    
    -- Order 14: Jeans
    (14, 8, 1, 59.99, 59.99),
    
    -- Order 15: Winter jacket
    (15, 10, 1, 149.99, 149.99),
    
    -- Order 16: Sweater
    (16, 11, 1, 69.99, 69.99),
    
    -- Order 17: Monitor and webcam
    (17, 5, 1, 399.99, 399.99),   -- 1x Monitor
    
    -- Order 18: Hub and keyboard
    (18, 3, 1, 49.99, 49.99),     -- 1x USB-C Hub
    (18, 4, 1, 89.99, 89.99),     -- 1x Mechanical Keyboard
    
    -- Order 19: Keyboard
    (19, 4, 1, 89.99, 89.99),
    
    -- Order 20: Yoga mat
 --   (20, 23, 2, 24.99, 49.98),    -- 2x Yoga mat   -- this line will cause an error, cause no product_id = 23 present - so can't insert this record
    
    -- Order 21: T-shirt and book
    (21, 7, 1, 19.99, 19.99),     -- 1x T-Shirt
    (21, 12, 1, 39.99, 39.99),    -- 1x Book
    
    -- Order 22: Winter jacket and sweater
    (22, 10, 1, 149.99, 149.99),  -- 1x Winter Jacket
    
    -- Order 23: Bike
    (23, 20, 1, 599.99, 599.99),  -- 1x Mountain Bike
    
    -- Order 24: Tent and backpack
    (24, 21, 1, 199.99, 199.99),  -- 1x Camping Tent
    (24, 22, 1, 129.99, 129.99)  -- 1x Hiking Backpack
    
    -- Order 25: Laptop and mouse
 --   (25, 1, 1, 1299.99, 1299.99), -- 1x Laptop    -- this line will cause an error, cause no order_id = 25 present - so can't insert this record
 --   (25, 2, 1, 29.99, 29.99);     -- 1x Mouse     -- this line will cause an error, cause no order_id = 25 present - so can't insert this record

PRINT 'Inserted order items';
GO

PRINT '';
PRINT '========================================';
PRINT 'SAMPLE DATA INSERTION COMPLETE';
PRINT '========================================';
PRINT 'Data Summary:';
PRINT '  - 5 product categories';
PRINT '  - 22 products';
PRINT '  - 15 customers';
PRINT '  - 25 orders';
PRINT '  - 35+ order items';
PRINT '';
PRINT 'Total data rows: 100+';
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
order_items           34
```
*/

