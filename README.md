# Coalfire Azure Windows Virtual Machine

## Description

This module creates a Windows Virtual Machine using managed disks

### Resource List

- VM
- VM Nic
- Public IP
- AKV secret
- Diagnostics extension
- Network watcher extension

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| vm_name | Azure Virtual Machine Name | string | N/A | yes |
| location | Azure region for resource deployment | string | N/A | yes |
| resource_group_name | Azure Resource Group resource will be deployed in | string | N/A | yes |
| vm_admin_username | Local Administrator name | string | N/A | yes |
| subnet_id | ID of the subnet the VM NIC should be attached to | string | N/A | yes |
| dj_kv_id | Domain Join Key Vault Resource ID | string | N/A | yes |
| source_image_id | VM image from shared image gallery (Needs to support multi-session) | string | N/A | yes |
| ssh_public_key | The Public Key which should be used for authentication | string | N/A | yes |
| storage_account_vmdiag_name | Storage Account name VM diagnostics are stored in | string | N/A | yes |
| vm_diag_sa | Storage Account name VM diagnostics are stored in | string | N/A | yes |
| regional_tags | Regional level tags | map(string) | N/A | yes |
| global_tags | Global level tags | map(string) | N/A | yes |
| enable_public_ip | True/False if a Public IP Address should be attached to the VM | bool | N/A | yes |
| diagnostics_storage_account_key | Storage Account key for diagnostics | string | N/A | yes |
| size | Azure Virtual Machine size | string | Standard_DS2_v2 | no |
| availability_set_id | Azure Availability VM should be attached to | string | null | no |
| vm_tags | Key/Value tags that should be added to the VM | map(string) | {} | no |
| private_ip_address_allocation | Dynamic or Static | string | Dynamic | no |
| private_ip | Static Private IP address | string | null | no |
| disk_caching | Type of caching used for Internal OS Disk - Must be one of [None, ReadOnly, ReadWrite] | string | ReadWrite | no |
| vm_storage_account_type | The Type of Storage Account which should back the OS Disk | string | StandardSSD_LRS | no |
| disk_size | Size of the Disk | number | 127 | no |
| custom_dns_label | The DNS label to use for public access. VM name if not set. DNS will be \<label\>.eastus2.cloudapp.azure.com | string | "" | no |
| public_ip_sku | Sku for the public IP attached to the VM. Can be `null` if no public IP needed | string | Standard | no |

### Outputs

| Name | Description |
|------|-------------|
| vm_system_identity | Virtual Machine System Managed Identity |
| vm_id | Virtual Machine Resource ID |
| vm_name | Virtual Machine Name |
| vm_xadm_kv_name | The name which the local admin password for the 'xadm' account is stored under in Key Vault |
| network_interface_ids | IDs of the VM NICs provisioned |
| network_interface_private_ip | Private IP addresses of the VM NICs |
| public_ip_id | ID of the public IP address provisioned |
| public_ip_address | The IP address allocated for the resource |
| public_ip_dns_name | FQDN to connect to the first VM provisioned |

### Usage

```hcl
module "windows_vm" {
  source = "github.com/Coalfire-CF/ACE-Azure-VM-Windows?ref=v1.0.0"

  vm_name                       = "${local.prefix}-vm"
  vm_admin_username             = var.vm_admin_username
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = local.location
  size                          = "Standard_B2ms"
  source_image_id               = data.terraform_remote_state.setup.outputs.windows_golden_id
  enable_public_ip              = true
  subnet_id                     = data.terraform_remote_state.va-mgmt-network.outputs.usgv_mgmt_vnet_subnet_ids["de-prod-va-mp-bastion-sn-1"]
  dj_kv_id                      = data.terraform_remote_state.usgv_key_vaults.outputs.usgv_dj_kv_id
  storage_account_vmdiag_name   = data.terraform_remote_state.setup.outputs.storage_account_vmdiag_name
  vm_diag_sa                    = data.terraform_remote_state.setup.outputs.vmdiag_endpoint
  private_ip_address_allocation = "Dynamic"
  #private_ip                    = cidrhost(data.terraform_remote_state.usgv_mgmt_vnet.outputs.networks[1]["cidr_block"], 6)
  disk_size = 12

  regional_tags = {}
  global_tags   = {}
  vm_tags = {
    OS         = "Windows_2019"
    Function   = "CA"
    Plane      = "Management"
    Stopinator = "False"
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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.xadm_pass](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_machine_extension.diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.vm_network_watcher](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
| [random_password.lap](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_set_id"></a> [availability\_set\_id](#input\_availability\_set\_id) | Azure Availability VM should be attached to | `string` | `null` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Specifies an Availability Zone in which the Windows VM should be located | `list(number)` | `null` | no |
| <a name="input_custom_dns_label"></a> [custom\_dns\_label](#input\_custom\_dns\_label) | The DNS label to use for public access. VM name if not set. DNS will be <label>.eastus2.cloudapp.azure.com | `string` | `""` | no |
| <a name="input_disk_caching"></a> [disk\_caching](#input\_disk\_caching) | Type of caching used for Internal OS Disk - Must be one of [None, ReadOnly, ReadWrite] | `string` | `"ReadWrite"` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Size of the Disk | `number` | `127` | no |
| <a name="input_dj_kv_id"></a> [dj\_kv\_id](#input\_dj\_kv\_id) | Domain Join Key Vault Resource ID | `string` | n/a | yes |
| <a name="input_enable_public_ip"></a> [enable\_public\_ip](#input\_enable\_public\_ip) | True/False if a Public IP Address should be attached to the VM | `bool` | n/a | yes |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global level tags | `map(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for resource deployment | `string` | n/a | yes |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | Static Private IP address | `string` | `""` | no |
| <a name="input_private_ip_address_allocation"></a> [private\_ip\_address\_allocation](#input\_private\_ip\_address\_allocation) | Dynamic or Static | `string` | `"Dynamic"` | no |
| <a name="input_public_ip_sku"></a> [public\_ip\_sku](#input\_public\_ip\_sku) | Sku for the public IP attached to the VM. Can be `null` if no public IP needed. | `string` | `"Standard"` | no |
| <a name="input_regional_tags"></a> [regional\_tags](#input\_regional\_tags) | Regional level tags | `map(string)` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure Resource Group resource will be deployed in | `string` | n/a | yes |
| <a name="input_size"></a> [size](#input\_size) | Azure Virtual Machine size | `string` | `"Standard_DS2_v2"` | no |
| <a name="input_source_image_id"></a> [source\_image\_id](#input\_source\_image\_id) | VM image from shared image gallery | `string` | n/a | yes |
| <a name="input_storage_account_vmdiag_name"></a> [storage\_account\_vmdiag\_name](#input\_storage\_account\_vmdiag\_name) | Storage Account VM diagnostics are stored in | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of the subnet the VM NIC should be attached to | `string` | n/a | yes |
| <a name="input_vm_admin_username"></a> [vm\_admin\_username](#input\_vm\_admin\_username) | Local Administrator Name | `string` | n/a | yes |
| <a name="input_vm_diag_sa"></a> [vm\_diag\_sa](#input\_vm\_diag\_sa) | Storage Account VM diagnostics are stored in | `string` | n/a | yes |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | Azure Virtual Machine Name | `string` | n/a | yes |
| <a name="input_vm_storage_account_type"></a> [vm\_storage\_account\_type](#input\_vm\_storage\_account\_type) | The Type of Storage Account which should back the OS Disk | `string` | `"StandardSSD_LRS"` | no |
| <a name="input_vm_tags"></a> [vm\_tags](#input\_vm\_tags) | Key/Value tags that should be added to the VM | `map(string)` | `{}` | no |

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