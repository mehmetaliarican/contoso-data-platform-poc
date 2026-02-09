# Networking Module

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

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "create_vnet" {
  description = "Create new VNet"
  type        = bool
  default     = true
}

variable "address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_name" {
  description = "Public subnet name"
  type        = string
}

variable "public_subnet_prefix" {
  description = "Public subnet address prefix"
  type        = list(string)
}

variable "private_subnet_name" {
  description = "Private subnet name"
  type        = string
}

variable "private_subnet_prefix" {
  description = "Private subnet address prefix"
  type        = list(string)
}

variable "nsg_public_name" {
  description = "Public NSG name"
  type        = string
}

variable "nsg_private_name" {
  description = "Private NSG name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  count               = var.create_vnet ? 1 : 0
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Public Subnet (for Databricks public endpoints)
resource "azurerm_subnet" "public" {
  name                 = var.public_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.create_vnet ? azurerm_virtual_network.main[0].name : var.vnet_name
  address_prefixes     = var.public_subnet_prefix
  
  delegation {
    name = "databricks-delegation"
    
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
      ]
    }
  }
}

# Private Subnet (for Databricks private endpoints)
resource "azurerm_subnet" "private" {
  name                 = var.private_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.create_vnet ? azurerm_virtual_network.main[0].name : var.vnet_name
  address_prefixes     = var.private_subnet_prefix
  
  delegation {
    name = "databricks-delegation"
    
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
      ]
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "public" {
  name                = var.nsg_public_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_group" "private" {
  name                = var.nsg_private_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

# Outputs
output "vnet_id" {
  description = "Virtual network ID"
  value       = var.create_vnet ? azurerm_virtual_network.main[0].id : null
}

output "vnet_name" {
  description = "Virtual network name"
  value       = var.create_vnet ? azurerm_virtual_network.main[0].name : var.vnet_name
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = azurerm_subnet.public.id
}

output "public_subnet_name" {
  description = "Public subnet name"
  value       = azurerm_subnet.public.name
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = azurerm_subnet.private.id
}

output "private_subnet_name" {
  description = "Private subnet name"
  value       = azurerm_subnet.private.name
}
