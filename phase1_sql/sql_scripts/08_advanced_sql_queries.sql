-- ============================================================================
-- PHASE 1: ADVANCED SQL QUERIES
-- PURPOSE: Demonstrate advanced SQL techniques for complex analytics
-- DESCRIPTION:
--   This script covers:
--   1. CTEs (Common Table Expressions) - organize complex logic
--   2. Window Functions - analytics without GROUP BY
--   3. Recursive CTEs - hierarchical data
--   4. Performance patterns - optimization techniques
--
-- Key Learning Goals:
--   - Write queries that are both fast AND readable
--   - Understand when to use each technique
--   - Build reusable query patterns for Phase 2
--
-- ============================================================================

USE ecommerce_olap;
GO

PRINT '========================================';
PRINT 'ADVANCED SQL QUERIES';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- QUERY 1: Multi-Level CTE with Customer Lifetime Value
-- ============================================================================
-- Shows: How CTEs simplify multi-step logic
-- Business Use: Customer segmentation and targeting
--
-- Logic:
--   1. Calculate customer lifetime value
--   2. Calculate product preferences
--   3. Rank customers by value
--   4. Show top customers with preferences
-- ============================================================================

PRINT 'QUERY 1: Top Customers with Purchasing Patterns';
PRINT '---';
PRINT 'Uses: Multiple CTEs, ROW_NUMBER() window function';
PRINT '';

WITH customer_lifetime_value AS (
    -- Step 1: Calculate each customer's total value
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS num_orders,
        COUNT(*) AS num_items,
        SUM(total_amount) AS lifetime_value,
        AVG(total_amount) AS avg_item_value,
        MIN(date_id) AS first_purchase_date,
        MAX(date_id) AS most_recent_purchase
    FROM order_facts
    GROUP BY customer_id
),
customer_top_product AS (
    -- Step 2: Find each customer's favorite category
    SELECT
        o_f.customer_id,
        p.category_name,
        COUNT(*) AS items_in_category,
        SUM(o_f.total_amount) AS spending_in_category,
        ROW_NUMBER() OVER (PARTITION BY o_f.customer_id ORDER BY COUNT(*) DESC) AS category_rank
    FROM order_facts o_f
    JOIN product_dim p ON o_f.product_id = p.product_id
    GROUP BY o_f.customer_id, p.category_id, p.category_name
),
customer_top_category AS (
    -- Step 3: Get only their #1 category
    SELECT
        customer_id,
        category_name,
        items_in_category,
        spending_in_category
    FROM customer_top_product
    WHERE category_rank = 1
),
ranked_customers AS (
    -- Step 4: Rank all customers by lifetime value
    SELECT
        clv.customer_id,
        clv.lifetime_value,
        clv.num_orders,
        ROW_NUMBER() OVER (ORDER BY clv.lifetime_value DESC) AS customer_rank
    FROM customer_lifetime_value clv
)
SELECT TOP 10
    rc.customer_rank,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.country,
    rc.lifetime_value,
    rc.num_orders,
    ctc.category_name AS favorite_category,
    ctc.spending_in_category
FROM ranked_customers rc
JOIN customer_dim c ON rc.customer_id = c.customer_id
LEFT JOIN customer_top_category ctc ON rc.customer_id = ctc.customer_id
ORDER BY rc.customer_rank;

PRINT '';

-- ============================================================================
-- QUERY 2: Window Functions - Customer Purchase History
-- ============================================================================
-- Shows: Window functions for moving aggregates and ranking
-- Business Use: Identify customer behavior patterns and trends
--
-- Window Functions Used:
--   - ROW_NUMBER() - Sequential numbering
--   - RANK() - Ranking with gaps
--   - LAG() - Previous row value
--   - SUM() OVER() - Running totals
--   - PERCENT_RANK() - Percentile ranking
-- ============================================================================

PRINT 'QUERY 2: Customer Purchase History with Window Functions';
PRINT '---';
PRINT 'Uses: ROW_NUMBER(), LAG(), SUM() OVER(), PERCENT_RANK()';
PRINT 'Shows first 3 purchases for the Top 5 customers';
PRINT '';

WITH customer_orders AS (
    SELECT
        c.customer_id,
        c.first_name + ' ' + c.last_name AS customer_name,
        d.calendar_date,
        o_f.order_id,
        o_f.total_amount,
        -- Sequential order number per customer
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY d.calendar_date) AS order_sequence,
        -- Days since previous purchase
        LAG(d.calendar_date) OVER (PARTITION BY c.customer_id ORDER BY d.calendar_date) AS prev_order_date,
        -- Running total of customer's spending
        SUM(o_f.total_amount) OVER (PARTITION BY c.customer_id ORDER BY d.calendar_date) AS cumulative_spending,
        -- Percentile of this customer's order value vs their other orders
        PERCENT_RANK() OVER (PARTITION BY c.customer_id ORDER BY o_f.total_amount) AS order_value_percentile
    FROM order_facts o_f
    JOIN customer_dim c ON o_f.customer_id = c.customer_id
    JOIN date_dim d ON o_f.date_id = d.date_id
)
SELECT
    customer_id,
    customer_name,
    calendar_date,
	prev_order_date,
    order_id,
    total_amount,
    order_sequence,
    DATEDIFF(DAY, prev_order_date, calendar_date) AS days_since_prev_order,
    cumulative_spending,
    CAST(order_value_percentile * 100 AS DECIMAL(5,1)) AS order_value_percentile
FROM customer_orders
WHERE order_sequence <= 3  -- Show first 3 orders only
  AND customer_id IN (
    SELECT TOP 5 customer_id 
    FROM order_facts 
    GROUP BY customer_id 
    ORDER BY SUM(total_amount) DESC
  )
ORDER BY customer_id, order_sequence;

PRINT '';

-- ============================================================================
-- QUERY 3: Year-over-Year Comparison (Advanced Window Function)
-- ============================================================================
-- Shows: Comparing same period across years
-- Business Use: Detecting growth trends and seasonal patterns
--
-- Technique: Use LAG() with PARTITION BY month to compare across years
-- ============================================================================

PRINT 'QUERY 3: Year-over-Year Revenue Comparison';
PRINT '---';
PRINT 'Uses: LAG() OVER(), PERCENT_RANK(), conditional aggregation';
PRINT '';

WITH monthly_sales AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        SUM(o_f.total_amount) AS monthly_revenue,
        COUNT(DISTINCT o_f.order_id) AS num_orders
    FROM order_facts o_f
    JOIN date_dim d ON o_f.date_id = d.date_id	
    GROUP BY d.year, d.month, d.month_name
)
SELECT
    year,
    month_name,
    monthly_revenue,
    num_orders,
    -- Get previous year's revenue for the same month
    LAG(monthly_revenue) OVER (PARTITION BY month ORDER BY year) AS prev_year_revenue,
    -- Calculate year-over-year growth
    CAST(
        (monthly_revenue - LAG(monthly_revenue) OVER (PARTITION BY month ORDER BY year)) / 
        LAG(monthly_revenue) OVER (PARTITION BY month ORDER BY year) * 100 
        AS DECIMAL(10,2)
    ) AS yoy_growth_percent
FROM monthly_sales
ORDER BY year DESC, month;

PRINT '';

-- ============================================================================
-- QUERY 4: Product Performance Ranking (RANK vs DENSE_RANK vs ROW_NUMBER)
-- ============================================================================
-- Shows: Differences between ranking functions
-- Business Use: Product selection for marketing campaigns
--
-- Key Difference:
--   - ROW_NUMBER(): Always unique (1,2,3,4...)
--   - RANK(): Skips ranks after ties (1,2,2,4...)
--   - DENSE_RANK(): No skips after ties (1,2,2,3...)
-- ============================================================================

PRINT 'QUERY 4: Product Rankings - Three Different Methods';
PRINT '---';
PRINT 'Shows difference between ROW_NUMBER vs RANK vs DENSE_RANK';
PRINT '';

WITH product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category_name,
        SUM(o_f.total_amount) AS total_revenue,
        SUM(o_f.quantity) AS total_units,
        COUNT(DISTINCT o_f.order_id) AS num_orders
    FROM order_facts o_f
    JOIN product_dim p ON o_f.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.category_name
)
SELECT
    product_name,
    category_name,
    total_revenue,
    -- All three ranking functions, side-by-side
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS row_rank,
    RANK() OVER (ORDER BY total_revenue DESC) AS standard_rank,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS dense_rank
FROM product_performance
ORDER BY total_revenue DESC;

PRINT '';

-- ============================================================================
-- QUERY 5: Running Totals & Moving Averages
-- ============================================================================
-- Shows: SUM/AVG OVER with ORDER BY creates running calculations
-- Business Use: Trend analysis, anomaly detection
--
-- ROWS/RANGE options:
--   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW = Running sum
--   ROWS BETWEEN 6 PRECEDING AND CURRENT ROW = Last 7 days
--   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW = All rows before current value
-- ============================================================================

PRINT 'QUERY 5: Running Totals and 7-Day Moving Average';
PRINT '---';
PRINT 'Uses: SUM() OVER with ROWS and RANGE clauses';
PRINT '';

WITH daily_sales AS (
    SELECT
        d.calendar_date,
        d.day_name,
        SUM(o_f.total_amount) AS daily_revenue,
        COUNT(DISTINCT o_f.order_id) AS daily_orders
    FROM order_facts o_f
    JOIN date_dim d ON o_f.date_id = d.date_id
    GROUP BY d.date_id, d.calendar_date, d.day_name
)
SELECT
    calendar_date,
    day_name,
    daily_revenue,
    -- Cumulative running total from start of data
    SUM(daily_revenue) OVER (ORDER BY calendar_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue,
    -- 7-day moving average
    AVG(daily_revenue) OVER (ORDER BY calendar_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7day,
    -- Compare to previous day
    daily_revenue - LAG(daily_revenue) OVER (ORDER BY calendar_date) AS day_over_day_change
FROM daily_sales
ORDER BY calendar_date DESC;

PRINT '';

-- ============================================================================
-- QUERY 6: Cohort Analysis with CTE
-- ============================================================================
-- Shows: Analyzing groups of customers by when they joined
-- Business Use: Retention analysis, cohort lifetime value
--
-- Cohort Analysis divides customers into groups based on when they first
-- made a purchase, then tracks their behavior over time
-- ============================================================================

PRINT 'QUERY 6: Cohort Analysis - Revenue by Customer Cohort';
PRINT '---';
PRINT 'Uses: CTE with MIN(), YEAR(), MONTH() for cohort definition';
PRINT '';

WITH customer_first_purchase AS (
    -- Determine each customer's cohort (year-month they first purchased)
    SELECT
        c.customer_id,
        YEAR(MIN(d.calendar_date)) AS cohort_year,
        MONTH(MIN(d.calendar_date)) AS cohort_month,
        FORMAT(MIN(d.calendar_date), 'yyyy-MM') AS cohort
    FROM customer_dim c
    JOIN order_facts o_f ON c.customer_id = o_f.customer_id
    JOIN date_dim d ON o_f.date_id = d.date_id
    GROUP BY c.customer_id
),
customer_monthly_spending AS (
    -- Calculate each customer's spending in each month
    SELECT
        cfp.cohort,
        YEAR(d.calendar_date) AS purchase_year,
        MONTH(d.calendar_date) AS purchase_month,
        COUNT(DISTINCT cfp.customer_id) AS cohort_size,
        SUM(o_f.total_amount) AS cohort_revenue,
        AVG(o_f.total_amount) AS avg_order_value
    FROM customer_first_purchase cfp
    JOIN order_facts o_f ON cfp.customer_id = o_f.customer_id
    JOIN date_dim d ON o_f.date_id = d.date_id
    GROUP BY cfp.cohort, YEAR(d.calendar_date), MONTH(d.calendar_date)
)
SELECT
    cohort,
    purchase_year,
    purchase_month,
    cohort_size,
    cohort_revenue,
    CAST(avg_order_value AS DECIMAL(10,2)) AS avg_order_value
FROM customer_monthly_spending
ORDER BY cohort DESC, purchase_year, purchase_month;

PRINT '';

-- ============================================================================
-- QUERY 7: Recursive CTE - Category Hierarchy (Setup for Phase 2)
-- ============================================================================
-- Shows: How to handle hierarchical data with recursive CTEs
-- Business Use: Org charts, product hierarchies, geographic hierarchies
--
-- Recursive CTEs:
--   1. Anchor member - initial result set
--   2. Recursive member - references previous iteration
--   3. Terminates when no new rows are generated
-- ============================================================================

PRINT 'QUERY 7: Recursive CTE Example - Category Path (Educational)';
PRINT '---';
PRINT 'Note: Our current schema has only 1 level, but this pattern is';
PRINT 'important for Phase 2 when we add hierarchical data.';
PRINT '';

WITH category_hierarchy AS (
    -- Anchor member: Start with root categories (no parent)
    SELECT
        category_id,
        category_name,
        CAST(category_id AS VARCHAR(MAX)) AS category_path,
        1 AS category_level
    FROM category_dim
    WHERE parent_category_id IS NULL
    
    UNION ALL
    
    -- Recursive member: Get children of current level
    SELECT
        c.category_id,
        c.category_name,
        ch.category_path + '>' + CAST(c.category_id AS VARCHAR(MAX)),
        ch.category_level + 1
    FROM category_dim c
    INNER JOIN category_hierarchy ch 
        ON c.parent_category_id = ch.category_id
)
SELECT
    category_id,
    category_name,
    category_path,
    category_level
FROM category_hierarchy
ORDER BY category_path;

PRINT '';

-- ============================================================================
-- QUERY 8: Performance Optimization - Index Usage
-- ============================================================================
-- Shows: How to ensure indexes are being used
-- Business Use: Query tuning and troubleshooting
--
-- Key Concepts:
--   - Seek: Efficient (uses index)
--   - Scan: Less efficient (reads all rows)
--   - Look at actual execution plan in SSMS (Ctrl+L)
-- ============================================================================

PRINT 'QUERY 8: Sales Analysis (Optimized for index usage)';
PRINT '---';
PRINT 'Uses: SUM() OVER to get aggregates AND individual rows efficiently';
PRINT '';

-- This query is optimized to use the idx_order_facts_date index
SELECT
    d.calendar_date,
    d.day_name,
    COUNT(*) AS num_items,
    COUNT(DISTINCT o_f.order_id) AS num_orders,
    SUM(o_f.total_amount) AS daily_revenue,
    SUM(SUM(o_f.total_amount)) OVER (ORDER BY d.calendar_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS revenue_7day_moving_avg
FROM order_facts o_f
JOIN date_dim d ON o_f.date_id = d.date_id
WHERE YEAR(d.calendar_date) = YEAR(GETDATE())  -- Filter to current year
GROUP BY d.date_id, d.calendar_date, d.day_name
ORDER BY d.calendar_date DESC;

PRINT '';

-- ============================================================================
-- SUMMARY & PATTERNS
-- ============================================================================

PRINT '========================================';
PRINT 'ADVANCED SQL PATTERNS DEMONSTRATED';
PRINT '========================================';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  ✓ CTEs organize complex logic into readable steps';
PRINT '  ✓ Window functions enable sophisticated analytics';
PRINT '  ✓ ROW_NUMBER/RANK/DENSE_RANK for different ranking needs';
PRINT '  ✓ LAG/LEAD for comparing rows across time periods';
PRINT '  ✓ SUM/AVG OVER for running totals and moving averages';
PRINT '  ✓ Recursive CTEs for hierarchical data (Phase 2)';
PRINT '  ✓ Always consider indexes in WHERE and JOIN clauses';
PRINT '';
PRINT 'Next: Review execution plans in SSMS to understand performance';
PRINT '';

GO
