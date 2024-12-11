# Root Providers and backend

terraform {
  backend "azurerm" {} # Settings come from backend.hcl

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
      version = "~> 1.5.0"
    }
  }
}

provider "azurerm" {
  subscription_id     = var.subscription_id
  storage_use_azuread = true
  features {}
}

provider "azuread" {
  # configuration options
}

provider "databricks" {
  alias = "create_workspace"
}

provider "databricks" {
  alias = "workspace_resources"
  host  = module.databricks_workspace.workspace_url
}
