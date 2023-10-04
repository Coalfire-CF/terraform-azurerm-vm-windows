output "vm_system_identity" {
  value       = azurerm_windows_virtual_machine.vm.identity[0].principal_id
  description = "Virtual Machine System Managed Identity"
}

output "vm_xadm_kv_name" {
  value       = azurerm_key_vault_secret.xadm_pass.name
  description = "The name which the local admin password for the 'xadm' account is stored under in Key Vault"
}

output "vm_id" {
  value       = azurerm_windows_virtual_machine.vm.id
  description = "Virtual Machine Resource ID"
}

output "vm_name" {
  value       = azurerm_windows_virtual_machine.vm.name
  description = "Virtual Machine Name"
}

output "network_interface_ids" {
  value       = azurerm_network_interface.nic.*.id
  description = "IDs of the VM NICs provisioned."
}

output "network_interface_private_ip" {
  value       = azurerm_network_interface.nic.*.private_ip_address
  description = "Private IP addresses of the VM NICs"
}

output "public_ip_id" {
  value       = azurerm_public_ip.public_ip.*.id
  description = "ID of the public IP address provisioned."
}

output "public_ip_address" {
  value       = azurerm_public_ip.public_ip.*.ip_address
  description = "The IP address allocated for the resource."
}

output "public_ip_dns_name" {
  value       = azurerm_public_ip.public_ip.*.fqdn
  description = "FQDN to connect to the first VM provisioned."
}
