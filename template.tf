# backend_dev.hcl - Template for team members
/*
resource_group_name  = "REPLACE_WITH_RG_NAME"
storage_account_name = "REPLACE_WITH_SA_NAME"
container_name      = "tfstate"
key                 = "REPLACE_WITH_STATE_FILE_NAME"
use_azuread_auth    = true


# terraform init -backend-config=environments/backend_dev.hcl




#.tfvars

# Resource Naming
client = "Client"
suffix = "001"

region          = "westus2"
subscription_id = "9d0072cb-27f9-4f90-b3fd-891e3c5f2dcd"


alert_email = "pachecojavier44@gmail.com"

vnet_address_space = ["10.44.0.0/16"]

subnet_address_prefixes = {
  vm_subnet                 = "10.44.1.0/26" # Private subnet for VMs
  bastion_subnet            = "10.44.2.0/26" # Subnet for Azure Bastion
  databricks_public_subnet  = "10.44.3.0/24" # Public subnet for Databricks
  databricks_private_subnet = "10.44.4.0/24" # Private subnet for Databricks
}

bronze_container = "bronze"
gold_container   = "gold"


# Default tags
owner       = "Javier"
environment = "dev"
project     = "Azure_Data_Platform"
created_by  = "Terraform"

*/