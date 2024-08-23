# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.116.0"
    }
    azapi = {
      source = "Azure/azapi"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    skip_provider_registration = "true"
    subscription_id = "xxxx"
    client_id = "xxx"
    client_secret = "xxxx"
    tenant_id = "xxxx" 
    features {
      
    }
}

provider "azapi" {
    skip_provider_registration = "true"
    subscription_id = "xxxx"
    client_id = "xxx"
    client_secret = "xxxx"
    tenant_id = "xxxx"  
}

# Create a resource group
data "azurerm_resource_group" "rg" {
  name     = "fkallel-sbx"
}


