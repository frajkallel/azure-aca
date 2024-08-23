resource "azurerm_log_analytics_workspace" "alaws" {
  name                = "fk-azworkspace"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "fk-apps-env" {
  name                       = "fk-apps-environment"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.alaws.id
  workload_profile {
    name = "Consumption"
    workload_profile_type = "Consumption"
  }
  
  infrastructure_subnet_id = azurerm_subnet.aca-subnet.id
}

resource "azurerm_container_app_environment_storage" "appenv-storage" {
  name                         = "nfs"
  container_app_environment_id = azurerm_container_app_environment.fk-apps-env.id
  account_name                 = azurerm_storage_account.storage.name
  share_name                   = azapi_resource.fileshare.name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  access_mode                  = "ReadWrite"
}
