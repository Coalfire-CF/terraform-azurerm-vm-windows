resource "random_password" "lap" {
  length           = 15
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#%"
}

resource "azurerm_key_vault_secret" "xadm_pass" {
  name         = "${var.vm_name}-lap"
  value        = random_password.lap.result
  key_vault_id = var.dj_kv_id
  content_type = "password"
  tags = {
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  # checkov:skip=CKV_AZURE_50: We use extensions to manage tools and VM lifecycle. Track allowed extensions via Azure Policy"
  name                       = var.vm_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  network_interface_ids      = [azurerm_network_interface.nic.id]
  size                       = var.size
  source_image_id            = var.source_image_id
  admin_username             = var.vm_admin_username
  admin_password             = random_password.lap.result
  availability_set_id        = var.availability_set_id
  zone                       = join("", var.availability_zone)
  encryption_at_host_enabled = true
  boot_diagnostics {
    storage_account_uri = var.vm_diag_sa
  }
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = var.disk_caching
    storage_account_type = var.vm_storage_account_type
    disk_size_gb         = var.disk_size
  }

  tags = merge(var.vm_tags, var.regional_tags, var.global_tags)
}
