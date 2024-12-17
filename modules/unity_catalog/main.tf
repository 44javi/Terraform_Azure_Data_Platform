# /modules/unity_catalog/main.tf

terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      version               = "~> 1.6.0"
      configuration_aliases = [databricks.account]
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.9"
    }
  }
}

# Unity Catalog Access Connector
resource "azurerm_databricks_access_connector" "unity" {
  name                = "${var.client}_Unity_Catalog_${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.region
  identity {
    type = "SystemAssigned"
  }
}

# Datalake access for Unity Catalog connector
resource "azurerm_role_assignment" "unity_storage" {
  scope                = var.datalake_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

resource "azurerm_role_assignment" "unity_queue" {
  scope                = var.datalake_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

# Resource group access for Unity Catalog connector
resource "azurerm_role_assignment" "unity_eventsubscription" {
  scope                = var.resource_group_id
  role_definition_name = "EventGrid EventSubscription Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

resource "databricks_storage_credential" "unity" {
  provider     = databricks.account
  metastore_id = var.metastore_id
  name         = "unity_catalog_credential"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity.id
  }
}

# Grants for the storage credential
resource "databricks_grants" "unity_credential" {
  provider           = databricks.account
  storage_credential = databricks_storage_credential.unity.id
  
  grant {
    principal  = "account users" # Grants to all users, can be restricted 
    privileges = ["CREATE_EXTERNAL_TABLE", "USE_STORAGE_CREDENTIAL"]
  }
}


# External location grants
resource "databricks_grants" "external_locations" {
  provider = databricks.account
  for_each = databricks_external_location.this

  external_location = each.value.id

  grant {
    principal  = "account users" # Grants to all users, can be restricted 
    privileges = ["CREATE_EXTERNAL_TABLE", "USE_EXTERNAL_LOCATION"]
  }
}

# Catalog grants
resource "databricks_grants" "catalog" {
  provider = databricks.account
  catalog  = databricks_catalog.main.id

  grant {
    principal  = "account users" # Grants to all users, can be restricted 
    privileges = ["USE_CATALOG", "CREATE_SCHEMA"]
  }
}

# Schema grants
resource "databricks_grants" "schemas" {
  provider = databricks.account
  for_each = databricks_schema.this

  schema = each.value.id

  grant {
    principal  = "account users" # Grants to all users, can be restricted
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_VIEW", "CREATE_FUNCTION"]
  }
}

# Catalog
resource "databricks_catalog" "main" {
  provider = databricks.account
  name     = "${var.client}_dev_catalog"
  comment  = "Development catalog for client"
  properties = {
    managed_location = databricks_external_location.catalog.url
  }

  depends_on = [
    databricks_external_location.catalog
  ]
}

# External Locations
resource "databricks_external_location" "catalog" {
  provider        = databricks.account
  name            = "catalog"
  url             = "abfss://catalog@${var.datalake_name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.unity.name
  comment         = "External location for catalog root storage"
}

resource "databricks_external_location" "this" {
  provider        = databricks.account
  for_each        = toset(["bronze", "gold"])
  name            = "${each.key}_container"
  url             = "abfss://${each.key}@${var.datalake_name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.unity.name
  comment         = "External location for ${each.key} container"
}

# Schemas
resource "databricks_schema" "this" {
  provider     = databricks.account
  for_each     = toset(["bronze_container_schema", "gold_container_schema"])
  catalog_name = databricks_catalog.main.name
  name         = each.key
  comment      = "Schema for ${each.key} data"
}
