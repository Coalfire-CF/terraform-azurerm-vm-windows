resource "azurerm_public_ip" "public_ip" {
  count = var.enable_public_ip ? 1 : 0

  name                = "${var.vm_name}-pubip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = coalesce(var.custom_dns_label, var.vm_name)
  sku                 = var.public_ip_sku
  tags                = merge(var.vm_tags, var.regional_tags)
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.vm_tags, var.regional_tags, var.global_tags)

  ip_configuration {
    name                          = "${var.vm_name}-ip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip
    public_ip_address_id          = var.public_ip_sku == null ? null : join("", azurerm_public_ip.public_ip.*.id)
  }


}
