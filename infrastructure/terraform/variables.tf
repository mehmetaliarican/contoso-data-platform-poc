# Root Variables for Contoso Data Platform

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "contoso"
}

# Resource Group
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = null  # Auto-generated if not provided
}

# Storage Account Configuration
variable "storage_account_tier" {
  description = "Storage account tier (Standard/Premium)"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage replication type (LRS, GRS, ZRS)"
  type        = string
  default     = "LRS"
}

# Databricks Configuration
variable "databricks_sku" {
  description = "Databricks workspace SKU (standard/premium)"
  type        = string
  default     = "premium"
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Contoso Data Platform"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

# Service Principal
variable "create_service_principal" {
  description = "Create service principal for Databricks"
  type        = bool
  default     = true
}

# Data Factory
variable "create_data_factory" {
  description = "Create Azure Data Factory"
  type        = bool
  default     = false
}

# Monitoring
variable "create_log_analytics" {
  description = "Create Log Analytics workspace"
  type        = bool
  default     = true
}

# SQL Server for metadata (optional)
variable "create_sql_server" {
  description = "Create Azure SQL Server for metadata"
  type        = bool
  default     = false
}

variable "sql_admin_username" {
  description = "SQL Server admin username"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL Server admin password"
  type        = string
  default     = null
  sensitive   = true
}
