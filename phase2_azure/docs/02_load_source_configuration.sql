USE [sql-ecommerce-control-dev];
GO

-- =============================================
-- Load 3 Data Sources
-- =============================================

TRUNCATE TABLE dbo.etl_source_config;
GO

INSERT INTO dbo.etl_source_config (
    source_name, source_type, file_path, table_name, load_type, merge_key
)
VALUES
    ('orders', 'CSV', '/raw/orders/orders_[YYYY-MM-DD].csv', 
     'bronze_orders', 'INCREMENTAL', 'last_modified_date'),
    
    ('customers', 'CSV', '/raw/customers/customers_full.csv', 
     'bronze_customers', 'FULL', NULL),
    
    ('products', 'CSV', '/raw/products/products_[YYYY-MM-DD].csv', 
     'bronze_products', 'INCREMENTAL', 'updated_at');

-- =============================================
-- Initialize Watermarks
-- =============================================

INSERT INTO dbo.etl_watermark (
    source_id, watermark_column, last_watermark_value, current_watermark_value
)
SELECT
    source_id, merge_key, NULL, '1900-01-01'
FROM dbo.etl_source_config
WHERE load_type = 'INCREMENTAL';

-- =============================================
-- Test Logging
-- =============================================

EXEC dbo.sp_log_pipeline_execution
    @PipelineName = 'pl_test',
    @SourceId = 1,
    @Status = 'SUCCESS',
    @RowsProcessed = 1000;

-- ============================================================================
-- Verification - You should see 3 sources configured, watermarks initialized
-- ============================================================================

SELECT * FROM dbo.etl_source_config;
SELECT * FROM dbo.etl_watermark;
SELECT * FROM dbo.etl_execution_log;

GO

-- 
