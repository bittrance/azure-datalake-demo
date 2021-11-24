terraform {
  required_version = "1.0.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.86.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {
}

resource "random_string" "admin_password" {
  length = 16
}

resource "azurerm_resource_group" "rg" {
  name     = "datalake-demo"
  location = "West Europe"
}

resource "azurerm_storage_account" "sa" {
  name                     = "bittrancedatalakedemo"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/6659
resource "azurerm_role_assignment" "storage_role" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "fs" {
  name               = "big-data"
  storage_account_id = azurerm_storage_account.sa.id
}

resource "azurerm_synapse_workspace" "workspace" {
  name                                 = "datalake-demo"
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.fs.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = random_string.admin_password.result

  aad_admin {
    login     = "bittrance@gmail.com"
    object_id = data.azurerm_client_config.current.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }
}

resource "azurerm_synapse_firewall_rule" "allowall" {
  name                 = "allowAll"
  synapse_workspace_id = azurerm_synapse_workspace.workspace.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}