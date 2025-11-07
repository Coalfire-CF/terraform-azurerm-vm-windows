![Coalfire](coalfire_logo.png)

# terraform-azurerm-vm-windows

This module is used in the [Coalfire-Azure-RAMPpak](https://github.com/Coalfire-CF/Coalfire-Azure-RAMPpak) FedRAMP Framework. It will create a Windows Virtual Machine using managed disks.

Learn more at [Coalfire OpenSource](https://coalfire.com/opensource).

## Dependencies

- Security Core
- Region Setup

## Resource List

- VM
- VM Nic
- Public IP (optional)
- AKV secret
- Diagnostics extension
- Network watcher extension

## Deployment Steps

This module can be called as outlined below.

- Change directories to the `Bastion` directory.
- From the `/terraform/prod/us-va/mgmt/bastion` directory run `terraform init`.
- Run `terraform plan` to review the resources being created.
- If everything looks correct in the plan output, run `terraform apply`.

### Usage with source_image_reference

```hcl
provider "azurerm" {
  features {}
}

module "bastion1" {
  source = "github.com/Coalfire-CF/terraform-azurerm-vm-windows"

  vm_name                       = "${local.vm_name_prefix}ba1"
  vm_admin_username             = var.vm_admin_username
  location                      = var.location
  resource_group_name           = data.terraform_remote_state.core.outputs.core_rg_name
  size                          = "Standard_DS2_v2"
  enable_public_ip              = true
  subnet_id                     = data.terraform_remote_state.usgv_mgmt_vnet.outputs.usgv_mgmt_vnet_subnet_ids["${local.resource_prefix}-bastion-sn-1"]
  private_ip_address_allocation = "Dynamic"
  vm_diag_sa                    = data.terraform_remote_state.setup.outputs.vmdiag_endpoint
  storage_account_vmdiag_name   = data.terraform_remote_state.setup.outputs.storage_account_vmdiag_name
  kv_id                         = data.terraform_remote_state.core.outputs.core_kv_id
  trusted_launch                = false # For now, we are not using trusted launch. Fails with the CIS marketplace image.

  regional_tags                 = var.regional_tags
  global_tags                   = var.global_tags

  source_image_reference = {
    publisher = "center-for-internet-security-inc"
    offer     = "cis-win-2019-stig"
    sku       = "cis-win-2019-stig"
    version   = "latest"
  }

  plan = {
    publisher = "center-for-internet-security-inc"
    name      = "cis-win-2019-stig"
    product   = "cis-win-2019-stig"
  }

  vm_tags = {
    OS       = "Windows_STIG_2019"
    Function = "Bastion"
    Plane    = "Management"
  }
}
```

### Usage with source_image_id

```hcl
provider "azurerm" {
  features {}
}

module "bastion_custom" {
  source = "github.com/Coalfire-CF/terraform-azurerm-vm-windows"

  vm_name                       = "${local.vm_name_prefix}ba1"
  vm_admin_username             = var.vm_admin_username
  location                      = var.location
  resource_group_name           = data.terraform_remote_state.core.outputs.core_rg_name
  size                          = "Standard_DS2_v2"
  enable_public_ip              = true
  subnet_id                     = data.terraform_remote_state.usgv_mgmt_vnet.outputs.usgv_mgmt_vnet_subnet_ids["${local.resource_prefix}-bastion-sn-1"]
  private_ip_address_allocation = "Dynamic"
  vm_diag_sa                    = data.terraform_remote_state.setup.outputs.vmdiag_endpoint
  storage_account_vmdiag_name   = data.terraform_remote_state.setup.outputs.storage_account_vmdiag_name
  kv_id                         = data.terraform_remote_state.core.outputs.core_kv_id
  trusted_launch                = false

  regional_tags                 = var.regional_tags
  global_tags                   = var.global_tags

  source_image_id               = data.terraform_remote_state.setup.outputs.vm_image_definitions["win-server2022-golden"]
  source_image_reference        = null

  vm_tags = {
    OS       = "Windows_SIG"
    Function = "Bastion"
    Plane    = "Management"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.xadm_pass](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_monitor_data_collection_rule.ama_dcr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule) | resource |
| [azurerm_monitor_data_collection_rule_association.ama_dcr_assoc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule_association) | resource |
| [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_role_assignment.custom_assignments](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.dj_kv_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.sa_install_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_virtual_machine_extension.ama](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.custom_extension](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.vm_network_watcher](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
| [random_password.lap](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [time_sleep.wait_180_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_log_analytics_workspace.log_analytics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ama_settings"></a> [ama\_settings](#input\_ama\_settings) | Optional settings to pass to the Azure Monitor Agent extension | `map(any)` | `{}` | no |
| <a name="input_availability_set_id"></a> [availability\_set\_id](#input\_availability\_set\_id) | Azure Availability VM should be attached to | `string` | `null` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Specifies an Availability Zone in which the Windows VM should be located | `list(number)` | `null` | no |
| <a name="input_custom_dns_label"></a> [custom\_dns\_label](#input\_custom\_dns\_label) | The DNS label to use for public access. VM name if not set. DNS will be <label>.eastus2.cloudapp.azure.com | `string` | `""` | no |
| <a name="input_custom_role_assignments"></a> [custom\_role\_assignments](#input\_custom\_role\_assignments) | n/a | <pre>list(object({<br/>    scope = string<br/>    role  = string<br/>  }))</pre> | `[]` | no |
| <a name="input_custom_scripts"></a> [custom\_scripts](#input\_custom\_scripts) | Custom scripts with its arguments. Will be added to custom script extension. | `string` | `""` | no |
| <a name="input_custom_scripts_fileUris"></a> [custom\_scripts\_fileUris](#input\_custom\_scripts\_fileUris) | List with storage URLs to download custom scripts | `list(string)` | `null` | no |
| <a name="input_disk_caching"></a> [disk\_caching](#input\_disk\_caching) | Type of caching used for Internal OS Disk - Must be one of [None, ReadOnly, ReadWrite] | `string` | `"ReadWrite"` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Size of the Disk | `number` | `127` | no |
| <a name="input_dj_kv_name"></a> [dj\_kv\_name](#input\_dj\_kv\_name) | Key Vault name containing the domain join user password | `string` | `null` | no |
| <a name="input_domain_join"></a> [domain\_join](#input\_domain\_join) | Map with information required to join the vm to the domain | <pre>object({<br/>    domain_name             = string<br/>    disname                 = string<br/>    windows_admins_ad_group = string<br/>    user_name               = string<br/>    azure_cloud             = string<br/>    windows_domainjoin_url  = string<br/>    dj_kv_id                = string<br/>  })</pre> | `null` | no |
| <a name="input_enable_public_ip"></a> [enable\_public\_ip](#input\_enable\_public\_ip) | True/False if a Public IP Address should be attached to the VM | `bool` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global level tags | `map(string)` | n/a | yes |
| <a name="input_is_domain_join"></a> [is\_domain\_join](#input\_is\_domain\_join) | n/a | `bool` | `false` | no |
| <a name="input_kv_id"></a> [kv\_id](#input\_kv\_id) | Key Vault Resource ID to store local admin password | `string` | `null` | no |
| <a name="input_la_name"></a> [la\_name](#input\_la\_name) | Log analytics workspace name | `string` | n/a | yes |
| <a name="input_la_resource_group_name"></a> [la\_resource\_group\_name](#input\_la\_resource\_group\_name) | Log analytics resource group name | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for resource deployment | `string` | n/a | yes |
| <a name="input_performance_counters"></a> [performance\_counters](#input\_performance\_counters) | Performance counters to collect | <pre>list(object({<br/>    name                          = string<br/>    streams                       = list(string)<br/>    sampling_frequency_in_seconds = number<br/>    counter_specifiers            = list(string)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "counter_specifiers": [<br/>      "\\Processor Information(_Total)\\% Processor Time",<br/>      "\\Processor Information(_Total)\\% Privileged Time",<br/>      "\\Processor Information(_Total)\\% User Time",<br/>      "\\Processor Information(_Total)\\Processor Frequency",<br/>      "\\System\\Processes",<br/>      "\\Process(_Total)\\Thread Count",<br/>      "\\Process(_Total)\\Handle Count",<br/>      "\\System\\System Up Time",<br/>      "\\System\\Context Switches/sec",<br/>      "\\System\\Processor Queue Length",<br/>      "\\Memory\\% Committed Bytes In Use",<br/>      "\\Memory\\Available Bytes",<br/>      "\\Memory\\Committed Bytes",<br/>      "\\Memory\\Cache Bytes",<br/>      "\\Memory\\Pool Paged Bytes",<br/>      "\\Memory\\Pool Nonpaged Bytes",<br/>      "\\Memory\\Pages/sec",<br/>      "\\Memory\\Page Faults/sec",<br/>      "\\Process(_Total)\\Working Set",<br/>      "\\Process(_Total)\\Working Set - Private",<br/>      "\\LogicalDisk(_Total)\\% Disk Time",<br/>      "\\LogicalDisk(_Total)\\% Disk Read Time",<br/>      "\\LogicalDisk(_Total)\\% Disk Write Time",<br/>      "\\LogicalDisk(_Total)\\% Idle Time",<br/>      "\\LogicalDisk(_Total)\\Disk Bytes/sec",<br/>      "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",<br/>      "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",<br/>      "\\LogicalDisk(_Total)\\Disk Transfers/sec",<br/>      "\\LogicalDisk(_Total)\\Disk Reads/sec",<br/>      "\\LogicalDisk(_Total)\\Disk Writes/sec",<br/>      "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",<br/>      "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",<br/>      "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",<br/>      "\\LogicalDisk(_Total)\\Avg. Disk Queue Length",<br/>      "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length",<br/>      "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length",<br/>      "\\LogicalDisk(_Total)\\% Free Space",<br/>      "\\LogicalDisk(_Total)\\Free Megabytes",<br/>      "\\Network Interface(*)\\Bytes Total/sec",<br/>      "\\Network Interface(*)\\Bytes Sent/sec",<br/>      "\\Network Interface(*)\\Bytes Received/sec",<br/>      "\\Network Interface(*)\\Packets/sec",<br/>      "\\Network Interface(*)\\Packets Sent/sec",<br/>      "\\Network Interface(*)\\Packets Received/sec",<br/>      "\\Network Interface(*)\\Packets Outbound Errors",<br/>      "\\Network Interface(*)\\Packets Received Errors"<br/>    ],<br/>    "name": "windows-performance",<br/>    "sampling_frequency_in_seconds": 60,<br/>    "streams": [<br/>      "Microsoft-Perf"<br/>    ]<br/>  }<br/>]</pre> | no |
| <a name="input_plan"></a> [plan](#input\_plan) | Marketplace plan info — only required if using a Marketplace image that includes a plan. | <pre>object({<br/>    publisher = string<br/>    name      = string<br/>    product   = string<br/>  })</pre> | `null` | no |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | Static Private IP address | `string` | `""` | no |
| <a name="input_private_ip_address_allocation"></a> [private\_ip\_address\_allocation](#input\_private\_ip\_address\_allocation) | Dynamic or Static | `string` | `"Dynamic"` | no |
| <a name="input_public_ip_sku"></a> [public\_ip\_sku](#input\_public\_ip\_sku) | Sku for the public IP attached to the VM. Can be `null` if no public IP needed. | `string` | `"Standard"` | no |
| <a name="input_regional_tags"></a> [regional\_tags](#input\_regional\_tags) | Regional level tags | `map(string)` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure Resource Group resource will be deployed in | `string` | n/a | yes |
| <a name="input_sa_install_id"></a> [sa\_install\_id](#input\_sa\_install\_id) | Storage account id containing the install scripts | `string` | n/a | yes |
| <a name="input_size"></a> [size](#input\_size) | Azure Virtual Machine size | `string` | `"Standard_DS2_v2"` | no |
| <a name="input_source_image_id"></a> [source\_image\_id](#input\_source\_image\_id) | VM image from shared image gallery | `string` | `null` | no |
| <a name="input_source_image_reference"></a> [source\_image\_reference](#input\_source\_image\_reference) | VM image from shared image gallery | <pre>object({<br/>    publisher = string<br/>    offer     = string<br/>    sku       = string<br/>    version   = string<br/>  })</pre> | `null` | no |
| <a name="input_storage_account_vmdiag_name"></a> [storage\_account\_vmdiag\_name](#input\_storage\_account\_vmdiag\_name) | Storage Account VM diagnostics are stored in | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of the subnet the VM NIC should be attached to | `string` | n/a | yes |
| <a name="input_trusted_launch"></a> [trusted\_launch](#input\_trusted\_launch) | Enable Trusted Launch | `bool` | `true` | no |
| <a name="input_vm_admin_username"></a> [vm\_admin\_username](#input\_vm\_admin\_username) | Local Administrator Name | `string` | n/a | yes |
| <a name="input_vm_diag_sa"></a> [vm\_diag\_sa](#input\_vm\_diag\_sa) | Storage Account VM diagnostics are stored in | `string` | n/a | yes |
| <a name="input_vm_hostname"></a> [vm\_hostname](#input\_vm\_hostname) | (Optional) Hostname for the virtual machine. Must be 15 characters or less. | `string` | `null` | no |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | Azure Virtual Machine Name | `string` | n/a | yes |
| <a name="input_vm_storage_account_type"></a> [vm\_storage\_account\_type](#input\_vm\_storage\_account\_type) | The Type of Storage Account which should back the OS Disk | `string` | `"StandardSSD_LRS"` | no |
| <a name="input_vm_tags"></a> [vm\_tags](#input\_vm\_tags) | Key/Value tags that should be added to the VM | `map(string)` | `{}` | no |
| <a name="input_windows_event_logs"></a> [windows\_event\_logs](#input\_windows\_event\_logs) | Windows Event Logs to collect | <pre>list(object({<br/>    name           = string<br/>    streams        = list(string)<br/>    x_path_queries = list(string)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "windows-events",<br/>    "streams": [<br/>      "Microsoft-Event"<br/>    ],<br/>    "x_path_queries": [<br/>      "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]",<br/>      "Security!*[System[(band(Keywords,13510798882111488))]]",<br/>      "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]"<br/>    ]<br/>  }<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_interface_ids"></a> [network\_interface\_ids](#output\_network\_interface\_ids) | IDs of the VM NICs provisioned. |
| <a name="output_network_interface_private_ip"></a> [network\_interface\_private\_ip](#output\_network\_interface\_private\_ip) | Private IP addresses of the VM NICs |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The IP address allocated for the resource. |
| <a name="output_public_ip_dns_name"></a> [public\_ip\_dns\_name](#output\_public\_ip\_dns\_name) | FQDN to connect to the first VM provisioned. |
| <a name="output_public_ip_id"></a> [public\_ip\_id](#output\_public\_ip\_id) | ID of the public IP address provisioned. |
| <a name="output_vm_id"></a> [vm\_id](#output\_vm\_id) | Virtual Machine Resource ID |
| <a name="output_vm_name"></a> [vm\_name](#output\_vm\_name) | Virtual Machine Name |
| <a name="output_vm_system_identity"></a> [vm\_system\_identity](#output\_vm\_system\_identity) | Virtual Machine System Managed Identity |
| <a name="output_vm_xadm_kv_name"></a> [vm\_xadm\_kv\_name](#output\_vm\_xadm\_kv\_name) | The name which the local admin password for the 'xadm' account is stored under in Key Vault |
<!-- END_TF_DOCS -->

## Contributing

[Start Here](CONTRIBUTING.md)

## License

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/license/mit/)

## Contact Us

[Coalfire](https://coalfire.com/)

### Copyright

Copyright © 2025 Coalfire Systems Inc.
## Tree
```
.
|-- CHANGELOG.md
|-- CONTRIBUTING.md
|-- LICENSE
|-- README.md
|-- coalfire_logo.png
|-- data.tf
|-- extensions.tf
|-- locals.tf
|-- network.tf
|-- outputs.tf
|-- release-please-config.json
|-- variables.tf
|-- vm.tf
```
