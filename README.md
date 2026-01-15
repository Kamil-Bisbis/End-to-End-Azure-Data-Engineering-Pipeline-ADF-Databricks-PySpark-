# End-to-End Azure Data Engineering Pipeline (ADF, Databricks, PySpark)

## Overview
This project implements an end-to-end data engineering pipeline on Microsoft Azure that ingests customer and sales data from a SQL source, processes it with Databricks, and publishes curated datasets for analytics and reporting. The pipeline is designed around reliability (repeatable runs, validation checks) and clear data modeling using a Bronze, Silver, and Gold lakehouse pattern.

## Architecture
High-level flow:
1. Source data (SQL Server / relational source)
2. Azure Data Factory (ADF) orchestrates ingestion into Azure Data Lake Storage Gen2 (ADLS)
3. Databricks processes raw data into cleansed and curated layers using PySpark and Spark SQL
4. Gold outputs are exposed for downstream analytics (optional: views / BI dashboard)

Core components:
- Azure Data Factory: orchestration + scheduled runs
- ADLS Gen2: storage for bronze/silver/gold layers
- Databricks: transformations, aggregations, and validation notebooks
- SQL (optional): serverless views over curated outputs

## Data Layers (Bronze, Silver, Gold)
- Bronze (raw): landed data from the source with minimal changes, used for traceability and replay
- Silver (cleansed): cleaned and standardized datasets (types, naming, joins, de-duplication where applicable)
- Gold (curated): analytics-ready tables (aggregations, KPI-ready datasets, reporting-friendly structures)

This structure keeps raw ingestion separate from business-facing outputs and supports iterative improvement without losing source fidelity.

## Incremental Load Strategy
The pipeline supports incremental loading patterns where new or updated records can be ingested and processed without rebuilding the entire dataset each run. Typical approaches include:
- watermark-based ingestion (e.g., last_modified timestamp)
- append + merge/upsert logic in Silver/Gold (Delta Lake-friendly)
- partitioned storage for scalable processing

Exact logic depends on the source tables and available change tracking fields, but the repo structure is built to support incremental extensions.

## Data Quality and Validation
To ensure reliable data for downstream use, the pipeline includes dedicated validation checks:
- row count checks across Bronze → Silver → Gold
- schema checks (missing columns + type mismatch warnings)
- null checks on required columns (primary keys and other required fields)
- duplicate checks on primary keys
- optional distinct-PK reconciliation between layers

These checks are designed to catch common pipeline failures early (schema drift, incomplete loads, unexpected drops, bad keys) and can be configured to fail the job when issues are detected.

Validation notebook:
- `databricks/04_data_quality_and_validation.ipynb`

## Orchestration and Monitoring
ADF is used to orchestrate the pipeline and schedule recurring runs. Monitoring is handled through:
- ADF pipeline run history (success/failure, duration, activity-level logging)
- Databricks notebook output (success/failure behavior for validation)
- re-runnable lakehouse layers (ability to reprocess Silver/Gold from Bronze if needed)

## Repository Structure
- `databricks/`
  - `01_adls_mount_and_access.ipynb.ipynb`  
    Mount/access ADLS data from Databricks
  - `02_bronze_to_silver_transformations.ipynb`  
    Cleansing and standardization (Silver)
  - `03_silver_to_gold_aggregations.ipynb`  
    Aggregations and curated outputs (Gold)
  - `04_data_quality_and_validation.ipynb`  
    Data quality checks (row counts, nulls, duplicates, schema checks)
- `sql/queries/`
  - `01_create_login.sql`  
    Create login/user for access
  - `02_grant_privileges.sql`  
    Grants and access control
  - `03_seed_source_data.sql`  
    Seed/insert source data for testing
  - `04_create_gold_views.sql`  
    Create analytics-friendly views over curated outputs
- `AdventureWorksLT2017.bak`  
  Sample database backup used as a source dataset
- `README.md`  
  Project documentation

## How to Run (High Level)
1. Provision Azure resources:
   - Resource Group
   - ADLS Gen2 (bronze/silver/gold containers or folders)
   - Databricks workspace
   - Azure Data Factory
   - (Optional) Key Vault for secret management

2. Load source dataset:
   - Restore the SQL database (example backup included)
   - Confirm connectivity from ADF to the SQL source

3. Ingest with ADF:
   - Create ADF pipelines to copy source tables into Bronze (ADLS Gen2)
   - Set scheduling as needed (daily or on-demand)

4. Transform in Databricks:
   - Run notebooks in order:
     - `01_adls_mount_and_access...`
     - `02_bronze_to_silver_transformations...`
     - `03_silver_to_gold_aggregations...`

5. Run validation:
   - Run `04_data_quality_and_validation.ipynb`
   - Update dataset paths + PK columns in the config block
   - Optionally set `FAIL_PIPELINE_ON_ERROR = True` for job enforcement

6. Consume Gold outputs:
   - Use SQL views or connect a BI tool to curated datasets for reporting

## Technologies Used
- Python, SQL
- PySpark, Spark SQL
- Azure Data Factory (ADF)
- Azure Databricks
- Azure Data Lake Storage Gen2 (ADLS)
- Delta Lake (if configured for Delta format)
- (Optional) Power BI for dashboards
- (Optional) Azure Key Vault for secret management
- (Optional) serverless SQL views over Gold outputs

## Notes
- Do not store credentials in the repo. Use Key Vault / secret scopes for authentication.
- The validation notebook is intentionally lightweight and configurable so it can be reused across datasets and pipelines.