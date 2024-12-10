# /modules/databricks_workspace/variables.tf

variable "client" {
  description = "Client name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "region" {
  description = "Region for deployment"
  type        = string
}

variable "suffix" {
  description = "Unique suffix for naming"
  type        = string
}

variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
}

variable "vnet_id" {
  description = "The ID of the Virtual Network where the Databricks workspace will be deployed"
  type        = string
}

variable "public_subnet_name" {
  description = "The name of the public subnet for Databricks"
  type        = string
}

variable "private_subnet_name" {
  description = "The name of the private subnet for Databricks"
  type        = string
}

variable "public_subnet_nsg_assoc_id" {
  description = "The Network Security Group association ID for the public subnet"
  type        = string
}

variable "private_subnet_nsg_assoc_id" {
  description = "The Network Security Group association ID for the private subnet"
  type        = string
}