resource "azurerm_virtual_machine_extension" "vm_network_watcher" {
  name                       = "${var.vm_name}-network-watcher"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentWindows"
  type_handler_version       = "1.4"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_virtual_machine_extension.ama]
}

# Installs the Azure Monitor Agent
resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "${var.vm_name}-azure-monitor-agent"
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.34" # latest as of 04/22/2025 in GovCloud
  automatic_upgrade_enabled  = true   # automatically updates the agent to latest version
  auto_upgrade_minor_version = true   # automatically grabs the latest patch version IE 1.34.5
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  settings                   = jsonencode(var.ama_settings)
}

# Create the data collection rule for the Azure Monitor Agent
resource "azurerm_monitor_data_collection_rule" "ama_dcr" {
  name                = "${var.vm_name}-dcr"
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      name                  = "loganalytics"
      workspace_resource_id = data.azurerm_log_analytics_workspace.log_analytics.id
    }
  }

  data_flow {
    streams      = ["Microsoft-WindowsEvent", "Microsoft-Perf"]
    destinations = ["loganalytics"]
  }

}

# Associate the data collection rule with the Azure Monitor Agent on the VM
resource "azurerm_monitor_data_collection_rule_association" "ama_dcr_assoc" {
  name                    = "${var.vm_name}-azure-monitor-agent-dcr-assoc"
  target_resource_id      = azurerm_windows_virtual_machine.vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.ama_dcr.id
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
