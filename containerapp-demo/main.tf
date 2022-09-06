terraform {
  required_providers {
    azurerm = {
      version = "3.8.0"
      source  = "hashicorp/azurerm"
    }
    azapi = {
      version = "0.3.0"
      source  = "Azure/azapi"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "http" {}

data "http" "local_ip" {
  url = "https://ifconfig.co"
}

resource "azurerm_resource_group" "rg" {
  name     = "containerapps-demo"
  location = "West Europe"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "containerapps-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_virtual_network" "this" {
  name                = "containerapps-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "this" {
  name                 = "containerapps-demo-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/20"]
}

resource "azapi_resource" "managed_environment" {
  type                      = "Microsoft.App/managedEnvironments@2022-03-01"
  name                      = "containerapps-demo"
  parent_id                 = azurerm_resource_group.rg.id
  location                  = azurerm_resource_group.rg.location
  schema_validation_enabled = false

  body = jsonencode({
    properties = {
      internalLoadBalancerEnabled = false
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.this.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.this.primary_shared_key
        }
      }
      vnetConfiguration = {
        infrastructureSubnetId = azurerm_subnet.this.id
        internal               = false
      }
      zoneRedundant = true
    }
  })
}

resource "random_string" "admin_password" {
  length = 16
  special = false
}

resource "azurerm_postgresql_server" "this" {
  name                         = "containerapps-demo"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  administrator_login          = "urlshortener"
  administrator_login_password = random_string.admin_password.result
  sku_name                     = "GP_Gen5_4"
  version                      = "11"
  storage_mb                   = 16384
  backup_retention_days        = 7
  auto_grow_enabled            = false
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_firewall_rule" "this" {
  name                = "terraform-apply-ip"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.this.name
  start_ip_address    = chomp(data.http.local_ip.body)
  end_ip_address      = chomp(data.http.local_ip.body)
}

resource "azurerm_postgresql_firewall_rule" "containerapps" {
  name                = "azure-services"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.this.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_database" "this" {
  name                = "urlshortener"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.this.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

output "postgres_hostname" {
  value = azurerm_postgresql_server.this.fqdn
}

output "postgres_password" {
  value = azurerm_postgresql_server.this.administrator_login_password
  sensitive = true
}