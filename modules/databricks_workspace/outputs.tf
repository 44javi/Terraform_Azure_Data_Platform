# /modules/databricks_workspace/outputs.tf

output "workspace_url" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}"
}

output "workspace_id" {
  value = azurerm_databricks_workspace.this.id
}

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
