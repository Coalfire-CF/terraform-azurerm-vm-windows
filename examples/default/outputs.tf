output "vm_id" {
  description = "VM resource ID."
  value       = module.vm.vm_id
}

output "vm_system_identity" {
  description = "Principal ID of the VM system-assigned identity."
  value       = module.vm.vm_system_identity
}
