resource "azurerm_container_app" "app" {
  count = var.enable_app ? 1 : 0
  name = "ca-${var.prefix}"
  resource_group_name = azurerm_resource_group.app.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode = "Single"

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }
  registry {
    server = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.app.id
  }
  ingress {
    external_enabled = true
    target_port = 8000
    traffic_weight {
      latest_revision = true
      percentage = 100
    }
  }
  template {
    min_replicas = 0
    max_replicas = 2
    container {
      name = "api"
      image = var.container_image
      cpu = 0.5
      memory = "1Gi"
      env {
        name = "KEY_VAULT_URL"
        value = azurerm_key_vault.kv.vault_uri
      }
      env {
        name = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.app.client_id
      }
    }
  }
  depends_on = [azurerm_role_assignment.acr_pull, azurerm_role_assignment.kv_reader]
  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
  tags = var.tags
}
