data "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.la_name
  resource_group_name = var.la_resource_group_name
}
