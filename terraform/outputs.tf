output "resource_group" {
  value = azurerm_resource_group.app.name
}
output "acr_name" {
  value = azurerm_container_registry.acr.name
}
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}
output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
output "managed_identity_client_id" {
  value = azurerm_user_assigned_identity.app.client_id
}
output "log_analytics_name" {
  value = azurerm_log_analytics_workspace.logs.name
}
output "container_app_url" {
  value = var.enable_app ? "https://${azurerm_container_app.app[0].latest_revision_fqdn}" : "not deployed yet"
}
