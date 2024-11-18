# network module outputs

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  value = azurerm_subnet.private.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}
/*
output "databricks_public_subnet_name" {
  value = azurerm_subnet.databricks_public_subnet.name
}

output "databricks_private_subnet_name" {
  value = azurerm_subnet.databricks_private_subnet.name
}

output "databricks_public_subnet_id" {
  value = azurerm_subnet.databricks_public_subnet.id
}

output "databricks_private_subnet_id" {
  value = azurerm_subnet.databricks_private_subnet.id
}

output "databricks_public_subnet_nsg_assoc_id" {
  value       = azurerm_subnet_network_security_group_association.nsg_assoc_public.id
  description = "The NSG association ID for the Databricks public subnet"
}

output "databricks_private_subnet_nsg_assoc_id" {
  value       = azurerm_subnet_network_security_group_association.nsg_assoc_private.id
  description = "The NSG association ID for the Databricks private subnet"
}

output "nat_gateway_id" {
  value = azurerm_nat_gateway.this.id
}

output "public_ip_id" {
  value = azurerm_public_ip.nat_gateway.id
}
*/