resource "azurerm_storage_account" "storage" {
  name                     = "bittrancehelloapp"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "service_plan" {
  name                = "hello-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "app" {
  name                       = "bittrance-test-hello"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  service_plan_id            = azurerm_service_plan.service_plan.id

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node",
    "WEBSITE_MOUNT_ENABLED"    = "1",
  }

  site_config {
    application_stack {
      node_version = "18"
    }
    application_insights_key = azurerm_application_insights.insights.instrumentation_key
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
