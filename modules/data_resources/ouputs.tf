# output for data_pipeline module
/*
output "datalake_name" {
  description = "The name of the Azure Data Lake Storage account"
  value       = azurerm_storage_account.adls_storage.name
}

output "datalake_id" {
  description = "The resource ID of the Azure Data Lake Storage account"
  value       = azurerm_storage_account.adls_storage.id
}

output "datalake_endpoint" {
  description = "The primary Blob service endpoint for the storage account"
  value       = azurerm_storage_account.adls_storage.primary_blob_endpoint
}

output "datalake_connection" {
  description = "The primary connection string for the storage account"
  value       = azurerm_storage_account.adls_storage.primary_connection_string
}

*/

output "workspace_url" {
  description = "The workspace URL of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "workspace_id" {
  description = "The ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.id
}

output "databricks_identity_id" {
  description = "Client ID of the user-assigned managed identity for Databricks"
  value       = azurerm_user_assigned_identity.databricks.client_id
}