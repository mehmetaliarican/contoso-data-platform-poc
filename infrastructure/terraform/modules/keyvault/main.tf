# Key Vault Module

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
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

variable "key_vault_name" {
  description = "Key Vault name (globally unique)"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU (standard/premium)"
  type        = string
  default     = "standard"
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention in days"
  type        = number
  default     = 7
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled
  
  # Access policy for current user/service principal
  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
    key_permissions    = ["Get", "List", "Create", "Delete"]
  }
  
  # Network access (allow all for PoC - restrict in production)
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
  
  tags = var.tags
}

# Data source for current client config
data "azurerm_client_config" "current" {}

# Outputs
output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}
