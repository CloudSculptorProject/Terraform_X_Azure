provider "azurerm" {
  features {}
}

# Creación del Resource Group solo si no existe
resource "azurerm_resource_group" "storage_rg" {
  name     = "examen_DAW"
  location = "eastus"
}

resource "azurerm_container_group" "example" {
  name                = "example-container-group"
  location            = azurerm_resource_group.storage_rg.location
  resource_group_name = azurerm_resource_group.storage_rg.name
  os_type             = "Linux"

  container {
    name   = "example-container"
    image  = "javier0001/myapp:latest"
    cpu    = "0.5"
    memory = "1.5"
    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    environment = "testing"
  }
}
