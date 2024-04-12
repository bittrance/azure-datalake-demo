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

  identity {
    type = "SystemAssigned"
  }

  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    unauthenticated_action = "Return401"

    login {}

    active_directory_v2 {
      client_id                  = azuread_application.app.application_id
      client_secret_setting_name = "APPCLIENTSECRET"
      tenant_auth_endpoint       = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }

  depends_on = [azurerm_key_vault_secret.app_secret]
}

resource "azurerm_key_vault" "kv" {
  name                      = "bittrancehelloapp"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "self_write" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "app_kv_read" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.app.identity[0].principal_id
}

resource "random_string" "app_secret" {
  length  = 40
  special = true
}

resource "azurerm_key_vault_secret" "app_secret" {
  name         = "APPCLIENTSECRET"
  value        = random_string.app_secret.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.self_write]
}

resource "random_uuid" "permission_id" {}

resource "azuread_application" "app" {
  display_name = "bittrance-test-hello"

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "."
      admin_consent_display_name = "Hello Function App"
      enabled                    = true
      id                         = random_uuid.permission_id.result
      type                       = "Admin"
      user_consent_description   = "."
      user_consent_display_name  = "Hello Function App"
      value                      = "use"
    }
  }
}

# Convenient to get test creds with `az account get-access-token --resource XXX`
resource "azuread_application_pre_authorized" "azcli" {
  application_id       = azuread_application.app.id
  authorized_client_id = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
  permission_ids       = [random_uuid.permission_id.result]
}
