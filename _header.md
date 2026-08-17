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

