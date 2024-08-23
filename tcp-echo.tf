resource "azurerm_container_app" "tcp-echo" {
  name                         = "tcp-echo"
  container_app_environment_id = azurerm_container_app_environment.fk-apps-env.id
  resource_group_name          = data.azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption" 

  template {
    container {
      name   = "tcp-echo"
      image  = "docker.io/istio/tcp-echo-server:latest"
      cpu    = 0.25
      memory = "0.5Gi" 
      volume_mounts {
        name = "nfsv"
        path = "/data"
      }     
    }
    volume {
      name         = "nfsv"
      storage_name = "nfs"
      storage_type = "AzureFile"
    }

  }
  ingress {
    allow_insecure_connections = false
    external_enabled           = false
    target_port                = 9000
    exposed_port               = 9000 
    transport                  = "tcp"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }   
}
