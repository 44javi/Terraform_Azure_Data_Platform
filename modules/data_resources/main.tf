# data_resources module

# Get Azure subscription details
data "azurerm_client_config" "current" {}

data "databricks_current_user" "me" {
  depends_on = [databricks_metastore.this]
}

# Random string for storage names
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}

# Assigned to the VMs that need access to the datalake
resource "azurerm_user_assigned_identity" "datalake" {
  name                = "${var.client}_datalake_access_${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.region
}

resource "azurerm_role_assignment" "datalake_blob_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.datalake.principal_id
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
  public_network_access_enabled   = true #false blocks access to containers on the portal
  #shared_access_key_enabled = false

  tags = var.default_tags

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }

}

# Containers for 

resource "azurerm_storage_container" "this" {
  for_each              = toset(["bronze", "silver", "gold", "catalog"])
  name                  = each.key
  storage_account_id  = azurerm_storage_account.adls.id
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


# Unity Catalog Access Connector
resource "azurerm_databricks_access_connector" "unity" {
  name                = "${var.client}_Unity_Catalog_${var.suffix}"
  resource_group_name = var.resource_group_name
  location           = var.region
  identity {
    type = "SystemAssigned"
  }
}

# Datalake access for Unity Catalog connector
resource "azurerm_role_assignment" "unity_storage" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

resource "azurerm_role_assignment" "unity_queue" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

# Resource group access for Unity Catalog connector - EventGrid EventSubscription Contributor
resource "azurerm_role_assignment" "unity_eventsubscription" {
  scope                = var.resource_group_id
  role_definition_name = "EventGrid EventSubscription Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

# Metastore
resource "databricks_metastore" "this" {
  name          = "primary"
  storage_root  = "abfss://catalog@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
  force_destroy = true

  provider = databricks.workspace_resources
}

# Catalog
resource "databricks_catalog" "main" {
  metastore_id = databricks_metastore.this.id
  name         = "${var.client}_dev_catalog"
  comment      = "Development catalog for client"
  properties = {
    purpose = "development"
  }

  provider = databricks.workspace_resources
}

resource "databricks_storage_credential" "unity" {
  name = "unity_catalog_credential"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity.id
  }

  provider = databricks.workspace_resources
}

# External Locations
resource "databricks_external_location" "this" {
  for_each = toset(["bronze", "gold"])
  name     = "${each.key}_container"
  url      = "abfss://${each.key}@${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.unity.name
  comment  = "External location for ${each.key} container"
}

# Schemas
resource "databricks_schema" "schemas" {
  for_each      = toset(["bronze_container_schema", "gold_container_schema"])
  catalog_name  = databricks_catalog.main.name
  name          = each.key
  comment       = "Schema for ${each.key} data"
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


/*

# Data Permissions

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

*/