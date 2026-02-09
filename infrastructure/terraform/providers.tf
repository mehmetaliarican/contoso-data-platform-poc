# Azure Provider Configuration
terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.28.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
  
  # No backend configured - uses local state for PoC
  # For production, add azurerm backend here
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  tenant_id       = "d9dcb628-52b6-4484-a2e2-f2c3f3cb95e0"
  subscription_id = "e3aa5e75-4120-4f5b-a0b2-52de389421e9"
  skip_provider_registration = true
}

provider "azuread" {
  # Uses Azure CLI or Service Principal credentials
}

# Data sources for current subscription
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
