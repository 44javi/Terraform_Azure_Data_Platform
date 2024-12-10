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

output "databricks_public_subnet_name" {
  value = azurerm_subnet.databricks_public_subnet.name
}

output "databricks_private_subnet_name" {
  value = azurerm_subnet.databricks_private_subnet.name
}

output "databricks_public_subnet_nsg_assoc_id" {
  value = azurerm_subnet_network_security_group_association.nsg_assoc_public.id
}

output "databricks_private_subnet_nsg_assoc_id" {
  value = azurerm_subnet_network_security_group_association.nsg_assoc_private.id
}

# Output current user info
output "current_user" {
  value = data.databricks_current_user.me.user_name
}