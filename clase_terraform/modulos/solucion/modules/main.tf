provider "azurerm" {
  features {}
}

module "network" {
  source = "./modules/network"
  resource_group_name = var.resource_group_name
  location = var.location
  vnet_name = var.vnet_name
  subnet_name = var.subnet_name
}

module "virtual_machine" {
  source = "./modules/virtual_machine"
  resource_group_name = var.resource_group_name
  location = var.location
  vm_name = var.vm_name
  vm_size = var.vm_size
}
