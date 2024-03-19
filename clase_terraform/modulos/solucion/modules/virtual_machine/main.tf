resource "azurerm_virtual_machine" "example" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  vm_size               = var.vm_size

  # Configuración de la máquina virtual como imagen, credenciales, etc.

  provisioner "local-exec" {
    command = "echo ${azurerm_virtual_machine.example.public_ip_address} > ip_address.txt"
  }
}

output "vm_public_ip_address" {
  value = azurerm_virtual_machine.example.public_ip_address
}
