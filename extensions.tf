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

# # IF DOMAIN JOIN: Join VM to domain and install custom scripts if any
# resource "azurerm_virtual_machine_extension" "custom_extension_domainjoin" {
#   count                      = var.is_domain_join ? 1 : 0
#   name                       = "ud-dj"
#   virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
#   publisher                  = "Microsoft.Azure.Extensions"
#   type                       = "CustomScript"
#   auto_upgrade_minor_version = "true"
#   type_handler_version       = "2.1"
#   depends_on = [
#     time_sleep.wait_180_seconds
#   ]

#   settings = jsonencode({
#     "fileUris" = concat([var.domain_join.linux_domainjoin_url, var.linux_monitor_agent_url], var.custom_scripts_fileUris)
#   })

#   protected_settings = jsonencode({
#     "commandToExecute" = "./ud_linux_join_ad.sh -d \"${var.domain_join.domain_name}\" -dis \"${var.domain_join.disname}\" -a \"${var.domain_join.linux_admins_ad_group}\" -u \"${var.domain_join.user_name}\" -v \"${local.dj_kv_name}\" --host \"${azurerm_linux_virtual_machine.vm.name}\" -c \"${var.domain_join.azure_cloud}\";${chomp(var.custom_scripts)} exit 0"
#     "managedIdentity"  = {}
#   })
# }

# # IF NOT DOMAIN JOIN: Join VM to domain and install custom scripts if any
# resource "azurerm_virtual_machine_extension" "ud_dj_custom_extension" {
#   count                      = var.is_domain_join ? 0 : 1
#   name                       = "ud-dj"
#   virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
#   publisher                  = "Microsoft.Azure.Extensions"
#   type                       = "CustomScript"
#   auto_upgrade_minor_version = "true"
#   type_handler_version       = "2.1"
#   depends_on = [
#     time_sleep.wait_180_seconds
#   ]

#   settings = jsonencode({
#     "fileUris" = var.custom_scripts_fileUris
#   })

#   protected_settings = jsonencode({
#     "commandToExecute" = "${chomp(var.custom_scripts)} exit 0"
#     "managedIdentity"  = {}
#   })
# }
