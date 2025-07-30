terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"  # or latest 3.x version
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "5bed777a-a101-4228-b580-9fae5d0c1b81"
  client_id       = "4bf06616-9484-427d-a952-e2deb150d24f"
  client_secret   = "tOs8Q~u_LUrRxXqNTvzQdz9JzXp.obFOIyHZXcK5"
  tenant_id       = "bb2b0df2-4c1a-4c20-9bea-e81535bf1fe5"
}

# RESOURCE GROUP
resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "Southeast Asia"
}

# VNET
resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# SUBNET FOR POSTGRES
resource "azurerm_subnet" "pgsql_subnet" {
  name                 = "pgsql-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "fsdelegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

# PRIVATE DNS ZONE
resource "azurerm_private_dns_zone" "pgsql_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

# DNS ZONE LINK
resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.pgsql_dns.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

# POSTGRES FLEXIBLE SERVER
resource "azurerm_postgresql_flexible_server" "example" {
  name                   = "example-pgsql"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  version                = "16"
  administrator_login    = "psqladmin"
  administrator_password = "Coherentpixels"

  sku_name               = "GP_Standard_D4ds_v4"
  storage_mb             = 131072
  zone                   = "1"
  delegated_subnet_id    = azurerm_subnet.pgsql_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.pgsql_dns.id
  high_availability {
    mode = "SameZone"
  }

  depends_on = [
    azurerm_subnet.pgsql_subnet,
    azurerm_private_dns_zone.pgsql_dns
  ]
}

