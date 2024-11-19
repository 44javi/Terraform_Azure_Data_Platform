# Only needed if creating Databrick workspace resources like notebooks or clusters through terraform

# data_resources module versions.tf


terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.9"
    }
  }
}

module "jobs" {
  source = "./jobs"

  providers = {
    databricks = databricks
  }

  client                    = var.client
  suffix                    = var.suffix
  managed_identity_client_id = azurerm_user_assigned_identity.databricks.client_id
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  notebook_path            = databricks_notebook.gzip_to_parquet.path
  storage_account_name     = azurerm_storage_account.adls.name
  bronze_container         = var.bronze_container
  gold_container          = var.gold_container

  depends_on = [
    azurerm_databricks_workspace.this,
    databricks_notebook.gzip_to_parquet,
    azurerm_role_assignment.databricks_adls_access
  ]
}