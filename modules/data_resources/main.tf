# data_resources module

# Get Azure subscription details
data "azurerm_client_config" "current" {}

# Random string for storage names
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}

# Data Lake Storage
resource "azurerm_storage_account" "adls" {
  name                            = "datalakestorage${random_string.this.result}"
  resource_group_name             = var.resource_group_name
  location                        = var.region
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = "true"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true #false blocks access to containers on the portal unless ip range is allowed
  #shared_access_key_enabled = false

  

  tags = var.default_tags

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }

}

# Container for raw (input) data
resource "azurerm_storage_container" "bronze" {
  name                  = var.bronze_container
  storage_account_id    = azurerm_storage_account.adls.id
  container_access_type = "private"
}

# Container for processed (output) data
resource "azurerm_storage_container" "gold" {
  name                  = var.gold_container
  storage_account_id    = azurerm_storage_account.adls.id
  container_access_type = "private"
}

# Private Endpoint for ADLS (Azure Data Lake Storage)
resource "azurerm_private_endpoint" "adls" {
  name                = "${var.client}_adls-pe_${var.suffix}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  tags = var.default_tags

  private_service_connection {
    name                           = "adlsConnection"
    private_connection_resource_id = azurerm_storage_account.adls.id
    subresource_names              = ["dfs"] # For ADLS Gen2
    is_manual_connection           = false
  }
}

# Create Azure Databricks Workspace + VNet injection
resource "azurerm_databricks_workspace" "this" {
  name                          = "${var.client}_databricks_workspace_${var.suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.region
  sku                           = "premium"                                   # Chose premium for job clusters and private endpoint other extras are  Role-Based Access Control (RBAC), Audit Logs, and Cluster Policies.
  public_network_access_enabled = true                                        # For private connectivity set to false
  managed_resource_group_name   = "${var.client}_databricks_rg_${var.suffix}" # Databricks creates a mandatory managed RG

  tags = var.default_tags

  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = var.vnet_id
    public_subnet_name                                   = azurerm_subnet.databricks_public_subnet.name
    private_subnet_name                                  = azurerm_subnet.databricks_private_subnet.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.nsg_assoc_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.nsg_assoc_private.id
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.nsg_assoc_public,
    azurerm_subnet_network_security_group_association.nsg_assoc_private
  ]
}

locals {
  notebook_template = file("${path.module}/notebooks/gzip_to_parquet.py")
  notebook_content = replace(
    replace(
      replace(
        replace(
          replace(
            local.notebook_template,
            "STORAGE_ACCOUNT_NAME",
            azurerm_storage_account.adls.name
          ),
          "BRONZE_CONTAINER_NAME",
          var.bronze_container
        ),
        "GOLD_CONTAINER_NAME",
        var.gold_container
      ),
      "MANAGED_IDENTITY_CLIENT_ID",
      azurerm_user_assigned_identity.databricks.client_id
    ),
    "TENANT_ID",
    data.azurerm_client_config.current.tenant_id
  )
}

resource "databricks_notebook" "gzip_to_parquet" {
  path     = "/Shared/transformation/gzip_to_parquet"
  language = "PYTHON"
  source   = "${path.module}/notebooks/gzip_to_parquet.py"

  depends_on = [
    azurerm_databricks_workspace.this,
    azurerm_storage_container.bronze,
    azurerm_storage_container.gold
  ]
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


# Data Permissions

/*
# Managed Identity for Azure Data Factory (ADF)
# This creates a user-assigned managed identity for ADF
resource "azurerm_user_assigned_identity" "adf" {
  name                = "adf-managed-identity"
  resource_group_name = var.resource_group_name
  location            = var.region
}

# Role Assignment for Azure Data Factory (ADF) to Access ADLS Gen2
resource "azurerm_role_assignment" "adf_adls" {
  scope                = azurerm_storage_account.adls_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.adf_identity.principal_id
}

# Role Assignment for Azure Data Factory (ADF) to Access Databricks Workspace
resource "azurerm_role_assignment" "adf_databricks" {
  scope                = azurerm_databricks_workspace.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.adf_identity.principal_id
}
*/

# User assigned identity for databricks
resource "azurerm_user_assigned_identity" "databricks" {
  name                = "databricks-managed-identity"
  resource_group_name = var.resource_group_name
  location            = var.region
}

# Role Assignment for Databricks to access ADLS Gen2
resource "azurerm_role_assignment" "databricks_adls_access" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.databricks.principal_id
}

# Role Assignment for Databricks User-Assigned Identity to Access Databricks Workspace
resource "azurerm_role_assignment" "databricks_identity_access" {
  scope                = azurerm_databricks_workspace.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.databricks.principal_id
}

