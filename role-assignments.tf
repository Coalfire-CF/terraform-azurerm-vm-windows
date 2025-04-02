resource "azurerm_role_assignment" "sa_install_assignment" {
  scope                = var.sa_install_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_windows_virtual_machine.vm.identity.0.principal_id
}

resource "azurerm_role_assignment" "dj_kv_assignment" {
  count                = var.is_domain_join ? 1 : 0 # only add this assignment if the VM is joining the domain
  scope                = var.domain_join.dj_kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_virtual_machine.vm.identity.0.principal_id
}

resource "azurerm_role_assignment" "custom_assignments" {
  for_each             = { for entry in var.custom_role_assignments : "${replace(entry.role, " ", "")}_${split("/", entry.scope)[length(split("/", entry.scope)) - 1]}" => entry }
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_windows_virtual_machine.vm.identity.0.principal_id
}
