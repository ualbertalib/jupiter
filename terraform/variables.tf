################################
## Common - Variables ##
################################

variable "app-name" {
  type        = string
  description = "Application name"
}


################################
## Azure Provider - Variables ##
################################

variable "azure-subscription-id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure-client-id" {
  type        = string
  description = "Azure Client ID"
}

variable "azure-client-secret" {
  type        = string
  description = "Azure Client Secret"
}

variable "azure-tenant-id" {
  type        = string
  description = "Azure Tenant ID"
}

#############################################
# Azure Database for PostgreSQL - Variables #
#############################################

variable "postgresql-admin-login" {
  type        = string
  description = "Login to authenticate to PostgreSQL Server"
}

variable "postgresql-admin-password" {
  type        = string
  description = "Password to authenticate to PostgreSQL Server"
}
