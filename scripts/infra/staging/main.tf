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
  client_id      = "4bf06616-9484-427d-a952-e2deb150d24f"
  client_secret = "tOs8Q~u_LUrRxXqNTvzQdz9JzXp.obFOIyHZXcK5"
  tenant_id     = "bb2b0df2-4c1a-4c20-9bea-e81535bf1fe5"
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

resource "azurerm_subnet" "pgsql" {
  name                 = "pgsql-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  address_space = "10.0.1.0/24"
  route_table = null

  delegation {
    name = "postgresql resized"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example-vnet-link"
  resource_group_name = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_group_name = azurerm_virtual_network.example.id
}

resource "azurerm_windows_virtual_machine_scale_set" "example" {
  name                 = "example-pgsql"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                  = "GP_Standard_D4ds_v4"
  virtual_network_subnet_id = azurerm_subnet.pgsql.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix     = "example-pgsql"
    admin_username           = "psqladmin"
    admin_password          = "Coherentpixels"
  }

  os_profile_windows_config {
    provision_vm_agent = true
    timezone          = "GMT Standard Time"
    winRM {
      protocol                = "http"
      certificate {
        thumbprint           = ""
        certificate_store = "My"
      }
    }
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "MicrosoftSQLServer2019Ent"
    sku       = "SQL2019-STD-E"
    version   = "latest"
  }

  network_interfaceconfigs = [
    {
      name = "nbfg"
    }
  ]

  admin_username          = "psqladmin"
  admin_password          = "Coherentpixels"
  resource_type          = "FlexServers"

  storage_profile {
    os_disk {
      storage_account_type = "Standard_LRS"
      caching             = "ReadWrite"
      disk_size_gb       = 128
    }
  }

  high_availability {
    zone             = 1
    redundant_IO   = "Enabled"
  }
}
Note that the actual virtual machine scale set should be changed to PostgreSQL using the `sql_server` block.
