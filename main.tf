provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "fastapi-rg"
  location = "East US"
}

resource "azurerm_app_service_plan" "plan" {
  name                = "fastapi-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_key_vault" "kv" {
  name                = "fastapikv12345"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_secret" "mysecret" {
  name         = "MySecret"
  value        = "super-secret-value"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_app_service" "app" {
  name                = "fastapi-app-service"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  app_settings = {
    "WEBSITES_PORT" = "8000"
    "MY_SECRET"     = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.mysecret.id})"
  }
}
