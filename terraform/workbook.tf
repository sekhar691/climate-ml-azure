# Workbook dashboard definition stored in Terraform, query uses direct Log Analytics logs.
resource "azurerm_application_insights_workbook" "predictions" {
  name = "d5e8013e-28b0-4dae-8de1-1739f2d91004"
  resource_group_name = azurerm_resource_group.app.name
  location = azurerm_resource_group.app.location
  display_name = "Climate ML Predictions"
  source_id = lower(azurerm_log_analytics_workspace.logs.id)
  category = "workbook"
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      { type = 1, content = { json = "# Climate ML demo monitoring\nSynthetic classification probabilities from FastAPI structured stdout logs." }, name = "intro" },
      { type = 3, name = "predictions", content = {
          version = "KqlItem/1.0"
          query = file("${path.module}/../monitoring/predictions.kql")
          size = 0
          title = "Predictions over time"
          queryType = 0
          resourceType = "microsoft.operationalinsights/workspaces"
          crossComponentResources = [azurerm_log_analytics_workspace.logs.id]
          visualization = "timechart"
        }
      }
    ]
    isLocked = false
    fallbackResourceIds = [azurerm_log_analytics_workspace.logs.id]
  })
  tags = var.tags
}
