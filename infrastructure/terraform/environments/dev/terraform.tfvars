# Development Environment Configuration
# Usage: terraform plan -var-file=environments/dev/terraform.tfvars

environment = "dev"
location    = "northeurope"
project_name = "contoso"

# Storage Configuration
storage_account_tier     = "Standard"
storage_replication_type = "LRS"

# Databricks Configuration
databricks_sku = "premium"

# Features
create_service_principal = true
create_log_analytics     = true
create_data_factory      = true
create_sql_server        = true

# SQL Server (if enabled)
sql_admin_username = "contoso-admin"
# sql_admin_password = set via environment variable TF_VAR_sql_admin_password

# Tags
common_tags = {
  Project     = "Contoso Data Platform"
  Environment = "Development"
  ManagedBy   = "Terraform"
  CostCenter  = "IT-Data"
}
