-- ============================================================================
-- PHASE 1: DIMENSIONAL (STAR) SCHEMA CREATION
-- PURPOSE: Build the star schema data warehouse structure optimized for analytics
-- DESCRIPTION:
--   This script creates:
--   1. Date dimension (date_dim) — basis for all time-based analysis
--   2. Product dimension (product_dim) — what was sold, denormalized with category
--   3. Customer dimension (customer_dim) — who bought it
--   4. Category dimension (category_dim) — product classification
--   5. Order fact table (order_facts) — denormalized for fast analytics
--
--   The star schema is denormalized (NOT 3NF) but optimized for analytical
--   queries. This is intentional and represents best practices for OLAP systems.
--
-- GRAIN: One row per order item (not per order)
--   Why? Because you need to analyze each product separately, even within
--   the same order. This allows aggregation by product, category, customer, etc.
--
-- ============================================================================

-- Create the data warehouse database (if not exists)
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ecommerce_olap')
BEGIN
    CREATE DATABASE ecommerce_olap;
    PRINT 'Database ecommerce_olap created ✓';
END
ELSE
BEGIN
    PRINT 'Database ecommerce_olap already exists';
END

USE ecommerce_olap;
GO

-- ============================================================================
-- TABLE 1: DATE DIMENSION (date_dim)
-- ============================================================================
-- Purpose: Provides calendar context for every date in your data
-- Why date_dim? 
--   Rather than storing just order_date, you can join to dimensions like:
--   - Which year/month did this happen?
--   - Was it a weekend?
--   - What quarter?
--   This allows quick "Year-over-Year" and seasonal analysis
--
-- Grain: One row per calendar day
-- Row count: ~3,650 rows for 10 years of data
-- ============================================================================

IF OBJECT_ID('dbo.date_dim', 'U') IS NOT NULL
    DROP TABLE dbo.date_dim;

CREATE TABLE dbo.date_dim (
    date_id INT PRIMARY KEY NOT NULL,                    -- YYYYMMDD format as integer
    calendar_date DATE NOT NULL,                         -- Actual date
    year INT NOT NULL,                                   -- 2023, 2024, etc.
    quarter INT NOT NULL,                                -- 1-4
    month INT NOT NULL,                                  -- 1-12
    day_of_month INT NOT NULL,                          -- 1-31
    day_of_week INT NOT NULL,                           -- 1=Sunday, 7=Saturday
    day_name VARCHAR(20) NOT NULL,                      -- 'Monday', 'Tuesday', etc.
    is_weekend BIT NOT NULL,                            -- 1 if Saturday/Sunday
    is_holiday BIT NOT NULL DEFAULT 0,                  -- For holiday analysis
    week_number INT NOT NULL,                           -- 1-53
    month_name VARCHAR(20) NOT NULL,                    -- 'January', 'February', etc.
    year_month VARCHAR(7) NOT NULL,                     -- '2024-01' for grouping
    CONSTRAINT ck_date_dim_month CHECK (month BETWEEN 1 AND 12),
    CONSTRAINT ck_date_dim_day CHECK (day_of_month BETWEEN 1 AND 31)
);

CREATE NONCLUSTERED INDEX idx_date_dim_calendar ON dbo.date_dim(calendar_date);

PRINT 'Table date_dim created ✓';
GO

-- ============================================================================
-- TABLE 2: CATEGORY DIMENSION (category_dim)
-- ============================================================================
-- Purpose: Static list of product categories
-- Grain: One row per category
-- Notes: This could be denormalized into product_dim, but keeping separate
--        allows for category-level analysis and future hierarchies
-- ============================================================================

IF OBJECT_ID('dbo.category_dim', 'U') IS NOT NULL
    DROP TABLE dbo.category_dim;

CREATE TABLE dbo.category_dim (
    category_id INT PRIMARY KEY NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id INT NULL,                        -- For hierarchies (future use)
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT GETUTCDATE()
);

PRINT 'Table category_dim created ✓';
GO

-- ============================================================================
-- TABLE 3: PRODUCT DIMENSION (product_dim)
-- ============================================================================
-- Purpose: Denormalized product information for analytics
-- Grain:   One row per product
-- Denormalization: Includes category_name (from OLTP product_categories table)
-- Notes: In Phase 2, this will support Slowly Changing Dimensions (SCD Type 2)
--        for tracking price changes over time
-- ============================================================================

IF OBJECT_ID('dbo.product_dim', 'U') IS NOT NULL
    DROP TABLE dbo.product_dim;

CREATE TABLE dbo.product_dim (
    product_id INT PRIMARY KEY NOT NULL,               -- Surrogate key
    product_name VARCHAR(255) NOT NULL,                -- What is it?
    category_id INT NOT NULL,                          -- FK to category_dim
    category_name VARCHAR(100) NOT NULL,               -- Denormalized for easy analysis
    list_price DECIMAL(10, 2) NOT NULL,                -- Product's list price
    is_active BIT NOT NULL DEFAULT 1,                  -- Currently being sold?
    effective_date DATE NOT NULL,                      -- SCD Type 2 support (Phase 2)
    end_date DATE NULL,                                -- SCD Type 2 support (Phase 2)
    created_at DATETIME DEFAULT GETUTCDATE(),
    CONSTRAINT fk_product_dim_category FOREIGN KEY (category_id) REFERENCES category_dim(category_id)
);

CREATE NONCLUSTERED INDEX idx_product_dim_category ON dbo.product_dim(category_id);
CREATE NONCLUSTERED INDEX idx_product_dim_name ON dbo.product_dim(product_name);

PRINT 'Table product_dim created ✓';
GO

-- ============================================================================
-- TABLE 4: CUSTOMER DIMENSION (customer_dim)
-- ============================================================================
-- Purpose: Denormalized customer information for analytics
-- Grain:   One row per customer
-- Denormalization: Combines address info for easier joins
-- Notes: In Phase 2, this will support Slowly Changing Dimensions for
--        tracking customer address/contact changes
-- ============================================================================

IF OBJECT_ID('dbo.customer_dim', 'U') IS NOT NULL
    DROP TABLE dbo.customer_dim;

CREATE TABLE dbo.customer_dim (
    customer_id INT PRIMARY KEY NOT NULL,               -- Surrogate key
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
	city VARCHAR(100) NOT NULL, 
	state VARCHAR(100) NOT NULL, 
    country VARCHAR(100) NOT NULL,                     -- Denormalized from OLTP
    registration_date DATE NOT NULL,                   -- When they signed up
    is_active BIT NOT NULL DEFAULT 1,                  -- Currently a customer?
    effective_date DATE NOT NULL,                      -- SCD Type 2 support
    end_date DATE NULL,                                -- SCD Type 2 support
    created_at DATETIME DEFAULT GETUTCDATE()
);

CREATE NONCLUSTERED INDEX idx_customer_dim_name ON dbo.customer_dim(last_name, first_name);
CREATE NONCLUSTERED INDEX idx_customer_dim_country ON dbo.customer_dim(country);

PRINT 'Table customer_dim created ✓';
GO

-- ============================================================================
-- TABLE 5: ORDER FACT TABLE (order_facts)
-- ============================================================================
-- Purpose: Core fact table for analytical queries - one row per order item
-- Grain: One row per product in an order (NOT one row per order!)
--
-- Why this grain?
--   If you made fact grain = "one row per order", you'd have to duplicate
--   product details. Instead, each product in an order gets its own row.
--   This allows you to aggregate by product, category, customer, date, etc.
--
-- Example: Order #1 has 2 products
--   order_fact_id=1, order_id=1, product_id=10, quantity=2, unit_price=50
--   order_fact_id=2, order_id=1, product_id=20, quantity=1, unit_price=100
--
-- When you SELECT SUM(total_amount) by customer, you get the right total
-- When you SELECT SUM(total_amount) by product, you get correct per-product revenue
-- ============================================================================

IF OBJECT_ID('dbo.order_facts', 'U') IS NOT NULL
    DROP TABLE dbo.order_facts;

CREATE TABLE dbo.order_facts (
    order_fact_id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,  -- Surrogate key (system-generated)
    
    -- Business Keys (reference to OLTP)
    order_id INT NOT NULL,                                  -- Reference to OLTP order
    
    -- Foreign Keys to Dimensions
    product_id INT NOT NULL,                                -- FK to product_dim
    customer_id INT NOT NULL,                               -- FK to customer_dim
    date_id INT NOT NULL,                                   -- FK to date_dim (order date)
    category_id INT NOT NULL,                               -- FK to category_dim (denormalized)
    
    -- Metrics (facts that can be aggregated)
    quantity INT NOT NULL,                                  -- How many units ordered
    unit_price DECIMAL(10, 2) NOT NULL,                    -- Price per unit at time of order
    total_amount DECIMAL(10, 2) NOT NULL,                  -- quantity × unit_price
    
    -- Contextual Attributes (could be in dimension, included here for simplicity)
    order_status VARCHAR(50) NOT NULL,                     -- 'pending', 'completed', 'cancelled'
    
    -- Data Lineage (when was this record loaded?)
    created_at DATETIME DEFAULT GETUTCDATE(),
    
    -- Foreign Key Constraints
    CONSTRAINT fk_order_facts_product  FOREIGN KEY (product_id)  REFERENCES product_dim(product_id),
    CONSTRAINT fk_order_facts_customer FOREIGN KEY (customer_id) REFERENCES customer_dim(customer_id),
    CONSTRAINT fk_order_facts_date     FOREIGN KEY (date_id)     REFERENCES date_dim(date_id),
    CONSTRAINT fk_order_facts_category FOREIGN KEY (category_id) REFERENCES category_dim(category_id),
    
    -- Data Quality Constraints
    CONSTRAINT ck_order_facts_quantity   CHECK (quantity > 0),
    CONSTRAINT ck_order_facts_unit_price CHECK (unit_price > 0),
    CONSTRAINT ck_order_facts_total      CHECK (total_amount > 0)
);

-- Indexes for common query patterns
CREATE NONCLUSTERED INDEX idx_order_facts_date ON dbo.order_facts(date_id)  INCLUDE (total_amount);

CREATE NONCLUSTERED INDEX idx_order_facts_customer ON dbo.order_facts(customer_id) INCLUDE (total_amount);

CREATE NONCLUSTERED INDEX idx_order_facts_product ON dbo.order_facts(product_id) INCLUDE (total_amount, quantity);

CREATE NONCLUSTERED INDEX idx_order_facts_category ON dbo.order_facts(category_id) INCLUDE (total_amount);

PRINT 'Table order_facts created ✓';
GO

-- ============================================================================
-- SUMMARY: DIMENSIONAL SCHEMA CREATED
-- ============================================================================

PRINT '';
PRINT '========================================';
PRINT 'DIMENSIONAL SCHEMA CREATION COMPLETE';
PRINT '========================================';
PRINT '';
PRINT 'Tables created:';
PRINT '  1. date_dim (date_id INT, calendar_date DATE, year INT, ...)';
PRINT '  2. category_dim (category_id, category_name, ...)';
PRINT '  3. product_dim (product_id, product_name, category_id, ...)';
PRINT '  4. customer_dim (customer_id, first_name, last_name, ...)';
PRINT '  5. order_facts (order_fact_id, order_id, product_id, ...)';
PRINT '';
PRINT 'Next steps:';
PRINT '  Execute script 05_load_dimensions.sql to populate dimensions';
PRINT '  Then execute 06_load_facts.sql to load facts from OLTP';
PRINT '';

GO
