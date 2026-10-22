resource "random_string" "suffix" {
  length = 6
  lower = true
  upper = false
  numeric = true
  special = false
}
locals { suffix = random_string.suffix.result }
resource "azurerm_resource_group" "app" {
  name = "rg-${var.prefix}"
  location = var.location
  tags = var.tags
}
resource "azurerm_container_registry" "acr" {
  name = "${var.prefix}${local.suffix}"
  resource_group_name = azurerm_resource_group.app.name
  location = azurerm_resource_group.app.location
  sku = "Basic"
  admin_enabled = false
  tags = var.tags
}
resource "azurerm_log_analytics_workspace" "logs" {
  name = "law-${var.prefix}"
  resource_group_name = azurerm_resource_group.app.name
  location = azurerm_resource_group.app.location
  sku = "PerGB2018"
  retention_in_days = 30
  tags = var.tags
}
resource "azurerm_container_app_environment" "env" {
  name = "cae-${var.prefix}"
  location = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  tags = var.tags
}
resource "azurerm_application_insights" "ai" {
  name = "appi-${var.prefix}"
  location = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  application_type = "web"
  workspace_id = azurerm_log_analytics_workspace.logs.id
  tags = var.tags
}
