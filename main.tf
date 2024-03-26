# Proveedores para el archivo Terraform
provider "azurerm" {
  features {}
}


# Pregunta al usuario por el número de Virtual Machines a crear
variable "vm_count" {
  description = "Número de máquinas virtuales a crear"
  type        = number
}

# Creación del Resource Group solo si no existe
resource "azurerm_resource_group" "storage_rg" {
  name     = "examen_DAW"
  location = "eastus"
}


# Creación del VNet en el Resource Group y ubicación especificados
resource "azurerm_virtual_network" "example" {
  name                = "vnetexamen"
  resource_group_name = azurerm_resource_group.storage_rg.name
  location            = azurerm_resource_group.storage_rg.location
  address_space       = ["10.0.0.0/16"]
}

# Creación de la subred dentro de la VNet
resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.storage_rg.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  count               = var.vm_count
  name                = "example-public-ip${count.index}"
  resource_group_name = azurerm_resource_group.storage_rg.name
  location            = azurerm_resource_group.storage_rg.location
  allocation_method   = "Dynamic"
}

# Creación de las máquinas virtuales solicitadas
resource "azurerm_virtual_machine" "example" {
  count = var.vm_count

  name                  = "vm${count.index}"
  resource_group_name   = azurerm_resource_group.storage_rg.name
  location              = azurerm_resource_group.storage_rg.location
  network_interface_ids = [azurerm_network_interface.example[count.index].id]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vm${count.index}"
    admin_username = "Admin"
    admin_password = "$Coo...D00"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
    timezone                  = "UTC"
  }
}

# Creación de una interfaz de red para cada máquina virtual
resource "azurerm_network_interface" "example" {
  count = var.vm_count

  name                = "example-nic${count.index}"
  location            = azurerm_resource_group.storage_rg.location
  resource_group_name = azurerm_resource_group.storage_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example[count.index].id
  }
}
