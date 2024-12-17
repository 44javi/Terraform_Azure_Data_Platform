# /modules/databricks_workspace/main.tf
/*
terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "1.5.0"
      configuration_aliases = [databricks.create_workspace]
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.9"
    }
  }
}
*/

# Create Azure Databricks Workspace with VNet injection
resource "azurerm_databricks_workspace" "this" {
  name                        = "${var.client}_databricks_workspace_${var.suffix}"
  resource_group_name         = var.resource_group_name
  location                    = var.region
  sku                         = "premium" # Chose premium for job clusters and private endpoint, Role-Based Access Control (RBAC), Audit Logs, and Cluster Policies.
  managed_resource_group_name = "${var.client}_databricks_rg_${var.suffix}" # Databricks creates a mandatory managed RG

  tags = var.default_tags

  #public_network_access_enabled = false  

  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = var.vnet_id
    public_subnet_name                                   = azurerm_subnet.databricks_public_subnet.name 
    private_subnet_name                                  = azurerm_subnet.databricks_private_subnet.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.nsg_assoc_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.nsg_assoc_private.id
  }
}

# Public Subnet for Databricks
resource "azurerm_subnet" "databricks_public_subnet" {
  name                 = "${var.client}_databricks_public_subnet_${var.suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_address_prefixes["databricks_public_subnet"]] 

  # Disable default outbound access
  default_outbound_access_enabled = false

  delegation {
    name = "databricks_delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

# Private or Container Subnet for Databricks 
resource "azurerm_subnet" "databricks_private_subnet" {
  name                 = "${var.client}_databricks_private_subnet_${var.suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_address_prefixes["databricks_private_subnet"]] 

  # Disable default outbound access
  default_outbound_access_enabled = false

  delegation {
    name = "databricks_delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}



# NSG for Public Subnet
resource "azurerm_network_security_group" "databricks_public_nsg" {
  name                = "${var.client}_databricks_public_nsg_${var.suffix}"
  location            = var.region
  resource_group_name = var.resource_group_name

}


# NSG for Private Subnet
resource "azurerm_network_security_group" "databricks_private_nsg" {
  name                = "${var.client}_databricks_private_nsg_${var.suffix}"
  location            = var.region
  resource_group_name = var.resource_group_name

}

# NSG association for Public Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_public" {
  subnet_id                 = azurerm_subnet.databricks_public_subnet.id
  network_security_group_id = azurerm_network_security_group.databricks_public_nsg.id
}


# NSG association for Private Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_private" {
  subnet_id                 = azurerm_subnet.databricks_private_subnet.id
  network_security_group_id = azurerm_network_security_group.databricks_private_nsg.id
}


# Associate the NAT Gateway with the Databricks Public Subnet
resource "azurerm_subnet_nat_gateway_association" "databricks_public" {
  subnet_id      = azurerm_subnet.databricks_public_subnet.id
  nat_gateway_id = var.nat_gateway_id
}

# Associate the NAT Gateway with the Databricks Private Subnet
resource "azurerm_subnet_nat_gateway_association" "databricks_private" {
  subnet_id      = azurerm_subnet.databricks_private_subnet.id
  nat_gateway_id = var.nat_gateway_id
}