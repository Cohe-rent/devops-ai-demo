# Configure the Azure Provider
provider "azurerm" {
  version = "~> 3.90.0"
  subscription_id = "5bed777a-a101-4228-b580-9fae5d0c1b81"
  client_id      = "4bf06616-9484-427d-a952-e2deb150d24f"
  client_secret = "tOs8Q~u_LUrRxXqNTvzQdz9JzXp.obFOIyHZXcK5"
  tenant_id      = "bb2b0df2-4c1a-4c20-9bea-e81535bf1fe5"
}

# Create a resource group in the Southeast Asia region
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

# Create a subnet and delegate it to Microsoft.DBforPostgreSQL/flexibleServers
resource "azurerm_subnet" "pgsql-subnet" {
  name                 = "pgsql-subnet"
  resource_group_name = azurerm_resource_group.example-rg.name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "postgres"
    service_deployment_singleton_name = "postgres-flexibleservers"
    service_resource_id = "/subscriptions/your_subscription_id/resourceGroups/your_resource_group_name/providers/Microsoft.DBforPostgreSQL/flexibleServers"
  }
}

# Create a private DNS zone
resource "azurerm_private_dns_zone" "privatelink_postgres_database_azur" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example-rg.name
}

# Create a DNS zone virtual network link
resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_link" {
  name                  = "dns-zone-link"
  resource_group_name = azurerm_resource_group.example-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_postgres_database_azur.name
  virtual_network_id = azurerm_virtual_network.example-vnet.id
}

# Create a PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "example-pgsql" {
  name                = "example-pgsql"
  location            = azurerm_resource_group.example-rg.location
  resource_group_name = azurerm_resource_group.example-rg.name
  sku_name           = "GP_Standard_D4ds_v4"
  administrator_login = "psqladmin"
  administrator_password = "Coherentpixels"
  zone               = "1"
  storage_size_gb         = 128
  high_availability_mode = "SameZone"

  subnet_id = azurerm_subnet.pgsql-subnet.id

  private_dns_zone_id = azurerm_private_dns_zone.privatelink_postgres_database_azur.id
  explicit_subnet_acl {
    allow_virtual_network_access = true
    allow_remote_desktop = true
  }
}
Note:

* Replace `your_subscription_id` and `your_resource_group_name` with the actual values for your Azure subscription and resource group.
* The `storage_size_gb` attribute is set to 128 GB, as per your requirement. However, you can adjust this value as needed.
* The `subnet_id` attribute is set to the ID of the delegated subnet (`pgsql-subnet`).
* The `private_dns_zone_id` attribute is set to the ID of the private DNS zone (`privatelink.postgres.database.azure.com`).
* The `explicit_subnet_acl` block is used to configure the subnet ACL for the PostgreSQL Flexible Server.
