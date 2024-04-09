# Provider configuration
provider "azurerm" {
  features {}
}

# Variable declaration
variable "vm_count" {
  description = "Number of Windows virtual machines to create"
  type        = number
}

# Resource Group creation
resource "azurerm_resource_group" "windows_rg" {
  name     = "examen_DAW"
  location = "eastus"
}

# Storage Account creation
resource "azurerm_storage_account" "windows_storage_account" {
  name                     = "vhdexamen"
  resource_group_name      = azurerm_resource_group.windows_rg.name
  location                 = azurerm_resource_group.windows_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container creation for Windows VHDs
resource "azurerm_storage_container" "windows_container" {
  name                  = "windowscontainer"
  storage_account_name  = azurerm_storage_account.windows_storage_account.name
  container_access_type = "private"
}

# Upload Windows VHDs to the storage container
locals {
  windows_file_paths = fileset("./vhdwindows", "**")
}

resource "azurerm_storage_blob" "windows_blob" {
  for_each = { for p in local.windows_file_paths : p => p }

  name                   = each.value
  storage_account_name   = azurerm_storage_account.windows_storage_account.name
  storage_container_name = azurerm_storage_container.windows_container.name
  type                   = "Block"
  source                 = each.value
}

# Virtual Network creation
resource "azurerm_virtual_network" "windows_vnet" {
  name                = "winvnetexamen"
  resource_group_name = azurerm_resource_group.windows_rg.name
  location            = azurerm_resource_group.windows_rg.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet creation within the Virtual Network
resource "azurerm_subnet" "windows_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.windows_rg.name
  virtual_network_name = azurerm_virtual_network.windows_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Windows VM creation
resource "azurerm_virtual_machine" "windows_vm" {
  count               = var.vm_count

  name                = "win-vm${count.index}"
  resource_group_name = azurerm_resource_group.windows_rg.name
  location            = azurerm_resource_group.windows_rg.location
  network_interface_ids = [azurerm_network_interface.windows_nic[count.index].id]
  vm_size             = "Standard_B2s"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  storage_os_disk {
    name              = "win-myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "win-vm${count.index}"
    admin_username = "Student"
    admin_password = "$Coo...D00"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
    timezone                  = "UTC"
  }
}

# Network Interface creation for each VM
resource "azurerm_network_interface" "windows_nic" {
  count = var.vm_count

  name                = "win-example-nic${count.index}"
  location            = azurerm_resource_group.windows_rg.location
  resource_group_name = azurerm_resource_group.windows_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.windows_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows_ip[count.index].id
  }
}

# Public IP creation for each VM
resource "azurerm_public_ip" "windows_ip" {
  count               = var.vm_count
  name                = "win-example-ip${count.index}"
  resource_group_name = azurerm_resource_group.windows_rg.name
  location            = azurerm_resource_group.windows_rg.location
  allocation_method   = "Dynamic"
}

# Output the public IP addresses of the Windows VMs
output "windows_public_ips" {
  value = [azurerm_public_ip.windows_ip[*].ip_address]
}