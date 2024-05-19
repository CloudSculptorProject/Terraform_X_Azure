# Resource Group creation
resource "azurerm_resource_group" "linux_rg" {
  name     = "Maquinas-Virtuales-Linux"
  location = "eastus"
}

# Locate the existing custom image from the Shared Image Gallery
data "azurerm_shared_image" "main" {
  name                = "VM_ISO_Linux"
  gallery_name        = "VM_Principal"
  resource_group_name = "CloudSculptor"
}

# Virtual Network creation
resource "azurerm_virtual_network" "linux_vnet" {
  name                = "linuxvnetexamen"
  resource_group_name = azurerm_resource_group.linux_rg.name
  location            = azurerm_resource_group.linux_rg.location
  address_space       = ["10.1.0.0/16"]
}

# Subnet creation within the Virtual Network
resource "azurerm_subnet" "linux_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.linux_rg.name
  virtual_network_name = azurerm_virtual_network.linux_vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

# Linux VM creation
resource "azurerm_virtual_machine" "linux_vm" {
  count               = var.vm_count

  name                = "linux-vm${count.index}"
  resource_group_name = azurerm_resource_group.linux_rg.name
  location            = azurerm_resource_group.linux_rg.location
  network_interface_ids = [azurerm_network_interface.linux_nic[count.index].id]
  vm_size             = "Standard_B2s"

  storage_image_reference {
    id = data.azurerm_shared_image.main.id
  }

  storage_os_disk {
    name              = "linux-myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "linux-vm${count.index}"
    admin_username = "Student"
    admin_password = "$Coob1...D00"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Network Interface creation for each VM
resource "azurerm_network_interface" "linux_nic" {
  count = var.vm_count

  name                = "linux-example-nic${count.index}"
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
  count               = var.vm_count
  name                = "linux-example-ip${count.index}"
  resource_group_name = azurerm_resource_group.linux_rg.name
  location            = azurerm_resource_group.linux_rg.location
  allocation_method   = "Dynamic"
}

# Network Security Group creation for each VM
resource "azurerm_network_security_group" "linux_nsg" {
  count               = var.vm_count
  name                = "linux-nsg-${count.index}"
  location            = azurerm_resource_group.linux_rg.location
  resource_group_name = azurerm_resource_group.linux_rg.name
  
  security_rule {
    name                       = "Allow-SSH-${count.index}"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with each VM's NIC
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  count               = var.vm_count
  network_interface_id = azurerm_network_interface.linux_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.linux_nsg[count.index].id
}

# Output the public IP addresses of the Linux VMs
output "linux_public_ips" {
  value = [azurerm_public_ip.linux_ip[*].ip_address]
}
