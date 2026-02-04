# 🏗️ Azure Data Engineering Pipeline — Medallion Architecture

<div align="center">

![Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Databricks](https://img.shields.io/badge/Databricks-FF3621?style=for-the-badge&logo=databricks&logoColor=white)
![PySpark](https://img.shields.io/badge/PySpark-E25A1C?style=for-the-badge&logo=apachespark&logoColor=white)
![SQL](https://img.shields.io/badge/Azure_SQL-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)

**End-to-end data pipeline implementing the Bronze-Silver-Gold (Medallion) Architecture pattern on Azure**

[Overview](#-overview) • [Architecture](#-architecture) • [Setup](#-setup) • [Pipeline Steps](#-pipeline-steps) • [Key Learnings](#-key-learnings)

</div>

---

## 📋 Overview

This project demonstrates a production-grade **Medallion Architecture** implementation using Azure's modern data stack. The pipeline ingests raw data from Azure SQL Database, processes it through transformation layers, and produces clean, analytics-ready datasets.

### 🎯 Business Use Case

Simulating an enterprise data lakehouse where:
- **Raw transactional data** lands in the Bronze layer
- **Cleaned & validated data** moves to Silver layer
- **Aggregated business metrics** are served from Gold layer (for BI/ML)

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MEDALLION ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────┐      ┌──────────────┐      ┌──────────────┐             │
│   │              │      │              │      │              │             │
│   │    BRONZE    │ ───► │    SILVER    │ ───► │     GOLD     │             │
│   │   (Raw)      │      │  (Cleaned)   │      │ (Aggregated) │             │
│   │              │      │              │      │              │             │
│   └──────────────┘      └──────────────┘      └──────────────┘             │
│         ▲                                                                   │
│         │                                                                   │
│   ┌─────┴────────┐                                                         │
│   │ Azure SQL DB │                                                         │
│   │ (Source)     │                                                         │
│   └──────────────┘                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

                            DATA FLOW
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Azure SQL  │ ──► │    Data     │ ──► │ Databricks  │ ──► │   ADLS      │
│  Database   │     │   Factory   │     │  (PySpark)  │     │  Gen2       │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
    Source           Ingestion          Transformation        Storage
```

### Layer Descriptions

| Layer | Purpose | Data State | Storage |
|-------|---------|------------|---------|
| 🥉 **Bronze** | Landing zone for raw data | Unprocessed, as-is from source | `bronze/` container |
| 🥈 **Silver** | Cleaned & validated data | Deduplicated, typed, enriched | `silver/` container |
| 🥇 **Gold** | Business-ready aggregates | Aggregated, metrics, KPIs | `gold/` container |

---

## 🛠️ Tech Stack

| Component | Azure Service | Purpose |
|-----------|---------------|---------|
| **Source Database** | Azure SQL Database | Transactional data source |
| **Storage** | ADLS Gen2 (Storage Account) | Data Lake with hierarchical namespace |
| **Ingestion** | Azure Data Factory | ETL/ELT orchestration |
| **Processing** | Azure Databricks | Spark-based transformations |
| **Security** | SAS Tokens | Secure container access |
| **Compute** | Databricks Clusters | Distributed processing |

---

## 📁 Project Structure

```
azure-medallion-pipeline/
├── notebooks/
│   ├── 01_bronze_to_silver.py      # Bronze → Silver transformation
│   ├── 02_silver_to_gold.py        # Silver → Gold aggregation
│   └── 03_data_quality_checks.py   # Data validation scripts
├── scripts/
│   ├── setup_azure_resources.sh    # Azure CLI setup commands
│   └── sql_sample_data.sql         # Sample data for Azure SQL
├── docs/
│   ├── architecture_diagram.png    # Visual architecture
│   └── setup_guide.md              # Detailed setup instructions
├── images/
│   └── screenshots/                # Azure portal screenshots
├── README.md
└── requirements.txt
```

---

## 🚀 Pipeline Steps

### Step 1: Azure Infrastructure Setup

```bash
# Create Resource Group
az group create --name rg-medallion-demo --location uksouth

# Create Storage Account (ADLS Gen2)
az storage account create \
  --name stmedalliondata \
  --resource-group rg-medallion-demo \
  --location uksouth \
  --sku Standard_LRS \
  --kind StorageV2 \
  --hierarchical-namespace true

# Create containers
az storage container create --name bronze --account-name stmedalliondata
az storage container create --name silver --account-name stmedalliondata
az storage container create --name gold --account-name stmedalliondata
```

### Step 2: Data Ingestion (Azure Data Factory)

- Created **Linked Service** to Azure SQL Database
- Created **Linked Service** to ADLS Gen2 (Bronze container)
- Built **Copy Activity** pipeline:
  - Source: Azure SQL table
  - Sink: Bronze container (Parquet format)
  - Schedule: On-demand / Triggered

### Step 3: Bronze → Silver Transformation (Databricks)

```python
# notebooks/01_bronze_to_silver.py

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp, col

# Initialize Spark Session
spark = SparkSession.builder.appName("BronzeToSilver").getOrCreate()

# Mount Bronze container (using SAS token)
bronze_path = "wasbs://bronze@stmedalliondata.blob.core.windows.net/"

# Read raw data from Bronze
df_bronze = spark.read.parquet(f"{bronze_path}/raw_customers/")

# === TRANSFORMATIONS ===
df_silver = df_bronze \
    .dropDuplicates(["customer_id"]) \
    .withColumn("LoadedDate", current_timestamp()) \
    .withColumn("customer_id", col("customer_id").cast("integer")) \
    .filter(col("email").isNotNull())

# Write to Silver layer
silver_path = "wasbs://silver@stmedalliondata.blob.core.windows.net/"
df_silver.write.mode("overwrite").parquet(f"{silver_path}/customers_cleaned/")

print(f"✅ Processed {df_silver.count()} records to Silver layer")
```

### Step 4: Silver → Gold Aggregation (Databricks)

```python
# notebooks/02_silver_to_gold.py

from pyspark.sql.functions import count, sum, avg

# Read from Silver
df_silver = spark.read.parquet(f"{silver_path}/customers_cleaned/")

# === BUSINESS AGGREGATIONS ===
df_gold = df_silver.groupBy("region", "subscription_type").agg(
    count("customer_id").alias("total_customers"),
    sum("revenue").alias("total_revenue"),
    avg("lifetime_value").alias("avg_ltv")
)

# Write to Gold layer
gold_path = "wasbs://gold@stmedalliondata.blob.core.windows.net/"
df_gold.write.mode("overwrite").parquet(f"{gold_path}/customer_metrics/")

print("✅ Gold layer aggregations complete!")
```

---

## 📊 Data Quality Checks

Implemented validation between layers:

```python
# Row count validation
assert df_silver.count() <= df_bronze.count(), "Silver should not have more rows than Bronze"

# Null check on key columns
null_count = df_silver.filter(col("customer_id").isNull()).count()
assert null_count == 0, f"Found {null_count} null customer_ids"

# Schema validation
expected_cols = ["customer_id", "email", "region", "LoadedDate"]
assert all(c in df_silver.columns for c in expected_cols), "Missing expected columns"
```

---

## 🔐 Security Implementation

| Aspect | Implementation |
|--------|----------------|
| **Storage Access** | SAS tokens with time-limited access |
| **Network** | Private endpoints (production recommendation) |
| **Secrets** | Azure Key Vault integration |
| **RBAC** | Storage Blob Data Contributor role |

---

## 📈 Key Learnings

1. **Medallion Architecture** separates concerns and improves data quality
2. **Azure Data Factory** excels at source-to-landing ingestion
3. **Databricks + PySpark** provides scalable transformation capabilities
4. **ADLS Gen2** with hierarchical namespace is ideal for data lakes
5. **SAS tokens** provide secure, scoped access to storage containers

---

## 🏢 Real-World Applications

This architecture pattern is used by:

| Company | Use Case |
|---------|----------|
| **Netflix** | Content analytics & recommendations |
| **Uber** | Real-time ride data processing |
| **Databricks** | Internal analytics platform |
| **Airbnb** | Booking & pricing analytics |

---

## 🔄 Future Enhancements

- [ ] Add **Gold layer** aggregations for BI dashboards
- [ ] Implement **Delta Lake** for ACID transactions
- [ ] Add **Azure Synapse** integration for SQL analytics
- [ ] Create **Power BI** dashboard connected to Gold layer
- [ ] Implement **CI/CD** with Azure DevOps

---

## 👤 Author

**Rakesh Mohankumar**  
MSc Business Analytics | University of Exeter

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://linkedin.com/in/rakeshtiya)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/rakeshtiya)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**⭐ If you found this helpful, please star the repository!**

</div>
