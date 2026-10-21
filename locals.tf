locals {
  # Caller tags win on key collisions.
  tags = merge(var.global_tags, var.regional_tags, var.tags)

  fileUris = (
    var.is_domain_join ?
    concat([var.domain_join.windows_domainjoin_url], var.custom_scripts_fileUris) :
    var.custom_scripts_fileUris
  )

  # The data flow carries only the streams the configured data sources produce.
  dcr_streams = distinct(concat(
    flatten([for e in var.windows_event_logs : e.streams]),
    flatten([for p in var.performance_counters : p.streams]),
  ))

  # Microsoft Learn, "Supported log categories - Microsoft.Network/publicIPAddresses".
  public_ip_log_categories = ["DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports"]

  # Microsoft Learn, "Supported log categories - Microsoft.Compute/virtualMachines".
  vm_log_categories = ["SoftwareUpdateProfile", "SoftwareUpdates"]

  custom_extension_enabled = var.is_domain_join || length(var.custom_scripts_fileUris) > 0

  # CustomScriptExtension on Windows runs commandToExecute through cmd.exe.
  # Everything runs in PowerShell; -EncodedCommand avoids cmd.exe quoting.
  # Each value is a PowerShell single-quoted string with embedded quotes doubled.
  ps_quote = { for k, v in {
    domain_name  = try(var.domain_join.domain_name, "")
    ou_path      = try(var.domain_join.disname, "")
    admins_group = try(var.domain_join.windows_admins_ad_group, "")
    user_name    = try(var.domain_join.user_name, "")
    key_vault    = var.dj_kv_name == null ? "" : var.dj_kv_name
    azure_cloud  = try(var.domain_join.azure_cloud, "")
  } : k => "'${replace(v, "'", "''")}'" }

  # A join script that ends with a non-zero exit code stops the run here,
  # so later custom_scripts statements cannot mask the failure.
  domain_join_script = var.is_domain_join ? join(" ", [
    "& '.\\${basename(var.domain_join.windows_domainjoin_url)}'",
    "-DomainName ${local.ps_quote.domain_name}",
    "-OUPath ${local.ps_quote.ou_path}",
    "-AdminsGroup ${local.ps_quote.admins_group}",
    "-UserName ${local.ps_quote.user_name}",
    "-KeyVaultName ${local.ps_quote.key_vault}",
    "-HostName '${azurerm_windows_virtual_machine.vm.computer_name}'",
    "-AzureCloud ${local.ps_quote.azure_cloud};",
    "if ($LASTEXITCODE) { exit $LASTEXITCODE };",
  ]) : ""

  ps_script = join("\n", compact([
    "$ErrorActionPreference = 'Stop'",
    local.domain_join_script,
    chomp(var.custom_scripts),
  ]))

  commandToExecute = "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(local.ps_script, "UTF-16LE")}"
}
