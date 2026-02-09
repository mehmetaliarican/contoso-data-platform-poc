# Databricks notebook source
# MAGIC %md
# MAGIC # Extract to Raw Zone

# COMMAND ----------

import json
from pyspark.sql import functions as F

# COMMAND ----------

catalogs_df = spark.sql("SHOW CATALOGS").filter("catalog LIKE 'dbw_contoso_dev%'")
CATALOG = catalogs_df.collect()[0][0] if catalogs_df.count() > 0 else None

if not CATALOG:
    raise Exception("Can't find the catalog. Did you run 01_setup.py first?")

spark.sql(f"USE CATALOG {CATALOG}")

storage_account = "stcontosodevu4w2l7"
raw_container = "raw"

sql_username = "contoso-admin"
try:
    sql_password = dbutils.secrets.get("contoso-secrets", "sql-admin-password")
    print("Got SQL password from Key Vault")
except Exception as e:
    sql_password = "your-password-here"
    print(f"Couldn't get password from Key Vault: {e}")

print(f"Using catalog: {CATALOG}")
print(f"Storage: {storage_account}")

# COMMAND ----------

try:
    username = spark.conf.get("spark.databricks.clusterUsageTags.clusterOwnerOrgId")
except:
    try:
        username = dbutils.notebook.entry_point.getDbutils().notebook().getContext().userName().get()
    except:
        username = "user"

metadata_path = f"/Workspace/Repos/{username}/contoso-data-platform-poc/metadata/sources.json"

try:
    with open(metadata_path, 'r') as f:
        metadata = json.load(f)
    sources = metadata.get("sources", [])
    print(f"Found {len(sources)} sources to process")
except Exception as e:
    print(f"Couldn't load sources.json: {e}")
    sources = []

# COMMAND ----------

def extract_sql_server(source):
    conn = source["connection"]
    source_id = source["source_id"]
    raw_path = f"abfss://{raw_container}@{storage_account}.dfs.core.windows.net/{source_id}/"
    
    print(f"Extracting {source_id} from SQL Server...")
    
    try:
        df = (spark.read
            .format("jdbc")
            .option("url", f"jdbc:sqlserver://{conn['server']}:1433;database={conn['database']}")
            .option("dbtable", conn['table'])
            .option("user", sql_username)
            .option("password", sql_password)
            .option("encrypt", "true")
            .load())
        
        df_with_meta = (df
            .withColumn("_extracted_at", F.current_timestamp())
            .withColumn("_source", F.lit(source_id))
            .withColumn("_source_type", F.lit("sql_server"))
        )
        
        df_with_meta.write.mode("overwrite").parquet(raw_path)
        
        count = df_with_meta.count()
        print(f"Written {count} rows to {raw_path}")
        return True
        
    except Exception as e:
        print(f"Error: {e}")
        return False

def extract_csv(source):
    source_id = source["source_id"]
    csv_filename = source_id.replace("_csv", "")
    csv_path = f"/Workspace/Repos/{username}/contoso-data-platform-poc/metadata/{csv_filename}.csv"
    raw_path = f"abfss://{raw_container}@{storage_account}.dfs.core.windows.net/{source_id}/"
    
    print(f"Extracting {source_id} from CSV...")
    
    try:
        df = spark.read.option("header", "true").option("inferSchema", "true").csv(csv_path)
        
        df_with_meta = (df
            .withColumn("_extracted_at", F.current_timestamp())
            .withColumn("_source", F.lit(source_id))
            .withColumn("_source_type", F.lit("csv_file"))
        )
        
        df_with_meta.write.mode("overwrite").parquet(raw_path)
        
        count = df_with_meta.count()
        print(f"Written {count} rows to {raw_path}")
        return True
        
    except Exception as e:
        print(f"Error: {e}")
        return False

# COMMAND ----------

print("="*50)
print("Starting extraction...")
print("="*50)

for source in sources:
    if not source.get("enabled", True):
        continue
        
    source_type = source.get("type", "csv")
    
    if source_type == "sql_server":
        extract_sql_server(source)
    elif source_type == "csv":
        extract_csv(source)
    else:
        print(f"Unknown source type: {source_type}")

print("\n" + "="*50)
print("Extraction complete!")
print("Next: Run 03_load_to_hub.py")
print("="*50)
