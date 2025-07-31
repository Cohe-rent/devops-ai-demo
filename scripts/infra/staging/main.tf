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
  features        = {}
}

resource "azurerm_resource_group" "example" {
  name     = "ai-rg"
  location = "Southeast Asia"
}
