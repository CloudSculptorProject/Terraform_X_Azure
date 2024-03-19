provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "example_network" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "example_subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.example_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_machine" "example_vm" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.example_nic.id]
  vm_size               = var.vm_size

  storage_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.version
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = var.admin_username

    admin_password {
      value = var.admin_password
    }
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  provisioner "local-exec" {
    command = "echo ${azurerm_virtual_machine.example_vm.public_ip_address} > ip_address.txt"
  }
}

resource "azurerm_network_interface" "example_nic" {
  name                      = "${var.nic_name}-nic"
  location                  = var.location
  resource_group_name       = var.resource_group_name

  ip_configuration {
    name                          = "${var.nic_name}-ipconfig"
    subnet_id                     = azurerm_subnet.example_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
