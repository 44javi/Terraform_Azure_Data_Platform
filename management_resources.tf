# Root module management_resources

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
    name = "${var.client}_${var.environment}_rg_${var.suffix}"
    location = var.region
}