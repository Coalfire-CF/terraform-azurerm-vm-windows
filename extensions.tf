resource "azurerm_virtual_machine_extension" "vm_network_watcher" {
  name                       = "${var.vm_name}-network-watcher"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentWindows"
  type_handler_version       = "1.4"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_virtual_machine_extension.diagnostics]
}

resource "azurerm_virtual_machine_extension" "diagnostics" {
  name                       = "${var.vm_name}-diagnostics-extension"
  publisher                  = "Microsoft.Azure.Diagnostics"
  type                       = "IaaSDiagnostics"
  type_handler_version       = "1.16"
  auto_upgrade_minor_version = "true"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  settings                   = templatefile("${path.module}/shellscripts/winDiagnostics.json", { resource_id = azurerm_windows_virtual_machine.vm.id, storage_name = var.storage_account_vmdiag_name })

  # depends_on = [azurerm_virtual_machine_extension.domjoin]

  protected_settings = <<SETTINGS
  {
    "managedIdentity": {},
    "storageAccountName": "${var.storage_account_vmdiag_name}"
  }
SETTINGS
}

#Wait for role assignments to propagate before installing extensions (otherwise extension will fail to download scripts)
resource "time_sleep" "wait_180_seconds" {
  create_duration = "180s"
  depends_on = [
    azurerm_role_assignment.sa_install_assignment,
    azurerm_role_assignment.dj_kv_assignment,
    azurerm_role_assignment.custom_assignments
  ]
}

# Domain Join and Custom Script Extensions
resource "azurerm_virtual_machine_extension" "custom_extension" {
  count                      = var.is_domain_join || var.custom_scripts_fileUris != null ? 1 : 0
  depends_on                 = [time_sleep.wait_180_seconds]
  name                       = "custom_extension"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  auto_upgrade_minor_version = "true"
  type_handler_version       = "1.10"

  protected_settings = jsonencode({
    "managedIdentity"  = {}
    "commandToExecute" = local.commandToExecute
    "fileUris"         = local.fileUris
  })
}
