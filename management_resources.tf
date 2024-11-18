# Root module management_resources

# Random string for storage
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}


# Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.client}_Data_Platform_${var.suffix}"
  location = var.region
}

# Create a Resource Group
resource "azurerm_resource_group" "manage" {
  name     = "${var.client}_Management_Resources_${var.suffix}"
  location = var.region
}

# Storage account for state
resource "azurerm_storage_account" "this" {
  name                = "uniquestate${random_string.this.result}"
  location            = var.region
  resource_group_name = azurerm_resource_group.manage.name

  depends_on = [
    azurerm_resource_group.manage
  ]

  account_tier                      = "Standard"
  account_kind                      = "StorageV2"
  account_replication_type          = "GRS"
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = true
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = false

  blob_properties {
    versioning_enabled            = true
    change_feed_enabled           = true
    change_feed_retention_in_days = 30
    last_access_time_enabled      = true

    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }
  sas_policy {
    expiration_period = "00.02:00:00"
    expiration_action = "Log"
  }
}

# Create container in the storage account
resource "azurerm_storage_container" "this" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# for tags
locals {
  default_tags = {
    owner       = var.owner
    environment = var.environment
    project     = var.project
    client      = var.client
    region      = var.region
    created_by  = "Terraform"
  }
}