data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv" {
  name = "kv-${var.prefix}-${local.suffix}"
  location = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled = true
  tags = var.tags
}
resource "azurerm_role_assignment" "kv_reader" {
  scope = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id = azurerm_user_assigned_identity.app.principal_id
  skip_service_principal_aad_check = true
}
# Do not put secret VALUES in Terraform; add demo-greeting through Azure Portal.
