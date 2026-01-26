-- ============================================================================
-- PHASE 1: ANALYTICAL QUERIES ON STAR SCHEMA
-- PURPOSE: Demonstrate the power of star schema for business intelligence
-- DESCRIPTION:
--   These queries show how easy and fast analytics become with a proper
--   star schema. Notice:
--   1. Fewer JOINs (fact + dimensions only)
--   2. Easier to understand
--   3. Performance is much better than OLTP queries
--   4. Business users can modify these easily
--
-- ============================================================================

USE ecommerce_olap;
GO

PRINT '========================================';
PRINT 'ANALYTICAL QUERIES ON STAR SCHEMA';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- QUERY 1: Sales by Product
-- ============================================================================
-- Business Question: Which products generate the most revenue?
-- Note: Simple, direct aggregation - no complex joins needed
-- ============================================================================

PRINT 'QUERY 1: Top 10 Products by Revenue';
PRINT '---';

SELECT TOP 10
    p.product_name,
    p.category_name,
    COUNT(o_f.order_fact_id) AS num_orders,
    SUM(o_f.quantity) AS total_units_sold,
    SUM(o_f.total_amount) AS total_revenue,
    CAST(AVG(o_f.unit_price) AS DECIMAL(10,2)) AS avg_price,
    CAST(AVG(o_f.total_amount) AS DECIMAL(10,2)) AS avg_order_value
FROM dbo.order_facts o_f
JOIN dbo.product_dim p ON o_f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category_name
ORDER BY total_revenue DESC;

PRINT '';

-- ============================================================================
-- QUERY 2: Sales by Category
-- ============================================================================
-- Business Question: Which product categories are most profitable?
-- Benefit: See the full picture across all products in a category
-- ============================================================================

PRINT 'QUERY 2: Revenue by Category';
PRINT '---';

SELECT
    p.category_name,
    COUNT(DISTINCT p.product_id) AS num_products,
    COUNT(o_f.order_fact_id) AS num_items_sold,
    SUM(o_f.quantity) AS total_units,
    SUM(o_f.total_amount) AS category_revenue,
    CAST(AVG(o_f.total_amount) AS DECIMAL(10,2)) AS avg_item_value
FROM dbo.order_facts o_f
JOIN dbo.product_dim p ON o_f.product_id = p.product_id
GROUP BY p.category_id, p.category_name
ORDER BY category_revenue DESC;

PRINT '';

-- ============================================================================
-- QUERY 3: Customer Lifetime Value (CLV)
-- ============================================================================
-- Business Question: Which customers are our most valuable?
-- Insight: CLV is critical for customer retention and marketing strategies
-- ============================================================================

PRINT 'QUERY 3: Customer Lifetime Value (Top 10 Customers)';
PRINT '---';

SELECT TOP 10
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.country,
    COUNT(DISTINCT o_f.order_id) AS num_orders,
    COUNT(o_f.order_fact_id) AS num_items_purchased,
    SUM(o_f.total_amount) AS lifetime_value,
    CAST(AVG(o_f.total_amount) AS DECIMAL(10,2)) AS avg_order_value,
    MIN(d.calendar_date) AS first_purchase_date,
    MAX(d.calendar_date) AS most_recent_purchase
FROM dbo.order_facts o_f
JOIN dbo.customer_dim c ON o_f.customer_id = c.customer_id
JOIN dbo.date_dim d ON o_f.date_id = d.date_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
ORDER BY lifetime_value DESC



PRINT '';

-- ============================================================================
-- QUERY 4: Sales Trend - Monthly Revenue
-- ============================================================================
-- Business Question: How are sales trending over time?
-- Benefit: Spot seasonal patterns and growth trends
-- ============================================================================

PRINT 'QUERY 4: Monthly Sales Trend';
PRINT '---';

SELECT
    d.year,
    d.month_name,
    d.year_month,
   -- COUNT(o_f.order_fact_id) AS num_items,
	SUM(o_f.quantity) AS num_items,
    COUNT(DISTINCT o_f.order_id) AS num_orders,
    SUM(o_f.total_amount) AS monthly_revenue,
    CAST(AVG(o_f.total_amount) AS DECIMAL(10,2)) AS avg_item_price
FROM dbo.order_facts o_f
JOIN dbo.date_dim d ON o_f.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name, d.year_month
ORDER BY d.year, d.month;

PRINT '';

-- ============================================================================
-- QUERY 5: Seasonal Analysis (Same month, different years)
-- ============================================================================
-- Business Question: Is December always better than January?
-- Insight: Helps with inventory planning and staffing decisions
-- ============================================================================

PRINT 'QUERY 5: Seasonal Analysis - Revenue by Month (all years)';
PRINT '---';

SELECT
    d.month_name,
    d.year,
    --COUNT(o_f.order_fact_id) AS items_ordered,
	SUM(o_f.quantity) AS items_ordered,
    SUM(o_f.total_amount) AS revenue
FROM dbo.order_facts o_f
JOIN dbo.date_dim d ON o_f.date_id = d.date_id
GROUP BY d.month, d.month_name, d.year
ORDER BY d.month, d.year;

PRINT '';

-- ============================================================================
-- QUERY 6: Geographic Analysis - Sales by Country
-- ============================================================================
-- Business Question: Which countries drive the most revenue?
-- Insight: Helps with expansion and localization strategies
-- ============================================================================

PRINT 'QUERY 6: Revenue by Country';
PRINT '---';

SELECT
    c.country,
    COUNT(DISTINCT c.customer_id) AS num_customers,
    COUNT(DISTINCT o_f.order_id) AS num_orders,
    --COUNT(o_f.order_fact_id) AS num_items,
	SUM(o_f.quantity) AS num_items,
    SUM(o_f.total_amount) AS country_revenue,
    CAST(AVG(o_f.total_amount) AS DECIMAL(10,2)) AS avg_order_value
FROM dbo.order_facts o_f
JOIN dbo.customer_dim c ON o_f.customer_id = c.customer_id
GROUP BY c.country
ORDER BY country_revenue DESC;

PRINT '';

-- ============================================================================
-- QUERY 7: Order Status Analysis
-- ============================================================================
-- Business Question: How many orders are completed vs cancelled?
-- Insight: Identifies quality and fulfillment issues
-- ============================================================================

PRINT 'QUERY 7: Order Status Summary';
PRINT '---';

SELECT
    order_status,
    COUNT(DISTINCT order_id) AS num_orders,
    COUNT(*) AS num_items,
    SUM(quantity) AS total_units,
    SUM(total_amount) AS total_value
FROM dbo.order_facts
GROUP BY order_status;

PRINT '';

-- ============================================================================
-- QUERY 8: Customer Segmentation - High Value vs Others
-- ============================================================================
-- Business Question: Who are our best customers?
-- Insight: Helps segment customers for targeted marketing
-- ============================================================================

PRINT 'QUERY 8: Customer Segmentation by Spending';
PRINT '---';

   WITH CTE AS
   (SELECT c.customer_id,
           SUM(o_f.total_amount) AS customer_lifetime_value,
		   CASE
				WHEN SUM(o_f.total_amount) >= 10000 THEN 'VIP (10k+)'
				WHEN SUM(o_f.total_amount) >= 5000 THEN 'Premium (5k-10k)'
				WHEN SUM(o_f.total_amount) >= 1000 THEN 'Regular (1k-5k)'
				ELSE 'Occasional (<1k)'
		   END AS customer_segment
    FROM dbo.order_facts o_f
    JOIN dbo.customer_dim c ON o_f.customer_id = c.customer_id
    GROUP BY c.customer_id)
	SELECT
	customer_segment,
    COUNT(*) AS num_customers,
    CAST(AVG(customer_lifetime_value) AS DECIMAL(10,2)) AS avg_clv,
    CAST(MIN(customer_lifetime_value) AS DECIMAL(10,2)) AS min_clv,
    CAST(MAX(customer_lifetime_value) AS DECIMAL(10,2)) AS max_clv
	FROM CTE
	GROUP BY customer_segment
	ORDER BY avg_clv DESC;

PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '========================================';
PRINT 'ANALYTICAL QUERIES COMPLETE';
PRINT '========================================';
PRINT '';
PRINT 'Benefits of star schema demonstrated:';
PRINT '  ✓ Fast, simple aggregations';
PRINT '  ✓ Easy to understand queries';
PRINT '  ✓ Business-friendly structure';
PRINT '  ✓ Flexible for new analyses';
PRINT '';

GO


--## CHECKPOINT 1.3: Star Schema Complete


-- Run this quick check in SSMS
USE ecommerce_olap;
SELECT COUNT(*) as dimension_table_count FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME IN ('date_dim', 'product_dim', 'customer_dim', 'category_dim');

-- Should return: 4

-- Check fact table
SELECT COUNT(*) as fact_row_count FROM order_facts;
-- Should return: 33 rows
