# Private DNS zone for Azure Container Apps internal domain
resource "azurerm_private_dns_zone" "aca_internal" {
  name                = "internal.azurecontainerapps.io"
  resource_group_name = azurerm_resource_group.main.name
}

# Virtual network link for ACA and AppGW subnets
resource "azurerm_private_dns_zone_virtual_network_link" "aca_dns_link" {
  name                  = "burgerbuilder-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.aca_internal.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}
