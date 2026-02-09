# Terraform Outputs

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.main.id
}

# Storage Outputs
output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage.storage_account_name
}

output "storage_account_primary_endpoint" {
  description = "Storage account DFS endpoint"
  value       = module.storage.storage_account_primary_endpoint
}

output "raw_container_name" {
  description = "Raw container name"
  value       = module.storage.raw_container_name
}

output "hub_container_name" {
  description = "Data hub container name"
  value       = module.storage.hub_container_name
}

# Key Vault Outputs
output "key_vault_name" {
  description = "Key Vault name"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.keyvault.key_vault_uri
}

# Databricks Outputs
output "databricks_workspace_name" {
  description = "Databricks workspace name"
  value       = module.databricks.workspace_name
}

output "databricks_workspace_url" {
  description = "Databricks workspace URL"
  value       = module.databricks.workspace_url
}

output "databricks_cluster_id" {
  description = "Databricks cluster ID"
  value       = module.databricks.cluster_id
}

output "databricks_secret_scope" {
  description = "Databricks secret scope name"
  value       = module.databricks.secret_scope_name
}

# Service Principal Outputs (sensitive)
output "service_principal_client_id" {
  description = "Service Principal Client ID"
  value       = var.create_service_principal ? azuread_application.databricks_sp[0].client_id : null
  sensitive   = true
}

output "service_principal_object_id" {
  description = "Service Principal Object ID"
  value       = var.create_service_principal ? azuread_service_principal.databricks_sp[0].object_id : null
  sensitive   = true
}

# SQL Server Output (if created)
output "sql_server_fqdn" {
  description = "SQL Server FQDN"
  value       = var.create_sql_server ? azurerm_mssql_server.main[0].fully_qualified_domain_name : null
}

# Data Factory Output (if created)
output "data_factory_name" {
  description = "Data Factory name"
  value       = var.create_data_factory ? azurerm_data_factory.main[0].name : null
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value       = <<EOF

============================================
  CONTOSO DATA PLATFORM DEPLOYMENT COMPLETE
============================================

Resource Group:     ${azurerm_resource_group.main.name}
Location:           ${var.location}
Environment:        ${var.environment}

Storage Account:    ${module.storage.storage_account_name}
  - Raw Container:  ${module.storage.raw_container_name}
  - Hub Container:  ${module.storage.hub_container_name}

Key Vault:          ${module.keyvault.key_vault_name}

Databricks:         ${module.databricks.workspace_name}
  URL:              ${module.databricks.workspace_url}

Service Principal:  ${var.create_service_principal ? azuread_application.databricks_sp[0].display_name : "Not created"}

Next Steps:
1. Access Databricks: ${module.databricks.workspace_url}
2. Configure secrets in Key Vault
3. Clone repo to Databricks
4. Run notebooks 01-05

============================================
EOF
}
