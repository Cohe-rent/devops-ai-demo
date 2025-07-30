terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features = {}
}

# Temporary default resource — will be replaced by AI
resource "azurerm_resource_group" "example" {
  name     = "ai-generated-rg"
  location = "East US"
}
