# Databricks notebook source
# MAGIC %md
# MAGIC # Load to Data Hub

# COMMAND ----------

import json
from pyspark.sql import functions as F

# COMMAND ----------

catalogs_df = spark.sql("SHOW CATALOGS").filter("catalog LIKE 'dbw_contoso_dev%'")
CATALOG = catalogs_df.collect()[0][0] if catalogs_df.count() > 0 else None

if not CATALOG:
    raise Exception("Can't find the catalog. Run 01_setup.py first!")

spark.sql(f"USE CATALOG {CATALOG}")
spark.sql("CREATE SCHEMA IF NOT EXISTS hub")

storage_account = "stcontosodevu4w2l7"
raw_container = "raw"

print(f"Using catalog: {CATALOG}")

# COMMAND ----------

try:
    username = dbutils.notebook.entry_point.getDbutils().notebook().getContext().userName().get()
except:
    username = "mehmetaliarican@tutamail.com"

metadata_path = f"/Workspace/Users/{username}/contoso-data-platform/metadata/sources.json"

try:
    with open(metadata_path, 'r') as f:
        metadata = json.load(f)
    sources = metadata.get("sources", [])
    print(f"Found {len(sources)} sources to load")
except Exception as e:
    print(f"Couldn't load sources: {e}")
    sources = []

# COMMAND ----------

def load_to_hub(source):
    source_id = source["source_id"]
    hub_table = source["destination"]["hub_table"]
    raw_path = f"abfss://{raw_container}@{storage_account}.dfs.core.windows.net/{source_id}/"
    
    print(f"Loading {source_id} to {hub_table}...")
    
    try:
        df = spark.read.parquet(raw_path)
        
        df_with_meta = (df
            .withColumn("_loaded_at", F.current_timestamp())
            .withColumn("_load_job", F.lit("03_load_to_hub"))
        )
        
        df_with_meta.write.format("delta").mode("overwrite").saveAsTable(hub_table)
        
        count = df_with_meta.count()
        print(f"Loaded {count} rows into {hub_table}")
        return True
        
    except Exception as e:
        print(f"Error: {e}")
        return False

# COMMAND ----------

print("="*50)
print("Loading data to Data Hub...")
print("="*50)

for source in sources:
    if source.get("enabled", True):
        load_to_hub(source)

print("\n" + "="*50)
print("Done!")
print("="*50)

# COMMAND ----------

print("\nTables in Data Hub:")
spark.sql("SHOW TABLES IN hub").show()

print("\nSample data:")
for source in sources:
    if source.get("enabled", True):
        hub_table = source["destination"]["hub_table"]
        print(f"\n{hub_table}:")
        spark.sql(f"SELECT * FROM {hub_table} LIMIT 3").show()
        count = spark.table(hub_table).count()
        print(f"Total rows: {count}")
