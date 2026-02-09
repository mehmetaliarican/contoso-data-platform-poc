# Contoso Data Platform PoC

A data pipeline that pulls from SQL Server (OLAP) and CSV files, stores them in Azure Data Lake, then converts to Delta tables.

## Quick Start

### 1. Deploy Infrastructure

```bash
cd infrastructure/terraform
terraform init
terraform apply -var-file="environments/dev/terraform.tfvars"
```

Get your storage account name:
```bash
terraform output storage_account_name
```

### 2. Create SQL Table

Go to Azure Portal → SQL Server → Query Editor. Login with:
- Username: `contoso-admin`
- Password: `terraform output sql_admin_password`

Run the script in `sql/setup_olap.sql`.

### 3. Configure Databricks

1. In Databricks, go to **Compute** → Your cluster → **Edit**
2. **Spark Config** tab, add:

```
fs.azure.account.auth.type.YOUR_STORAGE_ACCOUNT.dfs.core.windows.net OAuth
fs.azure.account.oauth.provider.type.YOUR_STORAGE_ACCOUNT.dfs.core.windows.net org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider
fs.azure.account.oauth2.client.id.YOUR_STORAGE_ACCOUNT.dfs.core.windows.net {{secrets/contoso-secrets/sp-client-id}}
fs.azure.account.oauth2.client.secret.YOUR_STORAGE_ACCOUNT.dfs.core.windows.net {{secrets/contoso-secrets/sp-client-secret}}
fs.azure.account.oauth2.client.endpoint.YOUR_STORAGE_ACCOUNT.dfs.core.windows.net https://login.microsoftonline.com/{{secrets/contoso-secrets/sp-tenant-id}}/oauth2/token
```

3. **Restart cluster**

### 4. Run Notebooks

In Databricks, run in order:
1. `01_setup.py`
2. `02_extract_to_raw.py`
3. `03_load_to_hub.py`

### 5. Verify

```python
spark.sql("SHOW TABLES IN hub").show()
spark.table("hub.customers").show()
```

## Structure

```
infrastructure/terraform/   # Deploy Azure resources
notebooks/                  # Databricks notebooks
  01_setup.py              # Setup catalog/schemas
  02_extract_to_raw.py     # Extract to ADLS
  03_load_to_hub.py        # Load to Delta
metadata/                   # Source config & sample data
  sources.json             # Define data sources
  customers.csv            # Sample data
  products.csv             # Sample data
sql/                        # SQL scripts
  setup_olap.sql           # Create SalesFact table
```

## Cleanup

```bash
terraform destroy -var-file="environments/dev/terraform.tfvars"
```
