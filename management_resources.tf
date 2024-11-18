# Root module management_resources

# Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.client}_Data_Platform_${var.suffix}"
  location = var.region
}



# for tags
locals {
  default_tags = {
    owner       = var.owner
    environment = var.environment
    project     = var.project
    client      = var.client
    region      = var.region
    created_by  = "Terraform"
  }
}