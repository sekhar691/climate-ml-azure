terraform {
  backend "azurerm" {
    # Existing Azure Blob container; supply other fields via terraform init -backend-config.
    use_azuread_auth = true
  }
}
