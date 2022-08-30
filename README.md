# Coalfire Azure Windows Virtual Machine

## v1.0.0 - 2022-08-30

### **Description**

This module creates a Windows Virtual Machine using managed disks

### **Resource List**
- VM
- VM Nic
- Public IP
- AKV secret
- Diagnostics extension
- Network watcher extension

### **Inputs**

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
| private_ip_address_allocation | Dyanmic or Static | string | Dynamic | no |
| private_ip | Static Private IP address | string | null | no |
| disk_caching | Type of caching used for Internal OS Disk - Must be one of [None, ReadOnly, ReadWrite] | string | ReadWrite | no |
| vm_storage_account_type | The Type of Storage Account which should back the OS Disk | string | StandardSSD_LRS | no |
| disk_size | Size of the Disk | number | 127 | no |
| custom_dns_label | The DNS label to use for public access. VM name if not set. DNS will be <label>.eastus2.cloudapp.azure.com | string | "" | no |
| public_ip_sku | Sku for the public IP attached to the VM. Can be `null` if no public IP needed | string | Standard | no | 

### **Outputs**

| Name | Description |
|------|-------------|
| vm_system_identity | Virtual Machine System Managed Identity | 
| vm_id | Virtual Machine Resource ID | 
| vm_name | Virtual Machine Name |
| vm_xadm_kv_name | The name which the local admin password for the 'xadm' account is stored under in Key Vault |
| network_interface_ids | IDs of the VM NICs provisoned | 
| network_interface_private_ip | Private IP addresses of the VM NICs |
| public_ip_id | ID of the public IP address provisoned |
| public_ip_address | The IP address allocated for the resource |
| public_ip_dns_name | FQDN to connect to the first VM provisioned |

### **Usage**

```hcl
module "ca1" {
  source = "../../../../modules/coalfire-az-windows-vm"

  vm_name                       = length("${local.vm_name_prefix}ca") <= 15 ? "${local.vm_name_prefix}ca" : "${var.app_abbreviation}${var.environment}${var.location_abbreviation}ca"
  vm_admin_username             = var.vm_admin_username
  location                      = var.location
  resource_group_name           = data.terraform_remote_state.setup.outputs.management_rg_name
  size                          = "Standard_B2ms"
  source_image_id               = data.terraform_remote_state.setup.outputs.windows_ca_id
  availability_set_id           = module.ad_availability_set.availability_set_id
  enable_public_ip              = false
  subnet_id                     = data.terraform_remote_state.usgv_mgmt_vnet.outputs.usgv_mgmt_vnet_subnet_ids["${local.resource_prefix}-iam-sn-1"]
  private_ip_address_allocation = "Static"
  private_ip                    = cidrhost(data.terraform_remote_state.usgv_mgmt_vnet.outputs.networks[1]["cidr_block"], 6)
  dj_kv_id                      = data.terraform_remote_state.usgv_key_vaults.outputs.usgv_dj_kv_id
  vm_diag_sa                    = data.terraform_remote_state.setup.outputs.vmdiag_endpoint
  regional_tags                 = var.regional_tags
  global_tags                   = var.global_tags
  storage_account_vmdiag_name   = data.terraform_remote_state.setup.outputs.storage_account_vmdiag_name
  vm_tags = {
    OS         = "Windows_2019"
    Function   = "CA"
    Plane      = "Management"
    Stopinator = "False"
  }
}
```
