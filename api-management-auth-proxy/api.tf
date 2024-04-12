resource "azurerm_api_management" "apim" {
  name                = "bittrance-test"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Bittrance test"
  publisher_email     = "bittrance@gmail.com"

  sku_name = "Developer_1"
}

resource "azurerm_api_management_logger" "logger" {
  name                = "apim-logger"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  resource_id         = azurerm_application_insights.insights.id

  application_insights {
    instrumentation_key = azurerm_application_insights.insights.instrumentation_key
  }
}

resource "azurerm_api_management_api_diagnostic" "logging" {
  identifier               = "applicationinsights"
  resource_group_name      = azurerm_resource_group.rg.name
  api_management_name      = azurerm_api_management.apim.name
  api_name                 = azurerm_api_management_api.api.name
  api_management_logger_id = azurerm_api_management_logger.logger.id

  sampling_percentage       = 100
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"
}

resource "azurerm_api_management_backend" "backend" {
  name                = "hello-backend"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  protocol            = "http"
  url                 = "https://${azurerm_linux_function_app.app.default_hostname}/api"
}

resource "azurerm_api_management_api" "api" {
  name                  = "example-api"
  resource_group_name   = azurerm_resource_group.rg.name
  api_management_name   = azurerm_api_management.apim.name
  subscription_required = false
  revision              = "2"
  display_name          = "Example API"
  path                  = "api"
  protocols             = ["https"]
}

resource "azurerm_api_management_api_operation" "hello" {
  operation_id        = "hello"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  api_name            = azurerm_api_management_api.api.name
  display_name        = "Hello World"
  method              = "GET"
  url_template        = "/hello"
  description         = "Greets the caller."
}

resource "azurerm_api_management_api_operation_policy" "example" {
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  api_name            = azurerm_api_management_api.api.name
  operation_id        = azurerm_api_management_api_operation.hello.operation_id

  xml_content = <<XML
<policies>
    <inbound>
        <set-backend-service backend-id="${azurerm_api_management_backend.backend.name}" />
        <base/>
    </inbound>
</policies>
XML
}
