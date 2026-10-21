resource "random_password" "lap" {
  length           = 15
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#%"
}

resource "time_offset" "lap_expiry" {
  offset_days = var.admin_password_expiration_days
}

# The secret shares the VM's lifecycle. prevent_destroy would block destroying the VM.
# The caller's Key Vault keeps soft delete and purge protection (R16).
# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_key_vault_secret" "xadm_pass" {
  name             = "${var.vm_name}-lap"
  value_wo         = random_password.lap.result
  value_wo_version = 1
  expiration_date  = time_offset.lap_expiry.rfc3339
  key_vault_id     = var.kv_id
  content_type     = "password"
  tags             = local.tags
}

resource "azurerm_windows_virtual_machine" "vm" {
  #checkov:skip=CKV_AZURE_50:Extensions are required to manage agents and domain join; allowed extensions are governed by Azure Policy
  name                       = var.vm_name
  computer_name              = var.vm_hostname != null ? var.vm_hostname : var.vm_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  network_interface_ids      = [azurerm_network_interface.nic.id]
  size                       = var.size
  source_image_id            = var.source_image_reference == null ? var.source_image_id : null
  admin_username             = var.vm_admin_username
  admin_password             = random_password.lap.result
  availability_set_id        = var.availability_set_id
  secure_boot_enabled        = var.trusted_launch
  vtpm_enabled               = var.trusted_launch
  zone                       = var.availability_zone
  encryption_at_host_enabled = var.encryption_at_host_enabled

  dynamic "source_image_reference" {
    for_each = var.source_image_reference != null ? [1] : []
    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }

  dynamic "plan" {
    for_each = var.source_image_reference != null && var.plan != null ? [1] : []
    content {
      publisher = var.plan.publisher
      name      = var.plan.name
      product   = var.plan.product
    }
  }

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

  tags = local.tags
}

resource "azurerm_role_assignment" "sa_install_assignment" {
  scope                = var.sa_install_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_windows_virtual_machine.vm.identity[0].principal_id
}

resource "azurerm_role_assignment" "dj_kv_assignment" {
  count                = var.is_domain_join ? 1 : 0
  scope                = var.domain_join.dj_kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_virtual_machine.vm.identity[0].principal_id
}

resource "azurerm_role_assignment" "custom_assignments" {
  for_each             = { for i, value in var.custom_role_assignments : i => value }
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_windows_virtual_machine.vm.identity[0].principal_id
}

# terraform-azurerm-diagnostics v3.0.0 has no VM resource_type (D1).
resource "azurerm_monitor_diagnostic_setting" "vm" {
  name                       = "${var.vm_name}-diag"
  target_resource_id         = azurerm_windows_virtual_machine.vm.id
  log_analytics_workspace_id = var.diag_log_analytics_id

  dynamic "enabled_log" {
    for_each = local.vm_log_categories
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
