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
  }
}

# Azure RM provider configuration
provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Azure AD provider configuration
provider "azuread" {
  # configuration options
}