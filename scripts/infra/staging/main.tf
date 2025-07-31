terraform {
  required_version = ">= 1.1.0"

  # Configure the Azure Provider
  provider "azurerm" {
    version = "~> 3.90.0"

    # Azure credentials
    subscription_id = "5bed777a-a101-4228-b580-9fae5d0c1b81"
    client_id      = "4bf06616-9484-427d-a952-e2deb150d24f"
    client_secret = "tOs8Q~u_LUrRxXqNTvzQdz9JzXp.obFOIyHZXcK5"
    tenant_id     = "bb2b0df2-4c1a-4c20-9bea-e81535bf1fe5"
  }
}

resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "Southeast Asia"
}

resource "azurerm_virtual_network" "example_vnet" {
  name                = "example-vnet"
  address_spaces     = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "pgsql_subnet" {
  name           = "pgsql-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "pgsql-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}

resource "azurerm_private_dns_zone" "privatelink_postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_server" "dns_link" {
  name                = "dns-link"
  resource_group_name = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_postgres.name
  virtual_network_link {
    virtual_network_name = azurerm_virtual_network.example_vnet.name
  }
}

resource "azurerm_postgresql_server" "example_pgsql" {
  name                         = "example-pgsql"
  location                     = azurerm_resource_group.example.location
  resource_group_name          = azurerm_resource_group.example.name
  administrator_login          = "psqladmin"
  administrator_login_password = "Coherentpixels"
  zone                         = 1
  sku {
    name     = "GP_Standard_D4ds_v4"
    tier     = "GeneralPurpose"
    size     = "D4ds"
    family   = "v4"
  }
  storage_mb              = 128 * 1024
  high_availability_mode  = "SameZone"
  subnet_id              = azurerm_subnet.pgsql_subnet.id
  private_dns_zone_link = azurerm_private_dns_zone.privatelink_postgres.name
  explicit_placement {
    resource_group_name = azurerm_resource_group.example.name
    subscription_id    = azurerm_provider_configuration.subscription_id
  }
}
Note:

* In Azure, resource names must be globally unique. You may need to adjust the resource name in the `azurerm_postgresql_server` block to ensure uniqueness.
* The `azurerm_provider_configuration` block is not actually used in this configuration, but it is required to provide the subscription ID. You can safely ignore this block.
