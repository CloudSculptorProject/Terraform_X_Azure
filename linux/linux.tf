# Provider configuration
provider "azurerm" {
  features {}
}

# Variable declaration
variable "linux_vm_count" {
  description = "Number of Linux virtual machines to create"
  type        = number
}

# Resource Group creation
resource "azurerm_resource_group" "linux_rg" {
  name     = "examen_DAW"
  location = "eastus"
}

# Storage Account creation
resource "azurerm_storage_account" "linux_storage_account" {
  name                     = "vhdexamen"
  resource_group_name      = azurerm_resource_group.linux_rg.name
  location                 = azurerm_resource_group.linux_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container creation for Linux VHDs
resource "azurerm_storage_container" "linux_container" {
  name                  = "linuxcontainer"
  storage_account_name  = azurerm_storage_account.linux_storage_account.name
  container_access_type = "private"
}

# Upload Linux VHDs to the storage container
locals {
  linux_file_paths = fileset("./vhdlinux", "**")
}

resource "azurerm_storage_blob" "linux_blob" {
  for_each = { for p in local.linux_file_paths : p => p }

  name                   = each.value
  storage_account_name   = azurerm_storage_account.linux_storage_account.name
  storage_container_name = azurerm_storage_container.linux_container.name
  type                   = "Block"
  source                 = each.value
}

# Virtual Network creation
resource "azurerm_virtual_network" "linux_vnet" {
  name                = "linvnetexamen"
  resource_group_name = azurerm_resource_group.linux_rg.name
  location            = azurerm_resource_group.linux_rg.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet creation within the Virtual Network
resource "azurerm_subnet" "linux_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.linux_rg.name
  virtual_network_name = azurerm_virtual_network.linux_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Linux VM creation
resource "azurerm_virtual_machine" "linux_vm" {
  count               = var.linux_vm_count

  name                = "lin-vm${count.index}"
  resource_group_name = azurerm_resource_group.linux_rg.name
  location            = azurerm_resource_group.linux_rg.location
  network_interface_ids = [azurerm_network_interface.linux_nic[count.index].id]
  vm_size             = "Standard_B2s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "lin-myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "lin-vm${count.index}"
    admin_username = "Student"
    admin_password = "$Coo...D00"
  }
  
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Network Interface creation for each VM
resource "azurerm_network_interface" "linux_nic" {
  count = var.linux_vm_count

  name                = "lin-example-nic${count.index}"
  location            = azurerm_resource_group.linux_rg.location
  resource_group_name = azurerm_resource_group.linux_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.linux_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux_ip[count.index].id
  }
}

# Public IP creation for each VM
resource "azurerm_public_ip" "linux_ip" {
  count               = var.linux_vm_count
  name                = "lin-example-ip${count.index}"
  resource_group_name = azurerm_resource_group.linux_rg.name
  location            = azurerm_resource_group.linux_rg.location
  allocation_method   = "Dynamic"
}

# Output the public IP addresses of the Linux VMs
output "linux_public_ips" {
  value = [azurerm_public_ip.linux_ip[*].ip_address]
}