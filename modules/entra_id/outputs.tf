# module entra_id outputs.tf

output "client_id" {
  value = azuread_application.databricks_sp.client_id
}

output "client_secret" {
  value     = azuread_service_principal_password.databricks_sp.value
  sensitive = true
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}