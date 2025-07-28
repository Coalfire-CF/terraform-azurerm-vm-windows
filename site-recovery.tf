module "site_recovery" {
  source = "git::https://github.com/Coalfire-CF/terraform-azurerm-vm-site-recovery.git?ref=v0.0.1"

  enable_site_recovery = false
  vm_id                = azurerm_windows_virtual_machine.vm.id
  vm_name              = var.vm_name
  recovery_vault_name  = var.recovery_vault_name
  recovery_vault_rg    = var.recovery_vault_rg
  resource_group_name  = var.resource_group_name
  target_region        = var.target_region
}
