# Local Values for Resource Naming and Configuration
locals {
  # Normalize environment naming
  env_suffix = var.environment == "prod" ? "" : "-${var.environment}"
  
  # Resource naming convention
  resource_prefix = "${var.project_name}${local.env_suffix}"
  
  # Auto-generated resource group name
  resource_group_name = var.resource_group_name != null ? var.resource_group_name : "rg-${local.resource_prefix}-data"
  
  # Storage account name (must be globally unique and lowercase)
  storage_account_name = lower("st${var.project_name}${var.environment}${random_string.storage_suffix.result}")
  
  # Key Vault name
  key_vault_name = "kv-${local.resource_prefix}-data"
  
  # Databricks workspace name
  databricks_name = "dbw-${local.resource_prefix}"
  
  # Data Factory name (must be globally unique)
  data_factory_name = "adf-${local.resource_prefix}-mehmet"
  
  # Log Analytics name
  log_analytics_name = "log-${local.resource_prefix}"
  
  # SQL Server name
  sql_server_name = "sql-${local.resource_prefix}-ne"

  # Common tags with environment
  common_tags = merge(var.common_tags, {
    Environment = var.environment
  })
  
  # Container names for ADLS
  raw_container_name    = "raw"
  hub_container_name    = "datahub"
  archive_container_name = "archive"
}
