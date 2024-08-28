resource "azurerm_log_analytics_workspace" "alaws" {
  name                = "fk-azworkspace"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "fk-apps-env" {
  name                       = "fk-apps-env"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.alaws.id
  workload_profile {
    name = "Consumption"
    workload_profile_type = "Consumption"
  }
  
  infrastructure_subnet_id = azurerm_subnet.aca-subnet.id
  internal_load_balancer_enabled = true
  lifecycle {
    ignore_changes = [ infrastructure_resource_group_name ]
  }
}

resource "azurerm_container_app_environment_storage" "appenv-storage" {
  name                         = "nfs"
  container_app_environment_id = azurerm_container_app_environment.fk-apps-env.id
  account_name                 = azurerm_storage_account.storage.name
  share_name                   = azapi_resource.fileshare.name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  access_mode                  = "ReadWrite"
  depends_on = [ azurerm_container_app_environment.fk-apps-env ]
}

# app env for new module
resource "azurerm_container_app_environment" "fk-apps-env-module" {
  name                       = "fk-apps-env-module"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.alaws.id
  workload_profile {
    name = "Consumption"
    workload_profile_type = "Consumption"
  }
  
  infrastructure_subnet_id = azurerm_subnet.aca-module-subnet.id
  internal_load_balancer_enabled = true
  lifecycle {
    ignore_changes = [ infrastructure_resource_group_name ]
  }
}

resource "azurerm_container_app_environment_storage" "appenv-storage-module" {
  name                         = "nfs-module"
  container_app_environment_id = azurerm_container_app_environment.fk-apps-env-module.id
  account_name                 = azurerm_storage_account.storage.name
  share_name                   = azapi_resource.fileshare.name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  access_mode                  = "ReadWrite"
  depends_on = [ azurerm_container_app_environment.fk-apps-env-module ]
}
