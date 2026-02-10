# Main Terraform config - creates all Azure resources

# Resource group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Storage account (ADLS Gen2)
module "storage" {
  source = "./modules/storage"
  
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  storage_account_name     = local.storage_account_name
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type
  
  raw_container_name     = local.raw_container_name
  hub_container_name     = local.hub_container_name
  archive_container_name = local.archive_container_name
  
  tags = local.common_tags
}

# Key Vault for secrets
module "keyvault" {
  source = "./modules/keyvault"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  key_vault_name      = local.key_vault_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  tags = local.common_tags
}

# Databricks workspace
module "databricks" {
  source = "./modules/databricks"

  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  workspace_name       = local.databricks_name
  sku                  = var.databricks_sku

  create_service_principal = var.create_service_principal

  key_vault_id         = module.keyvault.key_vault_id
  key_vault_uri        = module.keyvault.key_vault_uri
  storage_account_name = module.storage.storage_account_name
  storage_account_key  = module.storage.storage_account_primary_key

  tags = local.common_tags
}

# Random suffix for storage (needs to be unique)
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Service Principal for Databricks to access storage
resource "azuread_application" "databricks_sp" {
  count        = var.create_service_principal ? 1 : 0
  display_name = "sp-${local.resource_prefix}-databricks"
  
  owners = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "databricks_sp" {
  count     = var.create_service_principal ? 1 : 0
  client_id = azuread_application.databricks_sp[0].client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "databricks_sp" {
  count                = var.create_service_principal ? 1 : 0
  service_principal_id = azuread_service_principal.databricks_sp[0].object_id
  end_date             = "2099-01-01T00:00:00Z"
}

# Give SP access to storage
resource "azurerm_role_assignment" "sp_storage_blob_contributor" {
  count                = var.create_service_principal ? 1 : 0
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.databricks_sp[0].object_id
}

# Save SP credentials in Key Vault
resource "azurerm_key_vault_secret" "sp_client_id" {
  count        = var.create_service_principal ? 1 : 0
  name         = "sp-client-id"
  value        = azuread_application.databricks_sp[0].client_id
  key_vault_id = module.keyvault.key_vault_id
}

resource "azurerm_key_vault_secret" "sp_client_secret" {
  count        = var.create_service_principal ? 1 : 0
  name         = "sp-client-secret"
  value        = azuread_service_principal_password.databricks_sp[0].value
  key_vault_id = module.keyvault.key_vault_id
}

resource "azurerm_key_vault_secret" "sp_tenant_id" {
  count        = var.create_service_principal ? 1 : 0
  name         = "sp-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = module.keyvault.key_vault_id
}

# Save storage account key in Key Vault
resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = module.storage.storage_account_primary_key
  key_vault_id = module.keyvault.key_vault_id
}

# Save storage account name in Key Vault
resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = module.storage.storage_account_name
  key_vault_id = module.keyvault.key_vault_id
}

# Log Analytics (optional)
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.create_log_analytics ? 1 : 0
  name                = local.log_analytics_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# Data Factory (optional)
resource "azurerm_data_factory" "main" {
  count               = var.create_data_factory ? 1 : 0
  name                = local.data_factory_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.common_tags
}

# Give ADF access to storage
resource "azurerm_role_assignment" "adf_storage" {
  count                = var.create_data_factory ? 1 : 0
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.main[0].identity[0].principal_id
}

# SQL Server (optional)
resource "azurerm_mssql_server" "main" {
  count                        = var.create_sql_server ? 1 : 0
  name                         = local.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password != null ? var.sql_admin_password : random_password.sql_admin[0].result
  
  tags = local.common_tags
}

resource "random_password" "sql_admin" {
  count   = var.create_sql_server && var.sql_admin_password == null ? 1 : 0
  length  = 16
  special = true
}

# Allow Azure services to connect to SQL
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count            = var.create_sql_server ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Create SQL Database
resource "azurerm_mssql_database" "main" {
  count     = var.create_sql_server ? 1 : 0
  name      = "contoso"
  server_id = azurerm_mssql_server.main[0].id
  sku_name  = "Basic"

  tags = local.common_tags
}

# Save SQL password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  count        = var.create_sql_server ? 1 : 0
  name         = "sql-admin-password"
  value        = var.sql_admin_password != null ? var.sql_admin_password : random_password.sql_admin[0].result
  key_vault_id = module.keyvault.key_vault_id
}
