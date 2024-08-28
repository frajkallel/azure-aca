# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "fk-iac-vnet"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "pg-subnet" {
  name                 = "fk-pg-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.0.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
  lifecycle {
    ignore_changes = [ delegation[0].service_delegation["actions"] ]
  }
}

resource "azurerm_subnet" "aca-subnet" {
  name                 = "fk-aca-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
  service_endpoints = [ "Microsoft.Storage" ]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.App/environments"
    }
  }
  lifecycle {
    ignore_changes = [ delegation[0].service_delegation["actions"] ]
  }
  
}

resource "azurerm_subnet" "subnet" {
  name                 = "fk-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.2.0/24"]
  service_endpoints = [ "Microsoft.Storage" ]

}

resource "azurerm_subnet" "appgw" {
  name                 = "fk-appgw-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.3.0/24"]
  service_endpoints = [ "Microsoft.Storage" ]

}

resource "azurerm_subnet" "aca-module-subnet" {
  name                 = "fk-aca-module-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.4.0/27"]
  service_endpoints = [ "Microsoft.Storage" ]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.App/environments"
    }
  }
  lifecycle {
    ignore_changes = [ delegation[0].service_delegation["actions"] ]
  }
  
}
