# Module_blocks in root

module "network" {
  source                  = "./modules/network"
  resource_group_name     = azurerm_resource_group.main.name
  resource_group_id       = azurerm_resource_group.main.id
  vnet_address_space      = var.vnet_address_space
  subnet_address_prefixes = var.subnet_address_prefixes
  region                  = var.region
  client                  = var.client
  suffix                  = var.suffix
  default_tags            = local.default_tags
}

module "data_resources" {
  source = "./modules/data_resources"
  providers = {
    databricks = databricks.create_workspace
  }
  resource_group_name     = azurerm_resource_group.main.name
  resource_group_id       = azurerm_resource_group.main.id
  region                  = var.region
  vnet_id                 = module.network.vnet_id
  vnet_name               = module.network.vnet_name
  subnet_id               = module.network.subnet_id
  subnet_address_prefixes = var.subnet_address_prefixes
  client                  = var.client
  suffix                  = var.suffix
  default_tags            = local.default_tags
  nat_gateway_id          = module.network.nat_gateway_id
  public_ip_id            = module.network.public_ip_id
  bronze_container        = var.bronze_container
  gold_container          = var.gold_container
}