![Coalfire](coalfire_logo.png)

# terraform-azurerm-vm-windows

This module is used in the [Coalfire-Azure-RAMPpak](https://github.com/Coalfire-CF/Coalfire-Azure-RAMPpak) FedRAMP Framework. It creates a Windows virtual machine with managed disks.

Learn more at [Coalfire OpenSource](https://coalfire.com/opensource).

## Dependencies

- Security Core
- Region Setup

## Resource List

- VM
- VM NIC
- Public IP (optional)
- Key Vault secret for the local admin password
- Azure Monitor Agent extension and data collection rule
- Network Watcher extension
- Custom script extension (optional, for domain join and custom scripts)
- Diagnostic settings for the VM, NIC, public IP and data collection rule

## Usage

The module has no provider block. The caller configures `azurerm` for Azure Government.
See [`examples/default`](examples/default) for a complete root.

```hcl
module "vm" {
  source = "git::https://github.com/Coalfire-CF/terraform-azurerm-vm-windows?ref=v3.0.0"

  vm_name               = "app-win-1"
  location              = var.location
  resource_group_name   = var.resource_group_name
  vm_admin_username     = "xadm"
  subnet_id             = var.subnet_id
  kv_id                 = var.kv_id
  vm_diag_sa            = var.vm_diag_sa
  sa_install_id         = var.sa_install_id
  diag_log_analytics_id = var.diag_log_analytics_id

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = {
    Function = "App"
  }
}
```

Set exactly one of `source_image_reference` or `source_image_id`.

## Password handling

The module generates the local admin password and writes it to the Key Vault at `kv_id`
through the write-only `value_wo` argument. The password is still in state, through
`random_password` and the VM's `admin_password`, because azurerm 5.10.0 has no
`admin_password_wo` on `azurerm_windows_virtual_machine`. Protect the state.

The secret is marked expired after `admin_password_expiration_days`. The expiry is
informational. Key Vault still returns an expired secret on a get, so the break-glass
password stays readable for recovery. The module does not rotate the password.

## Diagnostics

The VM, NIC, public IP and data collection rule use module-owned diagnostic settings,
because `terraform-azurerm-diagnostics` v3.0.0 has no resource type for them (decision D1).
Each sends its log categories and `AllMetrics` to `diag_log_analytics_id`. The data
collection rule sends Windows event logs and performance counters to the same workspace.

## Extension order

Extensions install one at a time: Azure Monitor Agent, then Network Watcher, then the custom
script. The custom script also waits 180 seconds after the role assignments, so the VM
identity can read the install storage account and the domain join Key Vault. The wait and the
custom script exist only when domain join or `custom_scripts_fileUris` is set.

## Custom script and domain join

The custom script extension runs PowerShell through `-EncodedCommand`. `custom_scripts` is
PowerShell statements, each ending in `;`.

- The script sets `$ErrorActionPreference = 'Stop'`, so a PowerShell error stops it and fails
  the extension.
- A native program that returns a non-zero exit code does not stop the script. Check
  `$LASTEXITCODE` yourself in `custom_scripts` when it matters.
- A join script that ends with a non-zero exit code stops the run and fails the extension.
- Keep inline statements short. The encoded command is about 2.7 times the script length and
  cmd.exe allows 8191 characters. Put long logic in a downloaded script file.

Domain join runs the `.ps1` at `domain_join.windows_domainjoin_url` from the download
directory with these parameters:

| Parameter | Source |
| --- | --- |
| `-DomainName` | `domain_join.domain_name` |
| `-OUPath` | `domain_join.disname` |
| `-AdminsGroup` | `domain_join.windows_admins_ad_group` |
| `-UserName` | `domain_join.user_name` |
| `-KeyVaultName` | `dj_kv_name` |
| `-HostName` | the VM computer name |
| `-AzureCloud` | `domain_join.azure_cloud` |

The caller supplies the script. It is not part of this module. Domain join has not been tested
in a live deployment.

## Other defaults

- Computer name: `vm_hostname`, or `vm_name` when it is null. Either must be 15 characters or
  less.
- Public IP: off by default. Set `enable_public_ip = true` only with an NSG that restricts
  management ports.
- Encryption at host: on by default. Turn it off only for a size that does not support it.
- Trusted launch: sets secure boot and vTPM, and needs a Gen2 image.
- Availability zone: none by default. It cannot be combined with `availability_set_id`.
