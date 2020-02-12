#######################################
## Azure VM with IIS Module - Output ##
#######################################

output "iis_vm_name" {
  description = "Virtual Machine name"
  value       = azurerm_virtual_machine.iis-vm.name
}

output "iis_vm_ip_address" {
  description = "Virtual Machine name IP Address"
  value       = azurerm_public_ip.iis-vm-ip.ip_address
}

output "iis_vm_admin_username" {
  description = "Username password for the Virtual Machine"
  value       = azurerm_virtual_machine.iis-vm.os_profile.*
  #sensitive   = true
}

output "iis_vm_admin_password" {
  description = "Administrator password for the Virtual Machine"
  value       = random_password.iis-vm-password.result
  #sensitive   = true
}

