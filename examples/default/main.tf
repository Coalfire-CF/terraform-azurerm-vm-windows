provider "azurerm" {
  environment                     = "usgovernment"
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
  features {}
}

module "vm" {
  source = "../.."

  vm_name               = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  vm_admin_username     = var.vm_admin_username
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

  tags = var.tags
}
