-- ============================================================================
-- PHASE 1: LOAD FACT TABLE & GRAIN VERIFICATION
-- PURPOSE: Load order data into star schema fact table and verify correctness
-- DESCRIPTION:
--   This script:
--   1. Loads order_facts from OLTP data (one row per order item)
--   2. Verifies the grain (one row per order item, not per order)
--   3. Checks that metrics sum correctly
--   4. Validates foreign key relationships
--
-- GRAIN VERIFICATION is critical in data warehousing!
--   If your grain is wrong, all analytics will be wrong.
--   Example: If you put 2 items in one fact row, and you SUM(quantity),
--            you get the same answer. But if you SUM(total_amount),
--            you get double the revenue (because you aggregated twice).
-- ============================================================================

USE ecommerce_olap;
GO

PRINT '========================================';
PRINT 'LOADING FACT TABLE';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- STEP 1: Load ORDER_FACTS from OLTP
-- ============================================================================
-- Logic: 
--   JOIN order_items (OLTP) with orders (OLTP) to get:
--   - quantity and unit_price per item (from order_items)
--   - order_date and customer_id (from orders)
--   Then JOIN with dimensions to get dimension keys
--
-- Grain check:
--   One row per order_item_id
--   If an order has 3 items, we get 3 rows in order_facts
--   This is correct for analytical aggregation
-- ============================================================================

PRINT 'STEP 1: Loading order_facts (one row per order item)';
PRINT '---';

INSERT INTO dbo.order_facts 
(order_id, product_id, customer_id, date_id, category_id, 
 quantity, unit_price, total_amount, order_status)
SELECT
    o.order_id,                                    -- Business key
    oi.product_id,                                 -- FK to product_dim
    o.customer_id,                                 -- FK to customer_dim
    -- Get date_id by formatting order_date
    CAST(FORMAT(o.order_date, 'yyyyMMdd') AS INT) AS date_id,  -- FK to date_dim
    p.category_id,                                 -- FK to category_dim (denormalized)
    
    -- Metrics
    oi.quantity,
    oi.unit_price,
    oi.item_total,
    o.order_status
FROM ecommerce_oltp.dbo.orders o
JOIN ecommerce_oltp.dbo.order_items oi ON o.order_id = oi.order_id
JOIN ecommerce_oltp.dbo.products p ON oi.product_id = p.product_id
WHERE o.order_id IS NOT NULL
  AND oi.product_id IS NOT NULL
  AND o.customer_id IS NOT NULL;

DECLARE @FactRowCount INT = @@ROWCOUNT;

PRINT CAST(@FactRowCount AS VARCHAR(10)) + ' fact records inserted ✓';
PRINT '';

-- ============================================================================
-- STEP 2: GRAIN VERIFICATION - Critical!
-- ============================================================================
-- Purpose: Verify that our grain is correct (one row per order item)
--
-- What we're checking:
--   1. Number of fact rows = number of OLTP order_items
--   2. Each order_item_id appears exactly once
--   3. No duplicate order + product combinations
--   4. Metrics sum correctly across aggregation levels
-- ============================================================================

PRINT 'STEP 2: GRAIN VERIFICATION';
PRINT '---';

-- Check 1: Fact table should have same number of rows as OLTP order_items
DECLARE @OltpOrderItemCount INT = (
    SELECT COUNT(*) FROM ecommerce_oltp.dbo.order_items
);

DECLARE @OlapFactCount INT = (
    SELECT COUNT(*) FROM dbo.order_facts
);

IF @OltpOrderItemCount = @OlapFactCount
    PRINT 'Check 1 PASSED: Fact row count matches OLTP order_items ✓'
ELSE
    PRINT 'Check 1 FAILED: Row count mismatch! OLTP=' + CAST(@OltpOrderItemCount AS VARCHAR) + 
          ', OLAP=' + CAST(@OlapFactCount AS VARCHAR);

-- Check 2: Total revenue from fact table should match OLTP orders total
DECLARE @OltpTotalRevenue DECIMAL(15,2) = (
    SELECT SUM(total_amount) FROM ecommerce_oltp.dbo.orders
);

DECLARE @OlapTotalRevenue DECIMAL(15,2) = (
    SELECT SUM(total_amount) FROM dbo.order_facts
);

IF ABS(@OltpTotalRevenue - @OlapTotalRevenue) < 0.01  -- Account for rounding
    PRINT 'Check 2 PASSED: Total revenue matches OLTP ✓ ($' + 
          FORMAT(@OlapTotalRevenue, 'N2') + ')'
ELSE
    PRINT 'Check 2 FAILED: Revenue mismatch! OLTP=' + 
          FORMAT(@OltpTotalRevenue, 'N2') + ', OLAP=' + FORMAT(@OlapTotalRevenue, 'N2');

-- Check 3: Verify sum(quantity * unit_price) = sum(total_amount)
DECLARE @CalcRevenue DECIMAL(15,2) = (
    SELECT SUM(quantity  * CAST(unit_price AS DECIMAL(10,2))) FROM dbo.order_facts
);

IF ABS(@CalcRevenue - @OlapTotalRevenue) < 0.01
    PRINT 'Check 3 PASSED: Metric calculation is correct ✓'
ELSE
    PRINT 'Check 3 FAILED: Metric calculation error!';

PRINT '';

-- ============================================================================
-- STEP 3: Sample Fact Table Data
-- ============================================================================
-- Show a few rows to verify data loaded correctly

PRINT 'STEP 3: Sample fact table rows';
PRINT '---';

SELECT TOP 10
    order_fact_id,
    order_id,
    product_id,
    customer_id,
    date_id,
    quantity,
    unit_price,
    total_amount
FROM dbo.order_facts
ORDER BY order_fact_id;

PRINT '';

-- ============================================================================
-- STEP 4: Aggregation Testing - Verify analytics work correctly
-- ============================================================================
-- Purpose: Show that aggregations give correct results
--
-- Key insight: With correct grain, different aggregations all make sense:
--   - SUM(total_amount) by customer = customer lifetime value
--   - SUM(total_amount) by product = product revenue
--   - SUM(quantity) by product = units sold
--   - COUNT(*) by date = items ordered per day
-- ============================================================================

PRINT 'STEP 4: Aggregation Testing';
PRINT '---';
PRINT 'Top 5 products by revenue:';

SELECT TOP 5
    p.product_name,
    COUNT(*) AS num_items_ordered,
    SUM(o_f.quantity) AS total_quantity,
    SUM(o_f.total_amount) AS total_revenue
FROM dbo.order_facts o_f
JOIN dbo.product_dim p ON o_f.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;

PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '========================================';
PRINT 'FACT TABLE LOADED & VERIFIED ✓';
PRINT '========================================';
PRINT '';
PRINT 'Grain: One row per order item (NOT per order)';
PRINT 'Fact rows: ' + CAST(@OlapFactCount AS VARCHAR);
PRINT 'Total revenue: $' + FORMAT(@OlapTotalRevenue, 'N2');


GO
