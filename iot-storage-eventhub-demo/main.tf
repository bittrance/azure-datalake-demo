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

resource "azurerm_resource_group" "rg" {
  name     = "iot-demo"
  location = "West Europe"
}

resource "azurerm_iothub" "iothub" {
  name                = "bittrance-iot-demo-hub"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "S1"
    capacity = "1"
  }
}

// Destination Storage account

resource "azurerm_storage_account" "sa" {
  name                     = "bittranceiotdemo"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_container" "sacontainer" {
  name                  = "iot-demo-container"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_iothub_endpoint_storage_container" "sacontainer" {
  resource_group_name        = azurerm_resource_group.rg.name
  iothub_name                = azurerm_iothub.iothub.name
  name                       = "storage-account"
  container_name             = azurerm_storage_container.sacontainer.name
  connection_string          = azurerm_storage_account.sa.primary_blob_connection_string
  file_name_format           = "{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}"
  batch_frequency_in_seconds = 60
  max_chunk_size_in_bytes    = 10485760
  encoding                   = "JSON"
}

resource "azurerm_iothub_route" "sacontainer" {
  resource_group_name = azurerm_resource_group.rg.name
  iothub_name         = azurerm_iothub.iothub.name
  name                = "storage-account"
  source              = "DeviceMessages"
  endpoint_names      = [azurerm_iothub_endpoint_storage_container.sacontainer.name]
  enabled             = true
}

// Destination Event Hub

resource "azurerm_eventhub_namespace" "namespace" {
  name                = "iot-demo-namespace"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
}

resource "azurerm_eventhub" "eventhub" {
  name                = "iot-demo-eventhub"
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  partition_count     = 2
  message_retention   = 7
}

resource "azurerm_iothub_endpoint_eventhub" "eventhub" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "eventhub"
  iothub_name         = azurerm_iothub.iothub.name
  connection_string   = azurerm_eventhub_authorization_rule.eventhub_sender.primary_connection_string
}

resource "azurerm_iothub_route" "eventhub" {
  resource_group_name = azurerm_resource_group.rg.name
  iothub_name         = azurerm_iothub.iothub.name
  name                = "eventhub"
  source              = "DeviceMessages"
  endpoint_names      = [azurerm_iothub_endpoint_eventhub.eventhub.name]
  enabled             = true
}

resource "azurerm_eventhub_authorization_rule" "eventhub_sender" {
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  eventhub_name       = azurerm_eventhub.eventhub.name
  name                = "send-rule"
  send                = true
}

resource "azurerm_eventhub_authorization_rule" "eventhub_receiver" {
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.namespace.name
  eventhub_name       = azurerm_eventhub.eventhub.name
  name                = "listen-rule"
  send                = true
  listen  = true
}
