# Provider configurations
# Security pillar: Using managed identities and least privilege access
provider "azurerm" {
  features {
    # Security: Enable advanced security features
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    cognitive_account {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azuread" {
  # Will use default tenant
}

provider "random" {
  # No configuration needed
}