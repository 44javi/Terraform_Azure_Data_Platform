# data_resources module

# Get Azure subscription details
data "azurerm_client_config" "current" {}

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