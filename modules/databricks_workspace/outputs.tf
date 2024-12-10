# /modules/databricks_workspace/outputs.tf

output "workspace_url" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}"
}

output "workspace_id" {
  value = azurerm_databricks_workspace.this.id
}
