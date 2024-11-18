# network module outputs

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name"{
    value = azurerm_virtual_network.vnet.name
}

output "subnet_id" {
  value = azurerm_subnet.private.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}

output "nat_gateway_id" {
  value = azurerm_nat_gateway.this.id
}

output "public_ip_id" {
  value = azurerm_public_ip.nat_gateway.id
}
