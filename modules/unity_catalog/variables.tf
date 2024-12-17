# /modules/unity_catalog/variables.tf

variable "client" {
  description = "Client name for resource naming"
  type        = string
}

variable "suffix" {
  description = "Suffix for resource naming"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "The ID of the resource group"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

variable "workspace_id" {
  description = "The ID of the Databricks workspace"
  type        = string
}

variable "datalake_name" {
  description = "The name of the Azure Data Lake Storage account"
  type        = string
}

variable "datalake_id" {
  description = "The resource ID of the Azure Data Lake Storage account"
  type        = string
}

variable "secondary_region" {
  description = "The 2nd region where resources will be created"
  type        = string
}

variable "metastore_id" {
  description = "ID of the default Databricks metastore"
  type        = string
}

