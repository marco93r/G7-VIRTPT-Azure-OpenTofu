terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.54.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli         = true
  subscription_id = "0aec017b-0615-405d-b568-c327f2a67ffd"
}