# Databricks notebook source
# MAGIC %md
# MAGIC # Setup

# COMMAND ----------

%pip install delta-spark --quiet

# COMMAND ----------

from pyspark.sql import SparkSession

spark = (SparkSession.builder
    .appName("ContosoDataPlatform")
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
    .getOrCreate())

print(f"Spark ready: {spark.version}")

# COMMAND ----------

CONFIG = {
    "storage_account": "stcontosodevu4w2l7",
    "raw_container": "raw",
    "hub_container": "datahub",
}

print(f"Config ready: {CONFIG['storage_account']}")

# COMMAND ----------

catalogs_df = spark.sql("SHOW CATALOGS").filter("catalog LIKE 'dbw_contoso_dev%'")
CATALOG = catalogs_df.collect()[0][0] if catalogs_df.count() > 0 else None

if not CATALOG:
    raise Exception("Can't find the auto-created catalog. Check SHOW CATALOGS output.")

spark.sql(f"USE CATALOG {CATALOG}")
spark.sql("CREATE SCHEMA IF NOT EXISTS hub")
spark.sql("CREATE SCHEMA IF NOT EXISTS raw")

print(f"Setup complete!")
print(f"   Catalog: {CATALOG}")
print(f"   Schemas: hub, raw")
print("")
print("Next: Run 02_extract_to_raw.py")
