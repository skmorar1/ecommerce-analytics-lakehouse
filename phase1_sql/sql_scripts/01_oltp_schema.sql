-- ============================================================================
-- PHASE 1: OLTP SCHEMA DESIGN
-- PURPOSE: Create normalized tables for eCommerce transactional data
-- DESCRIPTION:
--   This script creates 5 tables that store eCommerce operational data.
--   Tables are designed following 3NF (Third Normal Form) normalization.
--
--   Why normalized? 
--   - Prevents data duplication (customer stored once, not in every order)
--   - Ensures data integrity (foreign keys prevent orphaned records)
--   - Efficient for INSERT/UPDATE/DELETE operations
--   - Used in real-time operational systems
--
-- TABLE RELATIONSHIPS:
--   customers ──┐
--               ├─→ orders ──→ order_items ──→ products ──→ product_categories
--
-- ============================================================================

USE ecommerce_oltp;
GO

-- ============================================================================
-- TABLE 1: product_categories
-- PURPOSE: Define product categories
-- NOTES: Simple lookup table, no dependencies on other tables
-- ============================================================================

CREATE TABLE product_categories (
    -- Primary Key: Uniquely identifies each category
    category_id INT PRIMARY KEY IDENTITY(1,1),
    
    -- Column: Category name
    -- NOT NULL: Every category must have a name
    -- UNIQUE: No duplicate category names allowed
    category_name VARCHAR(100) NOT NULL UNIQUE,
    
    -- Column: Optional description
    description VARCHAR(500)
);

PRINT 'Created table: product_categories';
GO

-- ============================================================================
-- TABLE 2: products
-- PURPOSE: Store product information
-- NOTES: Foreign key references product_categories
-- ============================================================================

CREATE TABLE products (
    -- Primary Key: Uniquely identifies each product
    product_id INT PRIMARY KEY IDENTITY(1,1),
    
    -- Column: Product name
    -- NOT NULL: Every product must have a name
    product_name VARCHAR(255) NOT NULL,
    
    -- Column: Category ID (Foreign Key)
    -- FOREIGN KEY constraint: Ensures category_id exists in product_categories
    -- If user tries to insert non-existent category, SQL Server rejects it
    category_id INT NOT NULL,
    
    -- Column: Selling price
    -- DECIMAL(10,2) = 10 total digits, 2 decimal places (e.g., 99999999.99)
    -- CHECK constraint: Price must be positive (> 0)
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    
    -- Column: Current inventory quantity
    stock_quantity INT NOT NULL DEFAULT 0,
    
    -- Define Foreign Key relationship
    CONSTRAINT fk_products_category 
        FOREIGN KEY (category_id) REFERENCES product_categories(category_id)
);

PRINT 'Created table: products';
GO

-- ============================================================================
-- TABLE 3: customers
-- PURPOSE: Store customer information
-- NOTES: No dependencies, foundational table
-- ============================================================================

CREATE TABLE customers (
    -- Primary Key: Uniquely identifies each customer
    customer_id INT PRIMARY KEY IDENTITY(1,1),
    
    -- Column: Customer first name
    first_name VARCHAR(100) NOT NULL,
    
    -- Column: Customer last name
    last_name VARCHAR(100) NOT NULL,
    
    -- Column: Email address
    -- NOT NULL: Every customer must have email
    -- UNIQUE: No duplicate emails allowed (each customer has one unique email)
    email VARCHAR(255) UNIQUE NOT NULL,

	-- Column: City of residence
    city VARCHAR(100),

		-- Column: State of residence
    state VARCHAR(100),
    
    -- Column: Country of residence
    country VARCHAR(100),
    
    -- Column: Account creation date
    registration_date DATE NOT NULL DEFAULT GETDATE(),

	    -- Column: Account creation date
    updated_date DATETIME NULL DEFAULT GETDATE()
);

PRINT 'Created table: customers';
GO

-- ============================================================================
-- TABLE 4: orders
-- PURPOSE: Record customer orders
-- NOTES: Foreign key references customers
-- ============================================================================

CREATE TABLE orders (
    -- Primary Key: Uniquely identifies each order
    order_id INT PRIMARY KEY IDENTITY(1,1),
    
    -- Column: Customer ID (Foreign Key)
    -- FOREIGN KEY constraint: Links order to specific customer
    customer_id INT NOT NULL,
    
    -- Column: Order date
    -- DEFAULT GETDATE() = If not specified, use current date/time
    order_date DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    
    -- Column: Total order amount
    -- Sum of all items in this order
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    
    -- Column: Order status
    -- Typical values: 'pending', 'completed', 'cancelled', 'shipped'
    order_status VARCHAR(50) DEFAULT 'pending',
    
    -- Define Foreign Key relationship
    CONSTRAINT fk_orders_customer 
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

PRINT 'Created table: orders';
GO

-- ============================================================================
-- TABLE 5: order_items
-- PURPOSE: Store individual items within each order
-- NOTES: Foreign keys reference orders and products
--        One order can have many order_items
--        Example: Order #123 might have 2 products = 2 order_item rows
-- ============================================================================

CREATE TABLE order_items (
    -- Primary Key: Uniquely identifies each line item
    order_item_id INT PRIMARY KEY IDENTITY(1,1),
    
    -- Column: Order ID (Foreign Key)
    -- FOREIGN KEY constraint: Links item to specific order
    order_id INT NOT NULL,
    
    -- Column: Product ID (Foreign Key)
    -- FOREIGN KEY constraint: Links item to specific product
    product_id INT NOT NULL,
    
    -- Column: Quantity of this product in the order
    -- CHECK constraint: Must order at least 1 item
    quantity INT NOT NULL CHECK (quantity > 0),
    
    -- Column: Price per unit at time of order
    -- Stored separately because product price might change later
    -- By storing historical price, we preserve order accuracy
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    
    -- Column: Total for this line item
    -- Calculated: quantity × unit_price
    -- Could be calculated on-the-fly, but stored for performance
    item_total DECIMAL(12,2) NOT NULL CHECK (item_total > 0),
    
    -- Define Foreign Key relationships
    CONSTRAINT fk_order_items_order 
        FOREIGN KEY (order_id) REFERENCES orders(order_id),
    
    CONSTRAINT fk_order_items_product 
        FOREIGN KEY (product_id) REFERENCES products(product_id)
);

PRINT 'Created table: order_items';
GO

-- ============================================================================
-- SUMMARY: OLTP Schema Created
-- ============================================================================

PRINT '';
PRINT '========================================';
PRINT 'OLTP SCHEMA CREATION COMPLETE';
PRINT '========================================';
PRINT 'Tables Created:';
PRINT '  1. product_categories (lookup table)';
PRINT '  2. products (with category foreign key)';
PRINT '  3. customers (foundational table)';
PRINT '  4. orders (references customers)';
PRINT '  5. order_items (references orders and products)';
PRINT '';
PRINT 'Key Concepts:';
PRINT '  - Primary Keys: Uniquely identify each row';
PRINT '  - Foreign Keys: Create relationships between tables';
PRINT '  - NOT NULL: Ensures required data is always present';
PRINT '  - UNIQUE: Prevents duplicate values';
PRINT '  - CHECK: Validates data meets business rules';
PRINT '  - DEFAULT: Automatically fills in values if not specified';
PRINT '========================================';
GO

-- ============================================================================
-- VERIFICATION: Check that tables were created
-- ============================================================================

-- Display all tables in the database
PRINT '';
PRINT 'Tables in ecommerce_oltp database:';
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

GO

/*
### Execute the script:

1. **Select all text** (Ctrl+A)
2. **Press F5** to execute
3. **Check Messages tab** at bottom for success messages

**You should see:**
```
Created table: product_categories
Created table: products
Created table: customers
Created table: orders
Created table: order_items
========================================
OLTP SCHEMA CREATION COMPLETE
========================================

*/
