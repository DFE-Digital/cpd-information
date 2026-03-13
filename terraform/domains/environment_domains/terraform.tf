terraform {

  required_version = "= 1.14.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.61.0"
    }
    statuscake = {
      source  = "StatusCakeDev/statuscake"
      version = "2.2.2"
    }
  }
  backend "azurerm" {
    container_name = "terraform-state"
  }
}

provider "azurerm" {
  features {}

  resource_provider_registrations = "none"
}

module "infrastructure_secrets" {
  source = "./vendor/modules/domains//aks/secrets"

  azure_resource_prefix = var.azure_resource_prefix
  service_short         = var.service_short
  config_short          = var.config_short
}

provider "statuscake" {
  api_token = module.infrastructure_secrets.map.STATUSCAKE-API-TOKEN
}
