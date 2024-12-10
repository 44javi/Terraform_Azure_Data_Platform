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
  sku                         = "premium"                                             # Chose premium for job clusters and private endpoint, Role-Based Access Control (RBAC), Audit Logs, and Cluster Policies.
  managed_resource_group_name = "${var.client}_databricks_rg_${var.suffix}" # Databricks creates a mandatory managed RG

  tags = var.default_tags

  #public_network_access_enabled = false  

  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = var.vnet_id
    public_subnet_name                                   = var.public_subnet_name
    private_subnet_name                                  = var.private_subnet_name
    public_subnet_network_security_group_association_id  = var.public_subnet_nsg_assoc_id
    private_subnet_network_security_group_association_id = var.private_subnet_nsg_assoc_id
  }
}