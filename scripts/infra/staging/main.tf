terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = " ~> 3.90.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "5bed777a-a101-4228-b580-9fae5d0c1b81"
  client_id     = "4bf06616-9484-427d-a952-e2deb150d24f"
  client_secret = "tOs8Q~u_LUrRxXqNTvzQdz9JzXp.obFOIyHZXcK5"
  tenant_id     = "bb2b0df2-4c1a-4c20-9bea-e81535bf1fe5"
  features {}
}

resource "azurerm_resource_group" "example-rg" {
  name = "example-rg"
  location = "Southeast Asia"
}

resource "azurerm_virtual_network" "example-vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example-rg.location
  resource_group_name = azurerm_resource_group.example-rg.name
}

resource "azurerm_subnet" "pgsql-subnet" {
  name                 = "pgsql-subnet"
  resource_group_name = azurerm_resource_group.example-rg.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefix       = "10.0.1.0/24"
  depends_on          = [azurerm_virtual_network.example-vnet]
  service_endpoints    = ["Microsoft.DBforPostgreSQL/flexibleServers"]
}

resource "azurerm_private_dns_zone" "privatelink-postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pgsql-vnet-link" {
  name                  = "pgsql-vnet-link"
  resource_group_name = azurerm_resource_group.example-rg.name
  virtual_network_id = azurerm_virtual_network.example-vnet.id
  private_dns_zone_id = azurerm_private_dns_zone.privatelink-postgres.id
  depends_on          = [azurerm_private_dns_zone.privatelink-postgres]
}

resource "azurerm_postgresql_flexible_server" "example-pgsql" {
  name                = "example-pgsql"
  resource_group_name = azurerm_resource_group.example-rg.name
  location            = azurerm_resource_group.example-rg.location
  version             = 16
  administrator_login  = "psqladmin"
  administrator_login_password = "Coherentpixels"
  availability_zone        = 1 
  sku_name = "GP_Standard_D4ds_v4"
  storage_gb = 128
  high_availability = "SameZone"

  subnet_id = azurerm_subnet.pgsql-subnet.id
  depends_on = [azurerm_subnet.pgsql-subnet, azurerm_private_dns_zone.virtual_resource_record_set]
}

resource "azurerm_postgresql_flexible_server_private_endpoint" "example-pgsql-private-endpoint" {
  name                = "example-pgsql-private-endpoint"
  resource_group_name = azurerm_resource_group.example-rg.name
  location            = azurerm_resource_group.example-rg.location
  server_id            = azurerm_postgresql_flexible_server.example-pgsql.id
  subnet_id = azurerm_subnet.pgsql-subnet.id
  host              = "example-pgsql-privatelink.database.windows.net"
}

resource "azurerm_private_dns_zone_virtual_network_link" "pgsql-vnet-link-private" {
  name                = "pgsql-vnet-link-private"
  resource_group_name = azurerm_resource_group.example-rg.name
  virtual_network_id = azurerm_virtual_network.example-vnet.id
  private_dns_zone_id = azurerm_private_dns_zone.privatelink-postgres.id
  depends_on          = [azurerm_private_dns_zone.privatelink-postgres]
}

resource "azurerm_postgresql_flexible_server_virtual_network_rule" "example-pgsql-vnet-rule" {
  name                = "example-pgsql-vnet-rule"
  resource_group_name = azurerm_resource_group.example-rg.name
  server_id            = azurerm_postgresql_flexible_server.example-pgsql.id
  subnet_id = azurerm_subnet.pgsql-subnet.id
  ignore_missing_vnet_service_endpoint = true
}
