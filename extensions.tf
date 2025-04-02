resource "azurerm_virtual_machine_extension" "vm_network_watcher" {
  name                       = "${var.vm_name}-network-watcher"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentWindows"
  type_handler_version       = "1.4"
  auto_upgrade_minor_version = true
}

resource "time_sleep" "wait_180_seconds" {
  create_duration = "180s"
  depends_on = [
    azurerm_role_assignment.sa_install_assignment,
    azurerm_role_assignment.dj_kv_assignment,
    azurerm_role_assignment.custom_assignments
  ]
}

resource "azurerm_virtual_machine_extension" "windows_domain_join" {
  count                      = var.is_domain_join ? 1 : 0
  name                       = "ud-dj"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  auto_upgrade_minor_version = "true"
  type_handler_version       = "2.1"
  depends_on = [
    time_sleep.wait_180_seconds
  ]

  settings = jsonencode({
    "fileUris" = concat(
      [
        var.domain_join.linux_domainjoin_url,
        var.linux_monitor_agent_url
      ],
      var.custom_scripts_fileUris
    )
  })

  protected_settings = jsonencode({
    "commandToExecute" = "./ud_linux_join_ad.sh -d \"${var.domain_join.domain_name}\" -dis \"${var.domain_join.disname}\" -a \"${var.domain_join.linux_admins_ad_group}\" -u \"${var.domain_join.user_name}\" -v \"${local.dj_kv_name}\" --host \"${azurerm_linux_virtual_machine.vm.name}\" -c \"${var.domain_join.azure_cloud}\";./ud_linux_monitor_agent.sh -w \"${data.azurerm_log_analytics_workspace.log_analytics.workspace_id}\" -s \"${data.azurerm_log_analytics_workspace.log_analytics.primary_shared_key}\";${chomp(var.custom_scripts)} exit 0"
    "managedIdentity"  = {}
  })
}
