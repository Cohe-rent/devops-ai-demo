provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-postgresql-demo"
  location = "East US"
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                   = "pgflexibleserverdemo"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  version                = "13"
  administrator_login    = "pgadminuser"
  administrator_password = "Coherent@2025"

  sku_name   = "Standard_B1ms"
  storage_mb = 32768

  delegated_subnet_id = null
  private_dns_zone_id = null
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all" {
  name                = "AllowAll"
  server_name         = azurerm_postgresql_flexible_server.example.name
  resource_group_name = azurerm_resource_group.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}
