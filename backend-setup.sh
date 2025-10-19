#!/bin/bash
# Secure Terraform Backend Setup Script
# Run this BEFORE terraform init

set -e

# Configuration variables
RESOURCE_GROUP="tfstate-rg"
STORAGE_ACCOUNT="tfstate${RANDOM}"
CONTAINER_NAME="tfstate"
LOCATION="East US 2"

echo "🔒 Setting up secure Terraform backend..."

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

# Create storage account with security features
echo "Creating secure storage account: $STORAGE_ACCOUNT"
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_GRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --public-network-access Disabled

# Enable versioning for state file history
echo "Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --enable-versioning true

# Enable soft delete protection
echo "Enabling soft delete protection..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --enable-delete-retention true \
  --delete-retention-days 30

# Create container for Terraform state
echo "Creating state container..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login

# Output backend configuration
echo ""
echo "✅ Backend setup complete!"
echo ""
echo "Add this to your versions.tf file:"
echo ""
cat << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP"
    storage_account_name = "$STORAGE_ACCOUNT"
    container_name       = "$CONTAINER_NAME"
    key                  = "ai-landing-zone.terraform.tfstate"
    use_azuread_auth    = true  # Use Azure AD authentication
  }
}
EOF

echo ""
echo "🚨 IMPORTANT: Save the storage account name: $STORAGE_ACCOUNT"
echo "You'll need it to configure the backend in versions.tf"