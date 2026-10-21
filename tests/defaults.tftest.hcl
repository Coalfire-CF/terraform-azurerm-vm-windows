# Offline checks. azurerm is mocked; random and time run locally.

mock_provider "azurerm" {}

variables {
  vm_name             = "test-vm"
  location            = "usgovvirginia"
  resource_group_name = "test-rg"
  vm_admin_username   = "xadm"
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  subnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-sn"
  kv_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.KeyVault/vaults/test-kv"
  sa_install_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Storage/storageAccounts/testinstall"
  diag_log_analytics_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.OperationalInsights/workspaces/test-la"
  vm_diag_sa            = "https://testdiag.blob.core.usgovcloudapi.net/"
}

# vm_hostname and dj_kv_name stay null here, so this run exercises both null defaults.
run "secure_defaults" {
  command = plan

  assert {
    condition     = azurerm_windows_virtual_machine.vm.encryption_at_host_enabled == true
    error_message = "Encryption at host must default to true."
  }
  assert {
    condition     = azurerm_windows_virtual_machine.vm.secure_boot_enabled == true && azurerm_windows_virtual_machine.vm.vtpm_enabled == true
    error_message = "Trusted launch must set secure boot and vTPM by default."
  }
  assert {
    condition     = azurerm_windows_virtual_machine.vm.computer_name == "test-vm"
    error_message = "computer_name must fall back to vm_name when vm_hostname is null."
  }
  assert {
    condition     = length(azurerm_public_ip.public_ip) == 0
    error_message = "No public IP by default."
  }
  assert {
    condition     = azurerm_network_interface.nic.ip_configuration[0].public_ip_address_id == null
    error_message = "The NIC must have no public IP by default."
  }
  assert {
    condition     = azurerm_key_vault_secret.xadm_pass.value_wo_version == 1
    error_message = "The admin password secret must use value_wo."
  }
  assert {
    condition     = azurerm_key_vault_secret.xadm_pass.content_type == "password"
    error_message = "The secret content type must be password."
  }
  assert {
    condition     = azurerm_windows_virtual_machine.vm.size == "Standard_D2s_v5"
    error_message = "Default size must be Standard_D2s_v5."
  }
}

run "diagnostics_wired" {
  command = plan

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.public_ip) == 0
    error_message = "No public IP diagnostic setting without a public IP."
  }
  assert {
    condition     = azurerm_monitor_diagnostic_setting.vm.log_analytics_workspace_id == var.diag_log_analytics_id
    error_message = "VM diagnostics must go to diag_log_analytics_id."
  }
  assert {
    condition     = azurerm_monitor_diagnostic_setting.nic.log_analytics_workspace_id == var.diag_log_analytics_id
    error_message = "NIC diagnostics must go to diag_log_analytics_id."
  }
  assert {
    condition     = azurerm_monitor_diagnostic_setting.dcr.log_analytics_workspace_id == var.diag_log_analytics_id
    error_message = "DCR diagnostics must go to diag_log_analytics_id."
  }
  assert {
    condition     = [for m in azurerm_monitor_diagnostic_setting.nic.enabled_metric : m.category] == ["AllMetrics"]
    error_message = "NIC diagnostics must send AllMetrics."
  }
  assert {
    condition     = toset([for l in azurerm_monitor_diagnostic_setting.vm.enabled_log : l.category]) == toset(["SoftwareUpdateProfile", "SoftwareUpdates"])
    error_message = "VM diagnostics must send every VM log category."
  }
  assert {
    condition     = toset([for l in azurerm_monitor_diagnostic_setting.dcr.enabled_log : l.category]) == toset(["LogErrors"])
    error_message = "DCR diagnostics must send LogErrors."
  }
  assert {
    condition     = azurerm_monitor_data_collection_rule.ama_dcr.destinations[0].log_analytics[0].workspace_resource_id == var.diag_log_analytics_id
    error_message = "The DCR must send to diag_log_analytics_id."
  }
}

run "public_ip_opt_in" {
  command = plan

  variables {
    enable_public_ip = true
    global_tags      = { Owner = "test" }
  }

  assert {
    condition     = length(azurerm_public_ip.public_ip) == 1
    error_message = "enable_public_ip = true must create a public IP."
  }
  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.public_ip) == 1
    error_message = "The public IP must get a diagnostic setting."
  }
  assert {
    condition     = toset([for l in azurerm_monitor_diagnostic_setting.public_ip[0].enabled_log : l.category]) == toset(["DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports"])
    error_message = "Public IP diagnostics must send every public IP log category."
  }
  assert {
    condition     = azurerm_public_ip.public_ip[0].tags["Owner"] == "test"
    error_message = "The public IP must carry global_tags."
  }
}

run "tags_merge" {
  command = plan

  variables {
    tags          = { Function = "vm" }
    regional_tags = { Region = "va" }
    global_tags   = { Owner = "test" }
  }

  assert {
    condition     = azurerm_windows_virtual_machine.vm.tags == tomap({ Function = "vm", Region = "va", Owner = "test" })
    error_message = "VM tags must merge all three tag inputs."
  }
  assert {
    condition     = azurerm_network_interface.nic.tags == tomap({ Function = "vm", Region = "va", Owner = "test" })
    error_message = "NIC tags must merge all three tag inputs."
  }
  assert {
    condition     = azurerm_key_vault_secret.xadm_pass.tags == tomap({ Function = "vm", Region = "va", Owner = "test" })
    error_message = "Secret tags must merge all three tag inputs."
  }
  assert {
    condition     = azurerm_monitor_data_collection_rule.ama_dcr.tags == tomap({ Function = "vm", Region = "va", Owner = "test" })
    error_message = "DCR tags must merge all three tag inputs."
  }
  assert {
    condition     = azurerm_virtual_machine_extension.ama.tags == tomap({ Function = "vm", Region = "va", Owner = "test" })
    error_message = "AMA extension tags must merge all three tag inputs."
  }
  assert {
    condition     = azurerm_virtual_machine_extension.vm_network_watcher.tags == tomap({ Function = "vm", Region = "va", Owner = "test" })
    error_message = "Network Watcher extension tags must merge all three tag inputs."
  }
}

run "tags_input_wins_on_collision" {
  command = plan

  variables {
    tags        = { Owner = "caller" }
    global_tags = { Owner = "global" }
  }

  assert {
    condition     = azurerm_windows_virtual_machine.vm.tags["Owner"] == "caller"
    error_message = "tags must win over global_tags on a key collision."
  }
}

run "no_custom_extension_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_virtual_machine_extension.custom_extension) == 0
    error_message = "No custom script extension without domain join or file URIs."
  }
  assert {
    condition     = length(time_sleep.wait_180_seconds) == 0
    error_message = "No wait without a custom script extension."
  }
}

run "domain_join_without_file_uris" {
  command = plan

  variables {
    is_domain_join = true
    dj_kv_name     = "dj-kv"
    domain_join = {
      domain_name             = "corp.example"
      disname                 = "OU=Servers,DC=corp,DC=example"
      windows_admins_ad_group = "admins"
      user_name               = "joiner"
      azure_cloud             = "AzureUSGovernment"
      windows_domainjoin_url  = "https://testinstall.blob.core.usgovcloudapi.net/scripts/join-domain.ps1"
      dj_kv_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.KeyVault/vaults/dj-kv"
    }
  }

  assert {
    condition     = length(azurerm_virtual_machine_extension.custom_extension) == 1
    error_message = "Domain join must create the custom script extension."
  }
  assert {
    condition     = length(time_sleep.wait_180_seconds) == 1
    error_message = "Domain join must create the role propagation wait."
  }
  assert {
    condition     = length(azurerm_role_assignment.dj_kv_assignment) == 1
    error_message = "Domain join must grant the VM access to the join Key Vault."
  }
  assert {
    condition     = startswith(jsondecode(azurerm_virtual_machine_extension.custom_extension[0].protected_settings).commandToExecute, "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ")
    error_message = "The command must run PowerShell with an encoded command."
  }
  assert {
    condition     = strcontains(local.ps_script, "& '.\\join-domain.ps1' -DomainName ")
    error_message = "The script must call the downloaded join script."
  }
  assert {
    condition     = strcontains(local.ps_script, "-KeyVaultName 'dj-kv'")
    error_message = "The script must pass dj_kv_name."
  }
  assert {
    condition     = strcontains(local.ps_script, "-HostName 'test-vm'")
    error_message = "The script must pass the computer name."
  }
  assert {
    condition     = strcontains(local.ps_script, "if ($LASTEXITCODE) { exit $LASTEXITCODE };")
    error_message = "The script must stop on a non-zero join script exit code."
  }
  assert {
    condition     = !strcontains(local.ps_script, ".sh")
    error_message = "The script must not reference a shell script."
  }
  assert {
    condition     = jsondecode(azurerm_virtual_machine_extension.custom_extension[0].protected_settings).fileUris == ["https://testinstall.blob.core.usgovcloudapi.net/scripts/join-domain.ps1"]
    error_message = "fileUris must hold only the join script."
  }
  assert {
    condition     = textdecodebase64(trimprefix(jsondecode(azurerm_virtual_machine_extension.custom_extension[0].protected_settings).commandToExecute, "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand "), "UTF-16LE") == local.ps_script
    error_message = "The encoded command must decode to the script."
  }
}

run "domain_join_requires_inputs" {
  command = plan

  variables {
    is_domain_join = true
    domain_join    = null
  }

  expect_failures = [var.is_domain_join]
}

run "domain_join_requires_ps1" {
  command = plan

  variables {
    is_domain_join = true
    dj_kv_name     = "dj-kv"
    domain_join = {
      domain_name             = "corp.example"
      disname                 = "OU=Servers,DC=corp,DC=example"
      windows_admins_ad_group = "admins"
      user_name               = "joiner"
      azure_cloud             = "AzureUSGovernment"
      windows_domainjoin_url  = "https://testinstall.blob.core.usgovcloudapi.net/scripts/join-domain.sh"
      dj_kv_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.KeyVault/vaults/dj-kv"
    }
  }

  expect_failures = [var.is_domain_join]
}

run "custom_scripts_only" {
  command = plan

  variables {
    custom_scripts_fileUris = ["https://testinstall.blob.core.usgovcloudapi.net/scripts/a.ps1"]
    custom_scripts          = "Write-Output 'x';"
  }

  assert {
    condition     = length(azurerm_virtual_machine_extension.custom_extension) == 1
    error_message = "File URIs must create the custom script extension."
  }
  assert {
    condition     = strcontains(local.ps_script, "Write-Output 'x';")
    error_message = "The script must include custom_scripts."
  }
  assert {
    condition     = !strcontains(local.ps_script, "-DomainName")
    error_message = "The script must not join the domain when is_domain_join is false."
  }
  assert {
    condition     = textdecodebase64(trimprefix(jsondecode(azurerm_virtual_machine_extension.custom_extension[0].protected_settings).commandToExecute, "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand "), "UTF-16LE") == "$ErrorActionPreference = 'Stop'\nWrite-Output 'x';"
    error_message = "The encoded command must decode to the exact script."
  }
}

run "disk_caching_accepts_none" {
  command = plan

  variables {
    disk_caching = "None"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.vm.os_disk[0].caching == "None"
    error_message = "disk_caching None must pass through."
  }
}

run "disk_caching_rejects_invalid" {
  command = plan

  variables {
    disk_caching = "Bogus"
  }

  expect_failures = [var.disk_caching]
}

run "image_required" {
  command = plan

  variables {
    source_image_reference = null
  }

  expect_failures = [var.source_image_id]
}

run "image_both_rejected" {
  command = plan

  variables {
    source_image_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Compute/galleries/g/images/i/versions/1.0.0"
  }

  expect_failures = [var.source_image_id]
}

run "image_id_only" {
  command = plan

  variables {
    source_image_reference = null
    source_image_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Compute/galleries/g/images/i/versions/1.0.0"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.vm.source_image_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Compute/galleries/g/images/i/versions/1.0.0"
    error_message = "source_image_id must pass through."
  }
}

run "zone_and_availability_set_conflict" {
  command = plan

  variables {
    availability_zone   = "1"
    availability_set_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Compute/availabilitySets/test-as"
  }

  expect_failures = [var.availability_zone]
}

run "zone_passthrough" {
  command = plan

  variables {
    availability_zone = "2"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.vm.zone == "2"
    error_message = "availability_zone must pass through."
  }
}

run "encryption_at_host_opt_out" {
  command = plan

  variables {
    encryption_at_host_enabled = false
  }

  assert {
    condition     = azurerm_windows_virtual_machine.vm.encryption_at_host_enabled == false
    error_message = "encryption_at_host_enabled = false must pass through."
  }
}

run "dcr_streams_follow_inputs" {
  command = plan

  variables {
    performance_counters = []
  }

  assert {
    condition     = azurerm_monitor_data_collection_rule.ama_dcr.data_flow[0].streams == tolist(["Microsoft-Event"])
    error_message = "DCR streams must follow the configured data sources."
  }
}

run "dcr_requires_a_source" {
  command = plan

  variables {
    performance_counters = []
    windows_event_logs   = []
  }

  expect_failures = [var.performance_counters]
}

run "hostname_too_long" {
  command = plan

  variables {
    vm_hostname = "abcdefghijklmnop"
  }

  expect_failures = [var.vm_hostname]
}

run "vm_name_too_long_without_hostname" {
  command = plan

  variables {
    vm_name = "abcdefghijklmnop"
  }

  expect_failures = [var.vm_name]
}

run "long_vm_name_with_hostname" {
  command = plan

  variables {
    vm_name     = "abcdefghijklmnop"
    vm_hostname = "shorthost"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.vm.computer_name == "shorthost"
    error_message = "computer_name must use vm_hostname when set."
  }
}

run "static_ip_requires_value" {
  command = plan

  variables {
    private_ip_address_allocation = "Static"
  }

  expect_failures = [var.private_ip]
}

run "static_ip_accepts_value" {
  command = plan

  variables {
    private_ip_address_allocation = "Static"
    private_ip                    = "10.0.0.10"
  }

  assert {
    condition     = azurerm_network_interface.nic.ip_configuration[0].private_ip_address == "10.0.0.10"
    error_message = "private_ip must pass through."
  }
}
