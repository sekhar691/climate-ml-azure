resource "azurerm_user_assigned_identity" "app" {
  name = "id-${var.prefix}"
  location = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  tags = var.tags
}
resource "azurerm_role_assignment" "acr_pull" {
  scope = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id = azurerm_user_assigned_identity.app.principal_id
  skip_service_principal_aad_check = true
}
