# Terraform version constraints and provider requirements
# Following Well-Architected Framework: Operational Excellence pillar
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  # Backend configuration for secure state management
  # SECURITY: Uncomment and configure before production deployment
  # Run ./backend-setup.sh first to create secure backend storage
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstate-replace-with-actual-name"  # Replace after running backend-setup.sh
  #   container_name       = "tfstate"
  #   key                  = "ai-landing-zone.terraform.tfstate"
  #
  #   # Security: Use Azure AD authentication instead of storage keys
  #   use_azuread_auth = true
  #   use_msi          = false  # Set to true for CI/CD pipelines with managed identity
  # }
}