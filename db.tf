# DB section

resource "azurerm_private_dns_zone" "pg-db" {
  name                = "pgdb.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-link" {
  name                  = "dns-link-vnet"
  private_dns_zone_name = azurerm_private_dns_zone.pg-db.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = data.azurerm_resource_group.rg.name
  depends_on            = [azurerm_subnet.pg-subnet]
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                          = "fk-pg-srv"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.pg-subnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.pg-db.id
  public_network_access_enabled = false
  administrator_login           = "xxxx"
  administrator_password        = "xxxx"
  zone                          = "2"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns-link]

}
