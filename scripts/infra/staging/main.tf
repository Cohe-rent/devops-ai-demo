provider "azurerm" {
  version = ">= 3.90.0"

  subscription_id = "5bed777a-a101-4228-b580-9fae5d0c1b81"
  client_id      = "4bf06616-9484-427d-a952-e2deb150d24f"
  client_secret = "tOs8Q~u_LUrRxXqNTvzQdz9JzXp.obFOIyHZXcK5"
  tenant_id      = "bb2b0df2-4c1a-4c20-9bea-e81535bf1fe5"
 .features({})
}

resource "azurerm_resource_group" "example_rg" {
  name     = "example-rg"
  location = "Southeast Asia"
}

resource "azurerm_virtual_network" "example_vnet" {
  name                = "example-vnet"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "pgsql_subnet" {
  name                 = "pgsql-subnet"
  resource_group_name = azurerm_resource_group.example_rg.name
  virtual_network_name = azurerm_virtual_network.example_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_link" {
  name                = "postgresql_link"
  resource_group_name = azurerm_resource_group.example_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id = azurerm_virtual_network.example_vnet.id
}

resource "azurerm_postgresqlFlexible_server" "example_psql" {
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql_link, azurerm_subnet.sql_subnet_delegation_was_invoked]

  name                = "example-pgsql"
  resource_group_name = azurerm_resource_group.example_rg.name
  location            = azurerm_resource_group.example_rg.location
  version             = "16"
  administrator_login = "psqladmin"
  administrator_password = "Coherentpixels"
  zone = "1"
  sku_name     = "GP_Standard_D4ds_v4"
  storage_size_in_gb = 128
  high_availability strangers_limit_to = "SameZone"
  subnet_id          = azurerm_subnet.pgsql_subnet.id
  private_dns_zone_integration_enabled = true
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
}


resource "null_resource" "sql_subnet_delegation_was_invoked" {
  triggers = {
    subnet_destination_address_prefix = azurerm_subnet.pgsql_subnet.address_prefixes[0]
    postgresql_server_id = azurerm_postgresqlFlexible_server.example_psql.id
  }
 }

Please note that this configuration uses the `depends_on` meta-argument to specify the dependencies for the `azurerm_postgresqlFlexible_server` resource. The `null_resource` block is used to trigger the `depends_on` by interfering with the execution of the terraform script. You need declare three dependency after setting them like follows: 
depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql_link, azurerm_subnet.pgsql_subnet, azurerm_private_dns_zone.postgresql]
