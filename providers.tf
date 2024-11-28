# Root Providers and backend

terraform {
  backend "azurerm" {} # Settings come from backend.hcl

  # Provider requirements
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.9"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "1.5.0"
    }
  }
}

# Azure RM provider configuration
provider "azurerm" {
  subscription_id = var.subscription_id
  storage_use_azuread = true
  features {}
}

# Azure AD provider configuration
provider "azuread" {
  # configuration options
}

provider "databricks" {
  alias = "create_workspace"
  # Basic configuration without host
}
/*
# For creating resources within the workspace
provider "databricks" {
  host = module.data_resources.workspace_url
}
*/
