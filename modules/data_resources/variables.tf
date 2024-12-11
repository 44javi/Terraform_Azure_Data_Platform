# Data_resources module variables

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "The full resource ID of the resource group"
  type        = string
}

variable "region" {
  description = "Region where resources will be created"
  type        = string
}

variable "client" {
  description = "Client name for resource naming"
  type        = string
}

variable "suffix" {
  description = "Numerical identifier for resources"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
}

variable "subnet_id" {
  description = "Private subnet id"
  type        = string
}

variable "vnet_id" {
  description = "Hub virtual network id"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "subnet_address_prefixes" {
  description = "A map of address prefixes for each subnet"
  type        = map(string)
}

variable "nat_gateway_id" {
  description = "nat gateway id"
  type        = string
}

variable "public_ip_id" {
  description = "id of gateway public ip"
  type        = string
}
/*
variable "bronze_container" {
  description = "Name of the container for raw data"
  type        = string
}

variable "gold_container" {
  description = "Name of the container for processed data"
  type        = string
}
*/

variable "workspace_url" {
  description = "The URL of the Databricks workspace"
  type        = string
}

variable "workspace_id" {
  description = "The ID of the Databricks workspace"
  type        = string
}
