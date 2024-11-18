# Network module 

# Grabs Tenant Info
data "azurerm_client_config" "current" {}


# Create the Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.client}_vnet_${var.suffix}"
  address_space       = var.vnet_address_space
  location            = var.region
  resource_group_name = var.resource_group_name

  tags = var.default_tags
}

# Creates the private subnet for VMs
resource "azurerm_subnet" "private" {
  name                            = "${var.client}_private_subnet_${var.suffix}"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [var.subnet_address_prefixes["vm_subnet"]]
  default_outbound_access_enabled = false # Disable default outbound internet access
}


# Creates the NAT Gateway
resource "azurerm_nat_gateway" "this" {
  name                = "${var.client}_nat_gateway_${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.region

  tags = var.default_tags
}

# Creates the Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway" {
  name                = "${var.client}_nat_gateway_ip_${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.default_tags
}

# Associates the NAT Gateway with the public ip
resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

# Associate NAT Gateway with the VM Subnet
resource "azurerm_subnet_nat_gateway_association" "nat_gateway_subnet_assoc" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

# Creates the the subnet for Azure Bastion
resource "azurerm_subnet" "bastion" {
  name                 = "${var.client}_bastion_subnet_${var.suffix}"# "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefixes["bastion_subnet"]] 
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.client}_nsg_${var.suffix}"
  location            = var.region
  resource_group_name = var.resource_group_name

  tags = var.default_tags

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.subnet_address_prefixes["bastion_subnet"] # Restricts to Bastion subnet
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-Kafka-Access"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9021"
    source_address_prefix      = "VirtualNetwork" # Restrict access to VNet or specify IP ranges
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-NKICU"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "VirtualNetwork" # Restrict access to VNet 
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-NKICU-2"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5001"
    source_address_prefix      = "VirtualNetwork" # Restrict access to VNet 
    destination_address_prefix = "*"
  }
}

# Link the NSG with the VM Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

/*
# Public Subnet for Databricks
resource "azurerm_subnet" "databricks_public_subnet" {
  name                 = "${var.client}_${var.environment}_databricks_public_subnet_${var.suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefixes["databricks_public_subnet"]] 

  # Disable default outbound access
  default_outbound_access_enabled = false

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

# Private or Container Subnet for Databricks 
resource "azurerm_subnet" "databricks_private_subnet" {
  name                 = "${var.client}_${var.environment}_databricks_private_subnet_${var.suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefixes["databricks_private_subnet"]] 

  # Disable default outbound access
  default_outbound_access_enabled = false

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

# NSG for Public Subnet
resource "azurerm_network_security_group" "databricks_public_nsg" {
  name                = "${var.client}_${var.environment}_databricks_public_nsg_${var.suffix}"
  location            = var.region
  resource_group_name = var.resource_group_name

}


# NSG for Private Subnet
resource "azurerm_network_security_group" "databricks_private_nsg" {
  name                = "databricks-private-nsg"
  location            = var.region
  resource_group_name = var.resource_group_name

}

# NSG association for Public Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_public" {
  subnet_id                 = azurerm_subnet.databricks_public_subnet.id
  network_security_group_id = azurerm_network_security_group.databricks_public_nsg.id
}


# NSG association for Private Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_private" {
  subnet_id                 = azurerm_subnet.databricks_private_subnet.id
  network_security_group_id = azurerm_network_security_group.databricks_private_nsg.id
}


# Associate the NAT Gateway with the Databricks Public Subnet
resource "azurerm_subnet_nat_gateway_association" "nat_gateway_databricks_public_subnet_assoc" {
  subnet_id      = azurerm_subnet.databricks_public_subnet.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

# Associate the NAT Gateway with the Databricks Private Subnet
resource "azurerm_subnet_nat_gateway_association" "nat_gateway_databricks_private_subnet_assoc" {
  subnet_id      = azurerm_subnet.databricks_private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}
*/