# network module 

# Grabs Tenant Info
data "azurerm_client_config" "current" {}


# Create the Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.client}-${var.environment}-vnet"
  address_space       = var.vnet_address_space
  location            = var.region
  resource_group_name = var.resource_group_name
}

# Creates the private subnet for VMs
resource "azurerm_subnet" "subnet" {
  name                            = "dev-subnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [var.subnet_address_prefixes["vm_subnet"]]
  default_outbound_access_enabled = false # Disable default outbound internet access
}


# Creates the NAT Gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "dev-nat-gateway"
  resource_group_name = var.resource_group_name
  location            = var.region
}

# Creates the Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway_ip" {
  name                = "nat-gateway-ip"
  resource_group_name = var.resource_group_name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Associates the NAT Gateway with the public ip
resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_ip.id
}

# Associate NAT Gateway with the VM Subnet
resource "azurerm_subnet_nat_gateway_association" "nat_gateway_subnet_assoc" {
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

# Creates the the subnet for Azure Bastion
resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefixes["bastion_subnet"]] # At least a 26 subnet size is recommended
}

resource "azurerm_network_security_group" "nsg" {
  name                = "dev-nsg"
  location            = var.region
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = azurerm_subnet.AzureBastionSubnet.address_prefixes[0] # Restricts to Bastion subnet
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
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# Public Subnet for Databricks
resource "azurerm_subnet" "databricks_public_subnet" {
  name                 = "databricks-public-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefixes["databricks_public_subnet"]] #["10.0.3.0/24"]

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
  name                 = "databricks-private-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefixes["databricks_private_subnet"]] #["10.0.4.0/24"]

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
  name                = "databricks-public-nsg"
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
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

# Associate the NAT Gateway with the Databricks Private Subnet
resource "azurerm_subnet_nat_gateway_association" "nat_gateway_databricks_private_subnet_assoc" {
  subnet_id      = azurerm_subnet.databricks_private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}