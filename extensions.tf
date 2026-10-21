resource "azurerm_virtual_machine_extension" "vm_network_watcher" {
  name                       = "${var.vm_name}-network-watcher"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentWindows"
  type_handler_version       = "1.4"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_virtual_machine_extension.ama]
  tags                       = local.tags
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
  tags                       = local.tags
}

# Create the data collection rule defaulted to grab all performance metrics and log events
resource "azurerm_monitor_data_collection_rule" "ama_dcr" {
  name                = "${var.vm_name}-azure-monitor-agent-dcr"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "Windows"
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }

  destinations {
    log_analytics {
      name                  = "loganalytics"
      workspace_resource_id = var.diag_log_analytics_id
    }
  }

  # Default is all events and levels
  data_sources {
    dynamic "windows_event_log" {
      for_each = var.windows_event_logs
      content {
        name           = windows_event_log.value.name
        streams        = windows_event_log.value.streams
        x_path_queries = windows_event_log.value.x_path_queries
      }
    }

    # Default is all metrics 60 seconds
    dynamic "performance_counter" {
      for_each = var.performance_counters
      content {
        name                          = performance_counter.value.name
        streams                       = performance_counter.value.streams
        sampling_frequency_in_seconds = performance_counter.value.sampling_frequency_in_seconds
        counter_specifiers            = performance_counter.value.counter_specifiers
      }
    }
  }

  data_flow {
    streams      = local.dcr_streams
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
  count           = local.custom_extension_enabled ? 1 : 0
  create_duration = "180s"
  depends_on = [
    azurerm_role_assignment.sa_install_assignment,
    azurerm_role_assignment.dj_kv_assignment,
    azurerm_role_assignment.custom_assignments
  ]
}

# Domain join and custom script extension.
# Extensions install one at a time: AMA, Network Watcher, then this one.
# It also waits for role assignment propagation.
resource "azurerm_virtual_machine_extension" "custom_extension" {
  count                      = local.custom_extension_enabled ? 1 : 0
  depends_on                 = [time_sleep.wait_180_seconds, azurerm_virtual_machine_extension.vm_network_watcher]
  name                       = "custom_extension"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  auto_upgrade_minor_version = true
  tags                       = local.tags
  type_handler_version       = "1.10"

  protected_settings = jsonencode({
    "managedIdentity"  = {}
    "commandToExecute" = local.commandToExecute
    "fileUris"         = local.fileUris
  })
}

# terraform-azurerm-diagnostics v3.0.0 has no data collection rule resource_type (D1).
# Microsoft Learn, "Supported log categories - Microsoft.Insights/datacollectionrules".
resource "azurerm_monitor_diagnostic_setting" "dcr" {
  name                       = "${var.vm_name}-dcr-diag"
  target_resource_id         = azurerm_monitor_data_collection_rule.ama_dcr.id
  log_analytics_workspace_id = var.diag_log_analytics_id

  enabled_log {
    category = "LogErrors"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
