resource "azurerm_container_app" "pyapi" {
  name                         = "pyapi"
  container_app_environment_id = azurerm_container_app_environment.fk-apps-env.id
  resource_group_name          = data.azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption" 

  template {
    container {
      name   = "api"
      image  = "docker.io/frajkallel/api:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name = "db_name"
        value = "postgres"
      }
      env {
        name = "db_user"
        value = "xxxx"
      }
      env {
        name = "db_password"
        value = "xxxx"
      }
      env {
        name = "db_host"
        value = "xxxx"
      }
      env {
        name = "db_port"
        value = "5432"
      }
      env {
        name = "conn_str"
        value = "xxxx"
      }
      env {
        name = "container_name"
        value = "xxxx"
      }
      env {
        name        = "dbhost"
        secret_name = "dbhost"
      }
      env {
        name        = "dbpassword"
        secret_name = "dbpassword"
      }
      volume_mounts {
        name = "az-volume"
        path = "/secrets"
      }
      volume_mounts {
        name = "nfsv"
        path = "/data"
      }
    }
    max_replicas = 1
    min_replicas = 1
    volume {
      name = "az-volume"
      storage_type = "Secret"
    }
    volume {
      name         = "nfsv"
      storage_name = "nfs"
      storage_type = "AzureFile"
    }

  }
  ingress {
    allow_insecure_connections = true
    external_enabled           = true
    target_port                = 8080
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  identity {
    type = "SystemAssigned"
  }
  secret {
    name = "testfk"
    identity = "System"
    key_vault_secret_id = "https://xxxx.vault.azure.net/secrets/testfk"
  }  
  secret {
    name = "dbhost"
    identity = "System"
    key_vault_secret_id = "https://xxxx.vault.azure.net/secrets/dbhost"
  }
  secret {
    name = "dbpassword"
    identity = "System"
    key_vault_secret_id = "https://xxxx.vault.azure.net/secrets/dbpassword"
  }

  depends_on = [ azurerm_container_app_environment.fk-apps-env ]    
  
}

