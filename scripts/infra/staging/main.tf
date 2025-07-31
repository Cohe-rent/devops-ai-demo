terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
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

resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "Southeast Asia"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "pgsql_subnets" {
  name           = "pgsql-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes       = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.DBforPostgreSQL/flexibleServers"]
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_virtual_network_link" "example" {
  name                = "example-vnet-link"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_id = azurerm_virtual_network.example.id
  private_dns_zone_id = azurerm_private_dns_zone.example.id
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = "example-pgsql"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version            = "16"
  administrator_login = "psqladmin"
  administrator_password = "Coherentpixels"
  zone  = 1
  sku_name = "GP_Standard_D4ds_v4"
  storage_size_in_gb = 128
  high_availability_policy {
    mode = "SameZone"
  }
  subnet_id = azurerm_subnet.pgsql_subnets.id
  depends_on = [
    azurerm_private_dns_virtual_network_link.example,
    azurerm_private_dns_zone.example,
    azurerm_subnet.pgsql_subnets,
  ]
  private_dns_zone_id = azurerm_private_dns_zone.example.id
}
