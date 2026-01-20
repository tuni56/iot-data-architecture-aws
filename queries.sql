-- =====================================================
-- FILE: queries.sql
-- PROJECT: Cost-Effective IoT Data Platform
-- PURPOSE: Define raw and curated Athena tables and
--          sample analytics queries.
-- =====================================================

-- =====================================================
-- 1. RAW LAYER: IoT events stored as JSON
-- Schema-on-read for flexibility and future schema evolution
-- =====================================================
CREATE EXTERNAL TABLE IF NOT EXISTS raw_iot_events (
    device_id STRING,
    timestamp STRING,
    temperature DOUBLE,
    humidity DOUBLE
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://iot-data-lake-rocio-demo/raw/iot/'
TBLPROPERTIES (
    'has_encrypted_data'='false',
    'projection.enabled'='false'
);

-- =====================================================
-- 2. CURATED LAYER: Optimized Parquet table for analytics
-- Partitioned by event_date for query efficiency
-- =====================================================
CREATE TABLE IF NOT EXISTS curated_iot_events
WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['event_date'],
    external_location = 's3://iot-data-lake-rocio-demo/curated/iot/'
) AS
SELECT
    device_id,
    CAST(from_iso8601_timestamp(timestamp) AS timestamp) AS event_timestamp,
    temperature,
    humidity,
    date(from_iso8601_timestamp(timestamp)) AS event_date
FROM raw_iot_events;

-- =====================================================
-- 3. SAMPLE ANALYTICS QUERY: Daily averages
-- Demonstrates scanning minimal data via partition pruning
-- =====================================================
SELECT
    event_date,
    AVG(temperature) AS avg_temperature,
    AVG(humidity) AS avg_humidity,
    COUNT(*) AS event_count
FROM curated_iot_events
WHERE event_date >= DATE '2024-01-01'
GROUP BY event_date
ORDER BY event_date DESC;

-- =====================================================
-- 4. SAMPLE ANALYTICS QUERY: Top active devices
-- =====================================================
SELECT
    device_id,
    COUNT(*) AS event_count
FROM curated_iot_events
WHERE event_date >= DATE '2024-01-01'
GROUP BY device_id
ORDER BY event_count DESC
LIMIT 10;

-- =====================================================
-- 5. SAMPLE ANALYTICS QUERY: Temperature thresholds
-- =====================================================
SELECT
    event_date,
    COUNT(*) AS high_temp_events
FROM curated_iot_events
WHERE temperature > 50
GROUP BY event_date
ORDER BY event_date DESC;

-- =====================================================
-- 6. PARTITION MANAGEMENT: Repair partitions after adding new data
-- Athena automatically detects partitions in S3 when using MSCK REPAIR TABLE
-- =====================================================
MSCK REPAIR TABLE curated_iot_events;

-- =====================================================
-- 7. SCHEMA EVOLUTION: Adding a new column (e.g., battery_level)
-- Step 1: Alter table to add new column
-- Step 2: Query includes new column, using COALESCE for backward compatibility
-- =====================================================
ALTER TABLE curated_iot_events
ADD COLUMN IF NOT EXISTS battery_level DOUBLE;

-- Query handling optional new column without breaking old data
SELECT
    device_id,
    event_timestamp,
    temperature,
    humidity,
    COALESCE(battery_level, 0) AS battery_level,
    event_date
FROM curated_iot_events
WHERE event_date >= DATE '2024-01-01'
ORDER BY event_timestamp DESC;

-- =====================================================
-- 8. AUTOMATED PARTITION ADDITION FOR NEW DATA
-- Use INSERT OVERWRITE or CTAS for new partitions if using Parquet
-- Example: Create partitioned daily table from staging raw data
-- =====================================================
CREATE TABLE IF NOT EXISTS curated_iot_events_partitioned
WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['event_date'],
    external_location = 's3://iot-data-lake-rocio-demo/curated/iot_partitioned/'
) AS
SELECT
    device_id,
    CAST(from_iso8601_timestamp(timestamp) AS timestamp) AS event_timestamp,
    temperature,
    humidity,
    date(from_iso8601_timestamp(timestamp)) AS event_date
FROM raw_iot_events
WHERE date(from_iso8601_timestamp(timestamp)) >= DATE '2026-01-01';

-- After adding new raw data daily, run:
MSCK REPAIR TABLE curated_iot_events_partitioned;
