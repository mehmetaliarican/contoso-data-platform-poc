# Storage Module - ADLS Gen2 Configuration

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

variable "storage_account_name" {
  description = "Storage account name (globally unique)"
  type        = string
}

variable "storage_account_tier" {
  description = "Storage tier (Standard/Premium)"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Replication type (LRS/GRS/ZRS)"
  type        = string
  default     = "LRS"
}

variable "raw_container_name" {
  description = "Name of raw data container"
  type        = string
  default     = "raw"
}

variable "hub_container_name" {
  description = "Name of data hub container"
  type        = string
  default     = "datahub"
}

variable "archive_container_name" {
  description = "Name of archive container"
  type        = string
  default     = "archive"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Storage Account with Hierarchical Namespace (ADLS Gen2)
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"
  
  # Enable ADLS Gen2
  is_hns_enabled = true
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  
  # Blob properties - versioning not compatible with HNS (ADLS Gen2)
  blob_properties {
    change_feed_enabled = true
    
    delete_retention_policy {
      days = 7
    }
    
    container_delete_retention_policy {
      days = 7
    }
  }
  
  # Network rules (allow all for PoC - restrict in production)
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
  
  tags = var.tags
}

# Raw Container
resource "azurerm_storage_container" "raw" {
  name                  = var.raw_container_name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Data Hub Container
resource "azurerm_storage_container" "hub" {
  name                  = var.hub_container_name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Archive Container
resource "azurerm_storage_container" "archive" {
  name                  = var.archive_container_name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Outputs
output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_key" {
  description = "Storage account primary access key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "storage_account_primary_endpoint" {
  description = "Primary DFS endpoint"
  value       = azurerm_storage_account.main.primary_dfs_endpoint
}

output "raw_container_name" {
  description = "Raw container name"
  value       = azurerm_storage_container.raw.name
}

output "hub_container_name" {
  description = "Data hub container name"
  value       = azurerm_storage_container.hub.name
}

output "archive_container_name" {
  description = "Archive container name"
  value       = azurerm_storage_container.archive.name
}
