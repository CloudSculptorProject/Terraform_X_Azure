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

# Creación del Storage Account solo si no existe
resource "azurerm_storage_account" "storage_account" {
  name                     = "vhdexamen"
  resource_group_name      = azurerm_resource_group.storage_rg.name
  location                 = azurerm_resource_group.storage_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Creación del Container para Windows solo si no existe
resource "azurerm_storage_container" "windows_container" {
  name                  = "windowscontainer"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

# Creación del Container para Linux solo si no existe
resource "azurerm_storage_container" "linux_container" {
  name                  = "linuxcontainer"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

# Subir todos los archivos de la carpeta vhdwindows al contenedor de Azure Storage
locals {
  windows_file_paths = fileset("./vhdwindows", "**")
  linux_file_paths   = fileset("./vhdlinux", "**")
}

resource "azurerm_storage_blob" "windows_blob" {
  for_each = { for p in local.windows_file_paths : p => p }

  name                   = each.value
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.windows_container.name
  type                   = "Block"
  source                 = each.value
}

resource "azurerm_storage_blob" "linux_blob" {
  for_each = { for p in local.linux_file_paths : p => p }

  name                   = each.value
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.linux_container.name
  type                   = "Block"
  source                 = each.value
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

# Agrega el recurso azurerm_managed_disk para representar tu VHD existente
resource "azurerm_managed_disk" "example" {
  count                = var.vm_count
  name                 = "example-disk${count.index}"
  location             = azurerm_resource_group.storage_rg.location
  resource_group_name  = azurerm_resource_group.storage_rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Import"
  disk_size_gb         = 128  # Reemplaza con el tamaño adecuado para tu disco
  import_source_uri    = "https://vhdexamen.blob.core.windows.net/vhd/WindowsDaw.VHD"
}

# Creación de las máquinas virtuales solicitadas
resource "azurerm_virtual_machine" "example" {
  count               = var.vm_count

  name                = "vm${count.index}"
  resource_group_name = azurerm_resource_group.storage_rg.name
  location            = azurerm_resource_group.storage_rg.location
  network_interface_ids = [azurerm_network_interface.example[count.index].id]
  vm_size             = "Standard_B2s"

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
    admin_username = "Student"
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

# Output para mostrar las direcciones IP públicas de las máquinas virtuales
output "public_ips" {
  value = [azurerm_public_ip.example[*].ip_address]
}
