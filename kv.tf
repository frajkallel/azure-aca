resource "azurerm_key_vault" "azkv" {
  name                        = "fkazkv"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = "xxxx"
  enable_rbac_authorization   = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "azkv-pe" {
  name                = "${azurerm_key_vault.azkv.name}-pe"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.azkv.id
    name                           = "${azurerm_key_vault.azkv.name}-psc"
    subresource_names              = ["vault"]
  }
  depends_on = [azurerm_key_vault.azkv]
}

resource "azurerm_private_dns_a_record" "azkv-dns" {
  name                = "fkazkv"
  zone_name           = azurerm_private_dns_zone.private_dns_zone_kv.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.azkv-pe.private_service_connection.0.private_ip_address]
}

resource "azurerm_private_dns_zone" "private_dns_zone_kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "fkazkv-vnet-link" {
  name                  = "vnetlink4fkazkv"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone_kv.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
