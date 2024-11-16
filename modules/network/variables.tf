# network module variables

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "The full resource ID of the resource group"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "A map of address prefixes for each subnet"
  type        = map(string)
}

variable "region" {
  description = "Region where resources will be created"
  type = string
}

variable "client" {
  description = "Client name for resource naming"
  type = string
}

variable "suffix" {
  description = "Numerical identifier for resources"
  type        = string
}

variable "default_tags" {
    description = "Default tags to apply to all resources"
  type = map(string)
}