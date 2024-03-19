variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
}

variable "location" {
  description = "Ubicación de los recursos"
}

variable "vnet_name" {
  description = "Nombre de la red virtual"
}

variable "subnet_name" {
  description = "Nombre de la subred"
}

variable "vm_name" {
  description = "Nombre de la máquina virtual"
}

variable "vm_size" {
  description = "Tamaño de la máquina virtual"
}

variable "publisher" {
  description = "Editor de la imagen del sistema operativo"
}

variable "offer" {
  description = "Oferta de la imagen del sistema operativo"
}

variable "sku" {
  description = "SKU de la imagen del sistema operativo"
}

variable "version" {
  description = "Versión de la imagen del sistema operativo"
}

variable "admin_username" {
  description = "Nombre de usuario administrador de la VM"
}

variable "admin_password" {
  description = "Contraseña del usuario administrador de la VM"
}
