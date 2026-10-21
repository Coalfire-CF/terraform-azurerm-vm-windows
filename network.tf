resource "azurerm_public_ip" "public_ip" {
  count = var.enable_public_ip ? 1 : 0

  name                = "${var.vm_name}-pubip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = coalesce(var.custom_dns_label, var.vm_name)
  sku                 = var.public_ip_sku
  tags                = local.tags
}

resource "azurerm_network_interface" "nic" {
  #checkov:skip=CKV_AZURE_119:A public IP is attached only when the caller sets enable_public_ip = true; the default is false (baseline R9).
  #checkov:skip=CKV2_AZURE_39:A public IP is attached only when the caller sets enable_public_ip = true; the default is false (baseline R9).
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  ip_configuration {
    name                          = "${var.vm_name}-ip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip
    public_ip_address_id          = try(azurerm_public_ip.public_ip[0].id, null)
  }
}

# terraform-azurerm-diagnostics v3.0.0 has no NIC or public IP resource_type (D1).
# A NIC has no log categories, only metrics.
resource "azurerm_monitor_diagnostic_setting" "nic" {
  name                       = "${var.vm_name}-nic-diag"
  target_resource_id         = azurerm_network_interface.nic.id
  log_analytics_workspace_id = var.diag_log_analytics_id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "public_ip" {
  count = var.enable_public_ip ? 1 : 0

  name                       = "${var.vm_name}-pubip-diag"
  target_resource_id         = azurerm_public_ip.public_ip[0].id
  log_analytics_workspace_id = var.diag_log_analytics_id

  dynamic "enabled_log" {
    for_each = local.public_ip_log_categories
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
