terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.90.0"
    }
     helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
  }
}

provider "azurerm" {
  subscription_id = var.azure-subscription-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
  tenant_id       = var.azure-tenant-id

  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.app-name}-rg"
  location = "Canada Central"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.app-name}-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.app-name}Cluster"

  default_node_pool {
    name       = "nodes"
    node_count = "3"
    vm_size    = "standard_d2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_postgresql_server" "db" {
  name                = "${var.app-name}-psqlserver"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login          = var.postgresql-admin-login
  administrator_login_password = var.postgresql-admin-password

  sku_name   = "GP_Gen5_4"
  version    = "11"

  # storage_mb = 500000
  # backup_retention_days        = 7
  # geo_redundant_backup_enabled = true
  # auto_grow_enabled            = true

  # TODO: Can we disabled public network access and use SSL?
  public_network_access_enabled    = true
  ssl_enforcement_enabled          = false
  # ssl_minimal_tls_version_enforced = "TLS1_2"
}

# Create a PostgreSQL Database
resource "azurerm_postgresql_database" "postgresql-db" {
  name                = "${var.app-name}_production"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.db.name
  charset             = "utf8"
  collation           = "English_United States.1252"
}

# TODO: Fix this, Currently we allow everything for now
resource "azurerm_postgresql_firewall_rule" "postgresql-fw-rules" {
  name                = "${var.app-name}-postgresql-fw-rules"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.db.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_redis_cache" "redis" {
  name                = "${var.app-name}-cache"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"

  # TODO: It possible to use SSL here?
  enable_non_ssl_port = true
  # minimum_tls_version = "1.2"

  redis_configuration {
    # https://github.com/mperham/sidekiq/wiki/Using-Redis#memory
    maxmemory_policy   = "noeviction"
  }
}

# TODO: Fix this, Currently we allow everything for now
resource "azurerm_redis_firewall_rule" "redis-fw-rules" {
  name                = "${var.app-name}_redis_fw_rules"
  redis_cache_name    = azurerm_redis_cache.redis.name
  resource_group_name = azurerm_resource_group.rg.name
  start_ip            = "0.0.0.0"
  end_ip              = "255.255.255.255"
}


# blob account name must be unique across Azure, so append random string to name
resource "random_string" "random" {
  length           = 10
  special          = false
  upper = false
}

resource "azurerm_storage_account" "blob_account" {
  name                     = "${var.app-name}account${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # TODO: Probably not needed for Jupiter?
  blob_properties {
    cors_rule {
      allowed_headers = ["Origin", "Content-Type", "Content-MD5", "x-ms-blob-content-disposition", "x-ms-blob-type"]
      allowed_methods = ["PUT"]
      allowed_origins = ["*"]
      exposed_headers = ["Origin", "Content-Type", "Content-MD5", "x-ms-blob-content-disposition", "x-ms-blob-type"]
      max_age_in_seconds = 3600
    }
  }
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "${var.app-name}-blob-container"
  storage_account_name  = azurerm_storage_account.blob_account.name
  container_access_type = "private"
}

provider "helm" {
  kubernetes {
    host = azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
    host = azurerm_kubernetes_cluster.cluster.kube_config.0.host
    client_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
    client_key = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}
