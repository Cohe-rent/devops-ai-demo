terraform {
  required_version = ">= 1.1.0"

  # Configure Azure Provider
  provider "azurerm" {
    version = "~> 3.90.0"

    subscription_id = "5bed777a-a101-4228-b580-9fae5d0c1b81"
    client_id      = "4bf06616-9484-427d-a952-e2deb150d24f"
    client_secret  = "tOs8Q~u_LUrRxXqNTvzQdz9JzXp.obFOIyHZXcK5"
    tenant_id      = "bb2b0df2-4c1a-4c20-9bea-e81535bf1fe5"
  }
}

# Create a resource group
resource "azurerm_resource_group" "example-rg" {
  name     = "example-rg"
  location = "Southeast Asia"
}

# Create a virtual network
resource "azurerm_virtual_network" "example-vnet" {
  name                = "example-vnet"
  location            = azurerm_resource_group.example-rg.location
  resource_group_name = azurerm_resource_group.example-rg.name
  address_space       = ["10.0.0.0/16"]
}

# Create a subnet
resource "azurerm_subnet" "pgsql-subnet" {
  name                 = "pgsql-subnet"
  resource_group_name = azurerm_resource_group.example-rg.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "pgsql-subnet-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}

# Create a private DNS zone
resource "azurerm_private_dns_zone" "privatelink-postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example-rg.name
}

# Create a DNS zone virtual network link
resource "azurerm_private_dns_zone_virtual_network_link" "privatelink-postgres-link" {
  name                  = "privatelink-postgres-link"
  resource_group_name = azurerm_resource_group.example-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink-postgres.name
  virtual_network_link {
    virtual_network_name = azurerm_virtual_network.example-vnet.name
  }
}

# Create a PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "example-pgsql" {
  name                = "example-pgsql"
  resource_group_name = azurerm_resource_group.example-rg.name
  location            = azurerm_resource_group.example-rg.location
  administrator_login = "psqladmin"
  administrator_password = "Coherentpixels"
  zone               = 1
  sku_name          = "GP_Standard_D4ds_v4"
  storage_size      = 128

  high_availability {
    mode = "SameZone"
  }

  subnet_id = azurerm_subnet.pgsql-subnet.id

  private_dns_zone_id = azurerm_private_dns_zone.privatelink-postgres.id

  delegated_subnet_network_resource_placement = "azurerm_subnet.pgsql-subnet"
}
Please note that you should replace the placeholders with your actual values.
