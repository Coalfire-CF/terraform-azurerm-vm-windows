module "vm_backup" {
  source              = "git::https://github.com/Coalfire-CF/terraform-azurerm-vm-backup.git?ref=v0.0.1"
  resource_group_name = var.resource_group_name
  recovery_vault_name = var.recovery_vault_name
  vm_id               = azurerm_linux_virtual_machine.vm.id
  policy_name         = local.backup_policy_name
  start_time          = "05:00" # midnight EST
  enable_backup       = true
}
