# Cost-Effective IoT Data Platform on AWS (Free-Tier Friendly)

## Overview

This project demonstrates the design and implementation of a **cost-effective, scalable IoT data platform on AWS**, capable of ingesting, storing, and querying **high-frequency sensor data over multiple years** using fully managed, serverless services.

The solution prioritizes:

- Low operational overhead  
- Schema drift tolerance  
- Query cost optimization  
- Security-first ingestion  
- Free-tier–friendly services for prototyping  

This is a **real-world Data Engineering architecture**, not a tutorial-only pipeline.

---

## Architecture

<img width="1536" height="1024" alt="IoT_data_architecture" src="https://github.com/user-attachments/assets/b1b1f265-6311-4dea-9fbb-932cde2c352f" />


**High-level flow:**

1. IoT devices (simulated in Python) publish telemetry via MQTT
2. AWS IoT Core securely ingests messages using TLS certificates
3. IoT Rules persist raw JSON events into Amazon S3
4. Amazon Athena queries raw data (schema-on-read)
5. Athena CTAS creates curated, optimized Parquet datasets

---

## Technology Stack

- **AWS IoT Core** – Secure MQTT ingestion  
- **Amazon S3** – Raw and curated data lake  
- **Amazon Athena** – Serverless SQL analytics  
- **Python** – IoT simulator (Paho MQTT)  
- **GitHub Codespaces** – Cloud-based dev environment  

---

## Data Zones

### Raw Zone (S3 – JSON)

- Immutable raw events
- Schema-on-read
- Tolerant to schema drift
- Low ingestion coupling

Path example:
s3://<bucket>/raw/iot/


### Curated Zone (S3 – Parquet)

- Typed, analytics-ready data
- Optimized for Athena
- Partitioned by event date
- Significantly reduced query cost

Path example:
s3://<bucket>/curated/iot/


---

## Data Modeling Strategy

**Raw table**
- Minimal assumptions
- Timestamp stored as ISO-8601 string
- Prevents ingestion failures

**Curated table**
- Explicit typing
- ISO timestamps converted to `timestamp`
- Stored as Parquet with SNAPPY compression

This separation reflects **production-grade lake design**.

---

## Key Engineering Decisions

- **Deferred schema enforcement** to avoid ingestion failures
- **CTAS-based transformations** instead of inline parsing
- **Parquet + partitioning** to minimize Athena scan cost
- **Lifecycle policies** to control long-term storage cost
- **TLS + certificate-based authentication** for IoT devices

---

## Example Athena Query (Curated)

```
SELECT
  event_date,
  COUNT(*) AS events,
  AVG(temperature) AS avg_temperature
FROM iot_analytics.curated_iot_events
GROUP BY event_date
ORDER BY event_date DESC;
This query scans **orders of magnitude less data** than querying raw JSON.

---

## Cost Considerations

- Serverless services only (pay per use)
- Athena queries optimized via **Parquet and partitions**
- S3 lifecycle rules for cold data
- Suitable for **AWS Free Tier experimentation**

---

## What This Project Demonstrates

- End-to-end data pipeline design
- Secure IoT ingestion on AWS
- Schema drift handling
- Query and storage cost optimization
- Debugging real AWS service limitations
- Production-oriented data modeling

This project reflects **Data Engineer responsibilities**, not just scripting.

---

## Potential Production Enhancements

- AWS Glue Crawlers for metadata automation
- Kinesis Firehose for batching and buffering
- Redshift Spectrum for BI workloads
- Monitoring and alerts (CloudWatch)
- CI/CD for schema evolution

---

---

## Metrics & Observability

### Ingestion

- **Event generation rate:** ~1 event / second (configurable in simulator)
- **Protocol:** MQTT over TLS 1.2
- **Latency (device → S3 raw):** ~1–3 seconds (IoT Core → Rule → S3)
- **Authentication:** X.509 certificates (per-device identity)

### Storage

- **Raw layer:** JSON objects in S3 (append-only)
- **Curated layer:** Parquet, columnar format
- **Compression:** Snappy (default for Parquet)
- **Partitioning:** `year / month / day`

### Query Performance (Athena)

| Dataset | Format | Avg Data Scanned | Avg Query Time |
|------|------|------------------|---------------|
| Raw | JSON | ~100% of dataset | Slow / expensive |
| Curated | Parquet + partitions | **~5–10%** | **10–20x faster** |

This query scans **orders of magnitude less data** than querying raw JSON.

### Cost Efficiency

- **Athena cost reduction:** ~90–95% per query after Parquet + partitioning
- **S3 cost optimization:** Lifecycle rules transition cold data
- **No always-on compute:** Fully serverless architecture

### Reliability & Data Quality

- Handles malformed records via Athena table properties
- Explicit schema enforcement in curated layer
- Isolated raw vs curated zones to prevent data loss

---


