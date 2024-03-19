module "virtual_machine" {
  source              = "./modules/vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = var.vnet_name
  subnet_name         = var.subnet_name
  nic_name            = var.nic_name
  vm_name             = var.vm_name
  vm_size             = var.vm_size
  publisher           = var.publisher
  offer               = var.offer
  sku                 = var.sku
  version             = var.version
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  depends_on = [module.network]
}
