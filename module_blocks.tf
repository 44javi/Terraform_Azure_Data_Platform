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
  source              = "./modules/data_resources"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  region              = var.region
  vnet_id             = module.network.vnet_id
  vnet_name           = module.network.vnet_name
  subnet_id           = module.network.subnet_id
  client              = var.client
  suffix              = var.suffix
  default_tags        = local.default_tags
  #bronze_container        = var.bronze_container
  #gold_container          = var.gold_container

  depends_on = [module.network]
}

module "databricks_workspace" {
  source = "./modules/databricks_workspace"
  #providers = {
  #   databricks = databricks.create_workspace
  # }
  client                  = var.client
  resource_group_name     = azurerm_resource_group.main.name
  region                  = var.region
  suffix                  = var.suffix
  default_tags            = local.default_tags
  subnet_address_prefixes = var.subnet_address_prefixes
  vnet_id                 = module.network.vnet_id
  vnet_name               = module.network.vnet_name
  subnet_id               = module.network.subnet_id
  public_ip_id            = module.network.public_ip_id
  nat_gateway_id          = module.network.nat_gateway_id


  depends_on = [module.data_resources]
}

module "entra_id" {
  source       = "./modules/entra_id"
  client       = var.client
  suffix       = var.suffix
  workspace_id = module.databricks_workspace.workspace_id
  datalake_id  = module.data_resources.datalake_id

  depends_on = [
    module.databricks_workspace,
    module.data_resources
  ]
}

module "unity_catalog" {
  source = "./modules/unity_catalog"
  providers = {
    databricks.account = databricks.account
  }

  client                = var.client
  suffix                = var.suffix
  resource_group_name   = azurerm_resource_group.main.name
  resource_group_id     = azurerm_resource_group.main.id
  region                = var.region
  secondary_region      = var.secondary_region
  datalake_name         = module.data_resources.datalake_name
  datalake_id           = module.data_resources.datalake_id
  workspace_id          = module.databricks_workspace.workspace_id
  metastore_id          = var.metastore_id

  depends_on = [
    module.entra_id,
    module.data_resources,
    module.databricks_workspace
  ]
}


