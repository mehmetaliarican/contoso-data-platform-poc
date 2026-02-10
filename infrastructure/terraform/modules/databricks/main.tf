# Databricks Module

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.0.0"
    }
  }
}

# Variables
variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "workspace_name" {
  description = "Databricks workspace name"
  type        = string
}

variable "sku" {
  description = "Workspace SKU (standard/premium)"
  type        = string
  default     = "premium"
}

variable "create_service_principal" {
  description = "Create service principal"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "Key Vault ID for secret scope"
  type        = string
}

variable "key_vault_uri" {
  description = "Key Vault URI for secret scope"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name for ADLS authentication"
  type        = string
}

variable "storage_account_key" {
  description = "Storage account primary access key"
  type        = string
  sensitive   = true
}

# Databricks Workspace
resource "azurerm_databricks_workspace" "main" {
  name                        = var.workspace_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku                         = var.sku
  managed_resource_group_name = "${var.workspace_name}-managed-rg"

  tags = var.tags
}

# Databricks Provider configuration for workspace resources
provider "databricks" {
  alias                       = "workspace"
  host                        = "https://${azurerm_databricks_workspace.main.workspace_url}/"
  azure_workspace_resource_id = azurerm_databricks_workspace.main.id
}

# Create a small single-node cluster for the PoC (cheapest option)
resource "databricks_cluster" "poc" {
  provider                = databricks.workspace
  cluster_name            = "poc-cluster"
  spark_version           = "13.3.x-scala2.12"
  node_type_id            = "Standard_D4ds_v5"
  autotermination_minutes = 30
  num_workers             = 0  # Single-node cluster
  data_security_mode      = "USER_ISOLATION"

  # Required for single-node cluster
  spark_conf = {
    "spark.databricks.cluster.profile"         = "singleNode"
    "spark.master"                             = "local[*]"
    "spark.databricks.delta.preview.enabled"   = "true"
    # ADLS Gen2 authentication using storage account key
    "fs.azure.account.key.${var.storage_account_name}.dfs.core.windows.net" = var.storage_account_key
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  depends_on = [azurerm_databricks_workspace.main, databricks_secret_scope.kv]
}

# Outputs
output "workspace_id" {
  description = "Databricks workspace ID"
  value       = azurerm_databricks_workspace.main.id
}

output "workspace_name" {
  description = "Databricks workspace name"
  value       = azurerm_databricks_workspace.main.name
}

output "workspace_url" {
  description = "Databricks workspace URL"
  value       = "https://${azurerm_databricks_workspace.main.workspace_url}/"
}

output "workspace_resource_id" {
  description = "Workspace Azure resource ID"
  value       = azurerm_databricks_workspace.main.id
}

output "cluster_id" {
  description = "ID of the created cluster"
  value       = databricks_cluster.poc.id
}

# Create secret scope backed by Key Vault
resource "databricks_secret_scope" "kv" {
  provider = databricks.workspace
  name     = "contoso-secrets"

  keyvault_metadata {
    resource_id = var.key_vault_id
    dns_name    = var.key_vault_uri
  }

  depends_on = [azurerm_databricks_workspace.main]
}

output "secret_scope_name" {
  description = "Name of the secret scope"
  value       = databricks_secret_scope.kv.name
}
