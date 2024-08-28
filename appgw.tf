resource "azurerm_public_ip" "appgw-pip" {
  name                = "fkallel-appgw-pip"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku = "Standard"
  sku_tier = "Regional"
  zones = ["2","1","3"]
}

resource "azurerm_private_dns_zone" "appgw-dns" {
  name                = "germanywestcentral.azurecontainerapps.io"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "appgw-dns-vnetlink" {
  name                  = "${azurerm_virtual_network.vnet.name}-link"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.appgw-dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

data "azurerm_container_app" "pyapi-info" {
  name = azurerm_container_app.pyapi.name
  resource_group_name = data.azurerm_resource_group.rg.name
  
}

data "azurerm_container_app" "nginx-info" {
  name = azurerm_container_app.nginx.name
  resource_group_name = data.azurerm_resource_group.rg.name
  
}

resource "azurerm_private_dns_a_record" "main" {
  name                = trimsuffix(data.azurerm_container_app.pyapi-info.ingress[0].fqdn, ".${azurerm_private_dns_zone.appgw-dns.name}")
  zone_name           = azurerm_private_dns_zone.appgw-dns.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_container_app_environment.fk-apps-env.static_ip_address]
}

resource "azurerm_private_dns_a_record" "nginx" {
  name                = trimsuffix(data.azurerm_container_app.nginx-info.ingress[0].fqdn, ".${azurerm_private_dns_zone.appgw-dns.name}")
  zone_name           = azurerm_private_dns_zone.appgw-dns.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_container_app_environment.fk-apps-env-module.static_ip_address]
}

resource "azurerm_application_gateway" "appgw" {
      enable_http2                      = true 
      fips_enabled                      = false 
      force_firewall_policy_association = false 
      location                          = data.azurerm_resource_group.rg.location 
      name                              = "fkallel-appgw" 
      resource_group_name               = data.azurerm_resource_group.rg.name 
      zones                             = [
          "1",
          "2",
          "3",
        ] 

      backend_address_pool {
          fqdns        = [
              data.azurerm_container_app.pyapi-info.ingress[0].fqdn,
            ] 
          name         = "fkallel-gw-backpool" 
        }
      backend_address_pool {
            fqdns        = [
              data.azurerm_container_app.nginx-info.ingress[0].fqdn,
            ]
            name         = "fkallel-nginx-bp"
        }

      backend_http_settings {
          cookie_based_affinity               = "Disabled" 
          name                                = "fkallel-bs" 
          pick_host_name_from_backend_address = false 
          port                                = 443 
          probe_name                          = "fkallel-hc" 
          protocol                            = "Https" 
          request_timeout                     = 20 
          trusted_root_certificate_names      = [] 
        }
      backend_http_settings {
            cookie_based_affinity               = "Disabled" 
            name                                = "fkallel-nginx-bs" 
            pick_host_name_from_backend_address = false 
            port                                = 443 
            probe_name                          = "fkallel-nginx-hc" 
            protocol                            = "Https" 
            request_timeout                     = 20 
            trusted_root_certificate_names      = [] 
        }

      frontend_ip_configuration {
          name                          = "appGwPublicFrontendIpIPv4" 
          private_ip_address_allocation = "Dynamic" 
          public_ip_address_id          = azurerm_public_ip.appgw-pip.id
      }
      frontend_ip_configuration {
        name                          = "appgw-private-ipp"
        private_ip_address            = "192.168.3.120"
        private_ip_address_allocation = "Static"
        subnet_id = azurerm_subnet.appgw.id
      }

      frontend_port {
          name = "port_80" 
          port = 80 
        }

      gateway_ip_configuration {
          name      = "appGatewayIpConfig" 
          subnet_id = azurerm_subnet.appgw.id 
        }

      http_listener {
            frontend_ip_configuration_name = "appGwPublicFrontendIpIPv4" 
            frontend_port_name             = "port_80" 
            host_name                      = data.azurerm_container_app.pyapi-info.ingress[0].fqdn
            host_names                     = [] 
            name                           = "fkallel-l1" 
            protocol                       = "Http" 
            require_sni                    = false 
      }
      http_listener {
            frontend_ip_configuration_name = "appGwPublicFrontendIpIPv4" 
            frontend_port_name             = "port_80" 
            host_name                      = data.azurerm_container_app.nginx-info.ingress[0].fqdn 
            host_names                     = [] 
            name                           = "fkallel-nginx-l1" 
            protocol                       = "Http" 
            require_sni                    = false 
        }

      http_listener {
        frontend_ip_configuration_name = "appgw-private-ipp"
        frontend_port_name             = "port_80"
        host_name                      = data.azurerm_container_app.nginx-info.ingress[0].fqdn 
        host_names                     = []
        name                           = "fkallel-nginx-priv-l1"
        protocol                       = "Http"
        require_sni                    = false
      }
    http_listener {
        frontend_ip_configuration_name = "appgw-private-ipp"
        frontend_port_name             = "port_80"
        host_name                      = data.azurerm_container_app.pyapi-info.ingress[0].fqdn
        host_names                     = []
        name                           = "fkallel-priv-l"
        protocol                       = "Http"
        require_sni                    = false
    }      

      probe {
          host                                      = data.azurerm_container_app.pyapi-info.ingress[0].fqdn 
          interval                                  = 30 
          minimum_servers                           = 0 
          name                                      = "fkallel-hc" 
          path                                      = "/query" 
          pick_host_name_from_backend_http_settings = false 
          protocol                                  = "Https" 
          timeout                                   = 30 
          unhealthy_threshold                       = 3 

          match {
              status_code = [] 
            }
        }
      probe {
            host                                      = data.azurerm_container_app.nginx-info.ingress[0].fqdn 
            interval                                  = 30 
            minimum_servers                           = 0 
            name                                      = "fkallel-nginx-hc" 
            path                                      = "/" 
            pick_host_name_from_backend_http_settings = false 
            protocol                                  = "Https" 
            timeout                                   = 30 
            unhealthy_threshold                       = 3 

            match {
                status_code = [] 
            }
        }

      request_routing_rule {
            backend_address_pool_name  = "fkallel-gw-backpool" 
            backend_http_settings_name = "fkallel-bs" 
            http_listener_name         = "fkallel-l1" 
            name                       = "fkallel-route" 
            priority                   = 1 
            rule_type                  = "Basic" 
        }
      request_routing_rule {
            backend_address_pool_name  = "fkallel-nginx-bp" 
            backend_http_settings_name = "fkallel-nginx-bs" 
            http_listener_name         = "fkallel-nginx-l1" 
            name                       = "fkallel-nginx-route" 
            priority                   = 2 
            rule_type                  = "Basic" 
      }

      request_routing_rule {
        backend_address_pool_name  = "fkallel-gw-backpool"
        backend_http_settings_name = "fkallel-bs"
        http_listener_name         = "fkallel-priv-l"
        name                       = "fkallel-pri-route"
        priority                   = 3
        rule_type                  = "Basic"
      }

      request_routing_rule {
        backend_address_pool_name  = "fkallel-nginx-bp"
        backend_http_settings_name = "fkallel-nginx-bs"
        http_listener_name         = "fkallel-nginx-priv-l1"
        name                       = "fkallel-nginx-pri-route"
        priority                   = 4
        rule_type                  = "Basic"
      }

      sku {
          capacity = 1 
          name     = "Standard_v2" 
          tier     = "Standard_v2" 
        }
    }
