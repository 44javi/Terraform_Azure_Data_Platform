# Root module outputs

output "resource_group_id" {
  description = "main resource group where most resources will be placed"
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "name of main resource group where most resources will be placed"
  value       = azurerm_resource_group.main.name
}