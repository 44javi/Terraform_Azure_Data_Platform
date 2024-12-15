# /modules/entra_id/main.tf

# Get current Azure config
data "azurerm_client_config" "current" {}

# Service Principal for Databricks
resource "azuread_application" "databricks_sp" {
  display_name = "${var.client}_databricks_sp_${var.suffix}"
}

# Create Service Principal
resource "azuread_service_principal" "databricks_sp" {
  client_id  = azuread_application.databricks_sp.client_id
}

# Create Service Principal secret
resource "azuread_service_principal_password" "databricks_sp" {
  service_principal_id = azuread_service_principal.databricks_sp.id
  end_date            = "2025-12-31T23:59:59Z" # Expiration date
}

# Role Assignments for Service Principal
resource "azurerm_role_assignment" "sp_databricks_contributor" {
  scope                = var.workspace_id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.databricks_sp.object_id
}

resource "azurerm_role_assignment" "sp_storage_contributor" {
  scope                = var.datalake_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.databricks_sp.object_id
}
