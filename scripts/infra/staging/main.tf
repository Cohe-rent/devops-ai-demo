terraform {
  required_providers {
    azurerm = {
      version = "~> 3.90.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "5bed777a-a101-4228-b580-9fae5d0c1b81"
  client_id       = "4bf06616-9484-427d-a952-e2deb150d24f"
  client_secret   = "tOs8Q~u_LUrRxXqNTvzQdz9JzXp.obFOIyHZXcK5"
  tenant_id       = "bb2b0df2-4c1a-4c20-9bea-e81535bf1fe5"
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "Southeast Asia"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "pgsql" {
  name                = "pgsql-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name            = "pgsql-delegation"
    service_delegation = "Microsoft.DBforPostgreSQL/flexibleServers"
  }
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_virtual_network_link" "example" {
  name                            = "example-vnet-link"
  resource_group_name             = azurerm_resource_group.example.name
  virtual_network_name            = azurerm_virtual_network.example.name
  private_dns_zone_group_name     = azurerm_private_dns_zone.example.name
  depends_on = [azurerm_private_dns_zone.example]
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                            = "example-pgsql"
  resource_group_name             = azurerm_resource_group.example.name
  location                       = "Southeast Asia"
  zone                           = 1
  sku                           = "GP_Standard_D4ds_v4"
  storage_size_in_gb            = 128
  high_availability_mode        = "SameZone"
  administrator_login           = "psqladmin"
  administrator_password        = "Coherentpixels"
  depends_on = [azurerm_subnet.pgsql, azurerm_private_dns_zone.example]
  subnet_id = azurerm_subnet.pgsql.id
  private_dns_zone_id = azurerm_private_dns_zone.example.id
}
