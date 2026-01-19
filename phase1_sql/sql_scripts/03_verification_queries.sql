-- ============================================================================
-- PHASE 1: DATA VERIFICATION & INTEGRITY CHECKS
-- PURPOSE: Verify that sample data loaded correctly and referential integrity
--          is maintained
-- DESCRIPTION:
--   These queries help you:
--   1. Confirm row counts match expectations
--   2. Check for orphaned records (orders without customers, etc.)
--   3. Verify data types and constraints
--   4. Spot any data quality issues
--
-- ============================================================================

USE ecommerce_oltp;
GO

PRINT '========================================';
PRINT 'DATA VERIFICATION CHECKS';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- CHECK 1: Row Counts
-- ============================================================================

PRINT 'CHECK 1: Row Counts (should be >0)';
PRINT '---';

SELECT 'product_categories' AS table_name, COUNT(*) AS row_count FROM product_categories
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

PRINT '';

-- ============================================================================
-- CHECK 2: Orphaned Orders (orders with non-existent customers)
-- ============================================================================

PRINT 'CHECK 2: Orphaned Orders (should return 0 rows)';
PRINT '---';
PRINT 'If this query returns ANY rows, there is a data integrity problem!';
PRINT '';

SELECT o.order_id, o.customer_id, 'ORPHANED - Customer does not exist' AS issue
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

IF @@ROWCOUNT = 0
    PRINT 'Result: No orphaned orders found ✓';
ELSE
    PRINT 'Result: PROBLEM - Orphaned orders found!';

PRINT '';

-- ============================================================================
-- CHECK 3: Orphaned Order Items (items with non-existent orders/products)
-- ============================================================================

PRINT 'CHECK 3: Orphaned Order Items (should return 0 rows)';
PRINT '---';

SELECT oi.order_item_id, 
       CASE 
           WHEN o.order_id IS NULL THEN 'ORPHANED - Order does not exist'
           WHEN p.product_id IS NULL THEN 'ORPHANED - Product does not exist'
       END AS issue
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE o.order_id IS NULL OR p.product_id IS NULL;

IF @@ROWCOUNT = 0
    PRINT 'Result: No orphaned order items found ✓';
ELSE
    PRINT 'Result: PROBLEM - Orphaned order items found!';

PRINT '';

-- ============================================================================
-- CHECK 4: Orphaned Products (products with non-existent categories)
-- ============================================================================

PRINT 'CHECK 4: Orphaned Products (should return 0 rows)';
PRINT '---';

SELECT p.product_id, p.product_name, p.category_id
FROM products p
LEFT JOIN product_categories pc ON p.category_id = pc.category_id
WHERE pc.category_id IS NULL;

IF @@ROWCOUNT = 0
    PRINT 'Result: No orphaned products found ✓';
ELSE
    PRINT 'Result: PROBLEM - Orphaned products found!';

PRINT '';

-- ============================================================================
-- CHECK 5: Data Quality - Negative Amounts (should return 0 rows)
-- ============================================================================

PRINT 'CHECK 5: Data Quality - Negative Amounts (should return 0)';
PRINT '---';

SELECT order_id, total_amount
FROM orders
WHERE total_amount < 0
UNION ALL
SELECT o.order_id, oi.item_total
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE oi.item_total < 0;

IF @@ROWCOUNT = 0
    PRINT 'Result: No negative amounts found ✓';
ELSE
    PRINT 'Result: PROBLEM - Negative amounts found!';

PRINT '';

-- ============================================================================
-- CHECK 6: Data Sample - Show a complete order with all details
-- ============================================================================

PRINT 'CHECK 6: Sample Data - Complete Order Example';
PRINT '---';
PRINT 'This shows one order with all related data (customer, items, products):';
PRINT '';

SELECT
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.email,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_status,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.item_total,
    pc.category_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_categories pc ON p.category_id = pc.category_id
WHERE o.order_id = 1  -- Show order #1
ORDER BY oi.order_item_id;

PRINT '';

-- ============================================================================
-- CHECK 7: Summary Statistics
-- ============================================================================

PRINT 'CHECK 7: Summary Statistics';
PRINT '---';

SELECT
    'Total Orders' AS metric,
    CAST(COUNT(*) AS VARCHAR) AS value
FROM orders
UNION ALL
SELECT 'Total Items Ordered', CAST(COUNT(*) AS VARCHAR) FROM order_items
UNION ALL
SELECT 'Total Revenue', CAST(SUM(total_amount) AS VARCHAR) FROM orders
UNION ALL
SELECT 'Average Order Value', CAST(AVG(total_amount) AS VARCHAR) FROM orders
UNION ALL
SELECT 'Highest Order Amount', CAST(MAX(total_amount) AS VARCHAR) FROM orders
UNION ALL
SELECT 'Lowest Order Amount', CAST(MIN(total_amount) AS VARCHAR) FROM orders
UNION ALL
SELECT 'Number of Customers', CAST(COUNT(DISTINCT customer_id) AS VARCHAR) FROM orders;

PRINT '';

PRINT '========================================';
PRINT 'VERIFICATION COMPLETE';
PRINT '========================================';
PRINT 'If all checks passed, your OLTP schema is ready! ✓';

GO

/*
### Execute the script:

1. **Select all text** (Ctrl+A)
2. **Press F5**
3. **Review the results carefully**

**Expected Output:**
- All checks should show "0 rows" for problems
- Row counts should match data inserted (5, 22, 15, 24, 34)
- Sample order should show complete data
- Summary statistics should be reasonable

## CHECKPOINT 1.2: OLTP Schema Complete

**Before moving to Section 1.3, verify:**


-- Run this quick check in SSMS
USE ecommerce_oltp;
SELECT COUNT(*) as table_count FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

-- Should return: 5

*/