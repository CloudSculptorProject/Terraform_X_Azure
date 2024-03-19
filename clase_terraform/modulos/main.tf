provider "azurerm" {
  features {}
}

module "virtual_machine" {
  source              = "./modules/vm"
  resource_group_name = "<resource-group-name>"
  location            = "<location>"
  vnet_name           = "<vnet-name>"
  subnet_name         = "<subnet-name>"
  nic_name            = "<nic-name>"
  vm_name             = "<vm-name>"
  vm_size             = "<vm-size>"
  publisher           = "<publisher>"
  offer               = "<offer>"
  sku                 = "<sku>"
  version             = "<version>"
  admin_username      = "<admin-username>"
  admin_password      = "<admin-password>"
}
