terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.90.0"
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
  name     = "ai-rg"
  location = "Southeast Asia"
}

resource "azurerm_virtual_network" "example" {
  name                = "ai-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "pgsql-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefix     = "10.0.1.0/24"
  depends_on       = [azurerm_resource_group.example]
  address_prefix_assignable = "true"
  enforce_private_link_endpoint_network_policy = "true"
  delegation {
    name           = "delegation"
    service_delegations {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example"
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
  resource_group_name = azurerm_resource_group.example.name
}
