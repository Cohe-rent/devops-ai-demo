provider "azurerm" {
  version = "~> 3.90.0"

  subscription_id = "5bed777a-a101-4228-b580-9fae5d0c1b81"
  client_id      = "4bf06616-9484-427d-a952-e2deb150d24f"
  client_secret = "tOs8Q~u_LUrRxXqNTvzQdz9JzXp.obFOIyHZXcK5"
  tenant_id     = "bb2b0df2-4c1a-4c20-9bea-e81535bf1fe5"
}

resource "azurerm_resource_group" "example-rg" {
  name     = "example-rg"
  location = "Southeast Asia"
}

resource "azurerm_virtual_network" "example-vnet" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.example-rg.name
  location            = azurerm_resource_group.example-rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "pgsql-subnet" {
  name                 = "pgsql-subnet"
  resource_group_name = azurerm_resource_group.example-rg.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes       = ["10.0.1.0/24"]
  service_endpoints = [
    "Microsoft.DBforPostgreSQL/flexibleServers"
  ]
}

resource "azurerm_private_dns_zone" "postgres-zone" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example-rg.name
  zone_target_resource_id = azurerm_virtual_network.example-vnet.id
}

resource "azurermirtual_network_link" "dns-link" {
  name                            = "dns-link"
  resource_group_name = azurerm_resource_group.example-rg.name
  virtual_network_id               = azurerm_virtual_network.example-vnet.id
  private_dns_zone_name            = azurerm_private_dns_zone.postgres-zone.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-vnet-link" {
  name                  = "dns-vnet-link"
  resource_group_name = azurerm_resource_group.example-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres-zone.name
  virtual_network_link_id = azurerm_virtual_network_link.dns-link.id
}

resource "azurerm_postgresql_flexible_server" "example-pgsql" {
  name                = "example-pgsql"
  resource_group_name = azurerm_resource_group.example-rg.name
  location            = "Southeast Asia"
  administrator_login = "psqladmin"
  administrator_login_password = "Coherentpixels"
  sku_name           = "GP_Standard_D4ds_v4"
  storage_mb         = 134217728
  zone                = 1
  source_system_id            = azurerm_subnet.pgsql-subnet.id
  high_availability { 
    mode = "SameZone"
  }

  private_dns_zone_ids = [
    azurerm_private_dns_zone.postgres-zone.id
  ]
}
Please ensure to update the Terraform version as well in your Terraform provider block to latest 3.90.0
