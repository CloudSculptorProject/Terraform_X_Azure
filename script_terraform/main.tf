# Resource Group creation
resource "azurerm_resource_group" "windows_rg" {
  name     = "CloudScuptor"
  location = "eastus"
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

  storage_image_id    =  var.ID

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

# Network Security Group creation for each VM
resource "azurerm_network_security_group" "windows_nsg" {
  count               = var.vm_count
  name                = "win-nsg-${count.index}"
  location            = azurerm_resource_group.windows_rg.location
  resource_group_name = azurerm_resource_group.windows_rg.name
  
  security_rule {
    name                       = "Allow-RDP-${count.index}"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with each VM's NIC
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  count               = var.vm_count
  network_interface_id = azurerm_network_interface.windows_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.windows_nsg[count.index].id
}

# Output the public IP addresses of the Windows VMs
output "windows_public_ips" {
  value = [azurerm_public_ip.windows_ip[*].ip_address]
}
