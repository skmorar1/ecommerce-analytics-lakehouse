-- ==============================================
-- Control Database Setup
-- ==============================================

USE [sql-ecommerce-control-dev];
GO

-- =============================================
-- TABLE 1: etl_source_config
-- Answers: What sources do we have and how do we load them?
-- Think of it as a menu. It lists every source file (orders, customers, products), 
-- where to find it, and whether to load it fully or incrementally. 
-- You set it up once and only touch it when adding a new source.

-- =============================================
-- Define all data sources in one place
-- Adding source = 1 INSERT, zero code changes
-- It means when you need to add a new source file to your pipeline, all you do is insert 
-- one row into etl_source_config. For example:
-- INSERT INTO dbo.etl_source_config (source_name, source_type, file_path, table_name, load_type, merge_key)
-- VALUES ('inventory', 'CSV', '/raw/inventory/inventory_full.csv','bronze_inventory', 'INCREMENTAL', 'last_modified_date');

IF OBJECT_ID('dbo.etl_source_config', 'U') IS NOT NULL
    DROP TABLE dbo.etl_source_config;
GO

CREATE TABLE dbo.etl_source_config (
    source_id INT PRIMARY KEY IDENTITY(1,1),
    source_name NVARCHAR(100) NOT NULL UNIQUE,
    source_type NVARCHAR(50) NOT NULL,  -- 'CSV', 'API', 'Database'
    file_path NVARCHAR(500) NOT NULL,
    table_name NVARCHAR(100) NOT NULL,
    load_type NVARCHAR(50) NOT NULL,    -- 'FULL' or 'INCREMENTAL'
    merge_key NVARCHAR(100),            --  Column name from the source file that contains the date used for incremental tracking, e.g. last_modified_date or updated_at or modified_on
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    is_active BIT DEFAULT 1
);

CREATE INDEX idx_source_active ON dbo.etl_source_config(is_active);
GO


-- =============================================
-- TABLE 2: etl_watermark
-- Answers: Where did we leave off last time?
-- Think of it as a bookmark. For each incremental source, it tracks the last date you loaded up to. 
-- Before each run, the pipeline checks this table to know what's new. 
-- After each run, it moves the bookmark forward. Same rows, updated in place.

-- =============================================
-- Track where we stopped last time
-- Watermark = checkpoint for incremental loads


IF OBJECT_ID('dbo.etl_watermark', 'U') IS NOT NULL
    DROP TABLE dbo.etl_watermark;
GO

CREATE TABLE dbo.etl_watermark (
    watermark_id INT PRIMARY KEY IDENTITY(1,1),
    source_id INT NOT NULL FOREIGN KEY REFERENCES dbo.etl_source_config(source_id),
    watermark_column NVARCHAR(100) NOT NULL,
    last_watermark_value NVARCHAR(100),
    current_watermark_value NVARCHAR(100),
    load_date DATETIME2 DEFAULT GETDATE(),
    UNIQUE (source_id, watermark_column)
);

CREATE INDEX idx_watermark_source ON dbo.etl_watermark(source_id);
GO


-- =============================================
-- TABLE 3: etl_execution_log
-- Answers: What happened and when?
-- Think of it as a diary. Every single pipeline run gets a new entry: started, succeeded, failed, how many rows, what went wrong etc. 
-- Rows are never updated or deleted 
-- You use it to troubleshoot failures and prove to auditors that data loaded correctly.

-- =============================================
-- Immutable log of every pipeline run
-- Once logged, never updated (append-only)



IF OBJECT_ID('dbo.etl_execution_log', 'U') IS NOT NULL
    DROP TABLE dbo.etl_execution_log;
GO

CREATE TABLE dbo.etl_execution_log (
	execution_id int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	source_id int FOREIGN KEY (source_id) REFERENCES dbo.etl_source_config(source_id),
	pipeline_run_id nvarchar(100) NOT NULL,
	pipeline_name nvarchar(100) NOT NULL,
	activity_name nvarchar(100)NOT NULL,
	execution_date datetime2 NOT NULL,
	completion_date datetime2,
	status nvarchar(20) NOT NULL,    -- 'STARTED', 'SUCCESS', 'FAILED', 'QUARANTINED'
	rows_processed int NULL,
	rows_failed int NULL,
	error_message nvarchar(1000) NULL,
	created_date datetime2 DEFAULT GETDATE()
);

CREATE INDEX idx_execution_status ON dbo.etl_execution_log(status);
CREATE INDEX idx_execution_date ON dbo.etl_execution_log(execution_date);
GO



-- =============================================
-- STORED PROCEDURE 1: sp_log_pipeline_execution
-- =============================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.sp_log_pipeline_execution', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_log_pipeline_execution;
GO

 CREATE PROCEDURE [dbo].[sp_log_pipeline_execution]
    @ExecutionId INT = NULL,
	@SourceId INT = NULL,
    @PipelineRunId NVARCHAR(100) = NULL,
	@PipelineName NVARCHAR(100) = NULL,
	@ActivityName NVARCHAR(100) = NULL,
    @Status NVARCHAR(20) = NULL,
    @RowsProcessed INT = 0,
    @RowsFailed INT = 0,
    @ErrorMessage NVARCHAR(1000) = NULL

AS
BEGIN
    SET NOCOUNT ON;

    -- MODE 1: START (Insert new record)
    IF @ExecutionId IS NULL
    BEGIN
        INSERT INTO dbo.etl_execution_log (
            pipeline_name, 
            source_id, 
            execution_date, 
            status, 
            pipeline_run_id,
            activity_name
        )
        VALUES (
            @PipelineName, 
            @SourceId, 
            GETUTCDATE(), -- Logs the start time in UTC
            @Status, 
            @PipelineRunId,
			@ActivityName
        );

        -- Returns the auto-generated Identity value to your ADF Lookup task
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS execution_id; 
    END

    -- MODE 2: END (Update existing record)
    ELSE
    BEGIN
        UPDATE dbo.etl_execution_log
        SET status = @Status,
            completion_date = GETUTCDATE(), -- Logs the end time to calculate duration
            rows_processed = @RowsProcessed,
            rows_failed = @RowsFailed,
            error_message = @ErrorMessage,
			activity_name = @ActivityName
        WHERE execution_id = @ExecutionId;
    END
END;

GO



-- =============================================
-- STORED PROCEDURE 2: sp_update_watermark
-- =============================================

IF OBJECT_ID('dbo.sp_update_watermark', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_update_watermark;
GO

CREATE PROCEDURE dbo.sp_update_watermark
    @SourceId INT,
    @WatermarkColumn NVARCHAR(100),
    @NewWatermarkValue NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM dbo.etl_watermark 
               WHERE source_id = @SourceId 
               AND watermark_column = @WatermarkColumn)
    BEGIN
        UPDATE dbo.etl_watermark
        SET last_watermark_value = current_watermark_value,
            current_watermark_value = @NewWatermarkValue,
            load_date = GETDATE()
        WHERE source_id = @SourceId
        AND watermark_column = @WatermarkColumn;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.etl_watermark (
            source_id, watermark_column, last_watermark_value,
            current_watermark_value, load_date
        )
        VALUES (
            @SourceId, @WatermarkColumn, NULL,
            @NewWatermarkValue, GETDATE()
        );
    END;
END;
GO

-- =============================================
-- STORED PROCEDURE 3: sp_get_source_config
-- =============================================

IF OBJECT_ID('dbo.sp_get_source_config', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_get_source_config;
GO

CREATE PROCEDURE dbo.sp_get_source_config
    @SourceId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        source_id, source_name, source_type, file_path,
        table_name, load_type, merge_key, is_active
    FROM dbo.etl_source_config
    WHERE is_active = 1
    AND (@SourceId IS NULL OR source_id = @SourceId) -- Call 1: No parameter passed, i.e. @SourceId = NULL (get ALL active sources) 
    ORDER BY source_id;                              -- Call 2: Specific @SourceId passed (get ONE source)
END;
GO

-- =============================================
-- VERIFICATION
-- =============================================

PRINT '';
PRINT '=== Control Database Created ===';
SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

GO

-- Verify 3 tables exist
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
-- Should return: etl_execution_log, etl_source_config, etl_watermark

-- Verify 3 stored procedures exist
SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;
-- Should return: sp_get_source_config, sp_log_pipeline_execution, sp_update_watermark

