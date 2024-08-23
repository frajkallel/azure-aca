resource "azurerm_storage_account" "storage" {
  name                     = "fkstorageacc"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false
  allow_nested_items_to_be_public = false
  cross_tenant_replication_enabled = false        
}

resource "azurerm_private_endpoint" "private_endpoint" {
  name                = "storage-endpoint"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id
 
  private_service_connection {
    name                           = "storage-endpoint-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
 
  private_dns_zone_group {
    name                 = "storage-endpoint-connection"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone.id]
  }
 
  depends_on = [
    azurerm_storage_account.storage
  ]
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}
 
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "vnetlink"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_a_record" "storage_account" {
  name                = "storageaccount"
  zone_name           = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.private_endpoint.private_service_connection.0.private_ip_address]
}

# blob container
resource "azapi_resource" "storage-container" {
  type = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01"
  name = "fkbucket"
  parent_id = "${azurerm_storage_account.storage.id}/blobServices/default"
  body = jsonencode({
    properties = {
    }
  })
}

# share files
resource "azapi_resource" "fileshare" {
  type = "Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01"
  name = "fileshare"
  parent_id = "${azurerm_storage_account.storage.id}/fileServices/default"
  body = jsonencode({
    properties = {
      accessTier = "TransactionOptimized"
    }
  })
}

resource "azurerm_private_endpoint" "private_endpoint_fs" {
  name                = "fs-storage-endpoint"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id
 
  private_service_connection {
    name                           = "fs-storage-endpoint-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
 
  private_dns_zone_group {
    name                 = "fs-storage-endpoint-connection"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone_fs.id]
  }
 
  depends_on = [
    azurerm_storage_account.storage
  ]
}
resource "azurerm_private_dns_zone" "private_dns_zone_fs" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_fs" {
  name                  = "vnetlinkfs"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone_fs.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_a_record" "storage_account_fs" {
  name                = "fs"
  zone_name           = "privatelink.file.core.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.private_endpoint_fs.private_service_connection.0.private_ip_address]
}
