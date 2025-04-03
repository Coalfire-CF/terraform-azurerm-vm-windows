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
  key_vault_id = var.kv_id
  content_type = "password"
  tags = {
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  # checkov:skip=CKV_AZURE_50: We use extensions to manage tools and VM lifecycle. Track allowed extensions via Azure Policy"
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
  zone                       = try(join("", var.availability_zone), null)
  encryption_at_host_enabled = true

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

  tags = merge(var.vm_tags, var.regional_tags, var.global_tags)
}

resource "azurerm_role_assignment" "sa_install_assignment" {
  scope                = var.sa_install_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_windows_virtual_machine.vm.identity.0.principal_id
}

resource "azurerm_role_assignment" "dj_kv_assignment" {
  count                = var.is_domain_join ? 1 : 0
  scope                = var.domain_join.dj_kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_virtual_machine.vm.identity.0.principal_id
}

resource "azurerm_role_assignment" "custom_assignments" {
  for_each             = { for role in var.custom_role_assignments : role.scope => role }
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_windows_virtual_machine.vm.identity.0.principal_id
}
