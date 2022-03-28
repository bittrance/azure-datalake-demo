terraform {
  required_version = "1.0.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.99.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "container-instances-demo"
  location = "westeurope"
}

resource "azurerm_container_group" "container" {
  name                = "aci-hello-web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  restart_policy      = "OnFailure"

  container {
    name   = "hello-container"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}

output "ip" {
  value = azurerm_container_group.container.ip_address
}
