variable "client" {
  description = "Client name for resource naming"
  type        = string
}

variable "suffix" {
  description = "Suffix for resource naming"
  type        = string
}

variable "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "notebook_path" {
  description = "Path to the notebook in Databricks workspace"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "bronze_container" {
  description = "Name of the container for raw/bronze data"
  type        = string
}

variable "gold_container" {
  description = "Name of the container for processed/gold data"
  type        = string
}