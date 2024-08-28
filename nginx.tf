resource "azurerm_container_app" "nginx" {
  name                         = "nginx"
  container_app_environment_id = azurerm_container_app_environment.fk-apps-env-module.id
  resource_group_name          = data.azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption" 

  template {
    container {
      name   = "nginx"
      image  = "docker.io/nginx:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      volume_mounts {
        name = "nfsv"
        path = "/data"
      }
    }
    volume {
      name         = "nfsv"
      storage_name = "nfs-module"
      storage_type = "AzureFile"
    }    
    max_replicas = 1
    min_replicas = 1
  }
  ingress {
    allow_insecure_connections = true
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  identity {
    type = "SystemAssigned"
  }

  depends_on = [ azurerm_container_app_environment.fk-apps-env-module ]    
  
}

