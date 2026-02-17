-- ============================================================================
-- PHASE 1: LOAD DIMENSION TABLES
-- PURPOSE: ETL (Extract, Transform, Load) from OLTP → Star Schema
-- DESCRIPTION:
--   This script populates the dimension tables by extracting and transforming
--   data from the OLTP schema. This is your first real ETL process!
--
--   ETL Steps:
--   1. EXTRACT: Query from ecommerce_oltp tables
--   2. TRANSFORM: Apply business logic and denormalization
--   3. LOAD: INSERT into ecommerce_olap dimension tables
--
-- ============================================================================

USE ecommerce_olap;
GO

PRINT '========================================';
PRINT 'LOADING DIMENSION TABLES';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- STEP 1: Load DATE_DIM
-- ============================================================================
-- Purpose: Generate all dates for 10 years (2020-2029)
-- Logic: 
--   - Most data is from 2023-2024
--   - But having 10 years allows future scenario planning
--   - Pre-generating dates is cheaper than generating on-the-fly
--
-- Note: This uses a CTE (Common Table Expression) which you'll learn more
--       about in Section 1.4. For now, understand it as a temporary result set.
-- ============================================================================

PRINT 'STEP 1: Loading date_dim (10 years of calendar data)';
PRINT '---';

DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2029-12-31';

WITH date_cte AS (
    -- Generate all dates from start to end
    SELECT 
        @StartDate AS calendar_date
    UNION ALL
    SELECT 
        DATEADD(DAY, 1, calendar_date)
    FROM date_cte
    WHERE calendar_date < @EndDate
)
INSERT INTO dbo.date_dim 
(date_id, calendar_date, year, quarter, month, day_of_month, day_of_week, 
 day_name, is_weekend, week_number, month_name, year_month)
SELECT
 -- date_id is YYYYMMDD format as integer
 -- Example: Jan 1, 2024 = 20240101
 -- CAST(FORMAT(calendar_date, 'yyyyMMdd') AS INT) AS date_id,           (don't use)
	CAST(CONVERT(VARCHAR(8), calendar_date, 112) AS INT) AS date_id,  -- (use this syntax)
    
    calendar_date,
    YEAR(calendar_date) AS year,
    --QUARTER(calendar_date) AS quarter,             (don't use)
	DATEPART(quarter, calendar_date) AS quarter,  -- (use this syntax)
    MONTH(calendar_date) AS month,
    DAY(calendar_date) AS day_of_month,
    DATEPART(WEEKDAY, calendar_date) AS day_of_week,
    -- Convert day number to name: 1=Sunday, 2=Monday, etc.
    CASE DATEPART(WEEKDAY, calendar_date)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS day_name,
    -- Mark weekends (Saturday=7, Sunday=1)
    CASE WHEN DATEPART(WEEKDAY, calendar_date) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    DATEPART(WEEK, calendar_date) AS week_number,

--    FORMAT(calendar_date, 'MMMM') AS month_name,     (don't use)
	DATENAME(MONTH, calendar_date) AS month_name,   -- (use this syntax)
--    FORMAT(calendar_date, 'yyyy-MM') AS year_month   (don't use)
	CONCAT(YEAR(calendar_date), '-', FORMAT(calendar_date, 'MM')) AS year_month  -- (use this syntax)
FROM date_cte
OPTION (MAXRECURSION 3653);  -- Allow CTE to generate 3650+ rows

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' date records inserted ✓';
PRINT '';

-- ============================================================================
-- STEP 2: Load CATEGORY_DIM
-- ============================================================================
-- Purpose: Load categories from OLTP
-- Logic: Simple 1:1 mapping from OLTP product_categories
--
-- This is the simplest dimension load because categories don't change often
-- ============================================================================

PRINT 'STEP 2: Loading category_dim';
PRINT '---';

INSERT INTO dbo.category_dim (category_id, category_name, is_active)
SELECT
    pc.category_id,
    pc.category_name,
    1 AS is_active  -- Assume all OLTP categories are active
FROM ecommerce_oltp.dbo.product_categories pc
WHERE pc.category_id IS NOT NULL;

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' category records inserted ✓';
PRINT '';

-- ============================================================================
-- STEP 3: Load PRODUCT_DIM
-- ============================================================================
-- Purpose: Load products with denormalized category information
-- Logic: JOIN OLTP products with OLTP product_categories to create 
--        denormalized dimension
-- Denormalization: Includes category_name in product_dim for faster queries
--
-- This saves an extra JOIN in analytical queries
-- ============================================================================

PRINT 'STEP 3: Loading product_dim (with denormalized category)';
PRINT '---';

INSERT INTO dbo.product_dim 
(product_id, product_name, category_id, category_name, list_price, 
 is_active, effective_date)
SELECT
    p.product_id,
    p.product_name,
    p.category_id,
    pc.category_name,                          -- Denormalized
    p.unit_price AS list_price,
    1 AS is_active,                            -- Assume all products are active
    CAST(GETDATE() AS DATE) AS effective_date  -- Today is when we loaded it
FROM ecommerce_oltp.dbo.products p
JOIN ecommerce_oltp.dbo.product_categories pc ON p.category_id = pc.category_id
WHERE p.product_id IS NOT NULL;

PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' product records inserted ✓';
PRINT '';

-- ============================================================================
-- STEP 4: Load CUSTOMER_DIM
-- ============================================================================
-- Purpose: Load customers with denormalized location information
-- Logic: Extract from OLTP customers table
-- Denormalization: Extract city and country from address for easier analysis
--
-- Note: In the OLTP schema, city and country are separate columns,
--       so this is straightforward transformation
-- ============================================================================

PRINT 'STEP 4: Loading customer_dim (with denormalized location)';
PRINT '---';


INSERT INTO dbo.customer_dim 
(customer_id, first_name, last_name, email, city, state, country,
 registration_date, is_active, effective_date)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
	c.city,
	c.state,
    c.country,
    registration_date,
    1 AS is_active,
    CAST(GETDATE() AS DATE) AS effective_date
FROM ecommerce_oltp.dbo.customers c
WHERE c.customer_id IS NOT NULL;


PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' customer records inserted ✓';
PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '========================================';
PRINT 'ALL DIMENSIONS LOADED SUCCESSFULLY ✓';
PRINT '========================================';
PRINT '';
PRINT 'Dimension row counts:';

DECLARE @RowCount_date_dim INT;
SELECT @RowCount_date_dim = COUNT(*) FROM dbo.date_dim;

DECLARE @RowCount_category_dim INT;
SELECT @RowCount_category_dim = COUNT(*) FROM dbo.category_dim;

DECLARE @RowCount_product_dim INT;
SELECT @RowCount_product_dim= COUNT(*) FROM dbo.product_dim;

DECLARE @RowCount_customer_dim INT;
SELECT @RowCount_customer_dim = COUNT(*) FROM dbo.customer_dim;

PRINT 'date_dim:     ' + CAST(@RowCount_date_dim AS VARCHAR(20));
PRINT 'category_dim: ' + CAST(@RowCount_category_dim AS VARCHAR(20));
PRINT 'product_dim:  ' + CAST(@RowCount_product_dim AS VARCHAR(20));
PRINT 'customer_dim: ' + CAST(@RowCount_customer_dim AS VARCHAR(20))

PRINT '';
PRINT 'Next: Execute 06_load_facts.sql to load the fact table';
PRINT '';

