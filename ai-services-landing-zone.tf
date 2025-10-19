# AI Services Landing Zone
# Following Well-Architected Framework: All pillars with focus on AI/ML workloads

# AI Services Resource Group
resource "azurerm_resource_group" "ai_services" {
  name     = local.resource_names.ai_services_rg
  location = var.location
  tags     = local.common_tags
}

# AI Services Virtual Network
resource "azurerm_virtual_network" "ai_services" {
  name                = local.resource_names.ai_services_vnet
  location            = azurerm_resource_group.ai_services.location
  resource_group_name = azurerm_resource_group.ai_services.name
  address_space       = var.ai_services_vnet_address_space

  # DDoS protection - Security pillar
  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = azurerm_network_ddos_protection_plan.main[0].id
      enable = true
    }
  }

  tags = local.common_tags
}

# AI Services Subnets
resource "azurerm_subnet" "ai_services_services" {
  name                 = local.ai_services_subnets.services.name
  resource_group_name  = azurerm_resource_group.ai_services.name
  virtual_network_name = azurerm_virtual_network.ai_services.name
  address_prefixes     = local.ai_services_subnets.services.address_prefixes

  # Service endpoints for Azure services
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.CognitiveServices"
  ]
}

resource "azurerm_subnet" "ai_services_pe" {
  name                 = local.ai_services_subnets.private_endpoints.name
  resource_group_name  = azurerm_resource_group.ai_services.name
  virtual_network_name = azurerm_virtual_network.ai_services.name
  address_prefixes     = local.ai_services_subnets.private_endpoints.address_prefixes

  # Disable private endpoint network policies
  private_endpoint_network_policies_enabled = false
}

# VNet Peering to Hub - Connectivity to shared services
resource "azurerm_virtual_network_peering" "ai_services_to_hub" {
  name                      = "ai-services-to-hub"
  resource_group_name       = azurerm_resource_group.ai_services.name
  virtual_network_name      = azurerm_virtual_network.ai_services.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways         = false
}

resource "azurerm_virtual_network_peering" "hub_to_ai_services" {
  name                      = "hub-to-ai-services"
  resource_group_name       = azurerm_resource_group.connectivity.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.ai_services.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways         = false
}

# Network Security Group for AI Services subnet
resource "azurerm_network_security_group" "ai_services" {
  name                = "${local.ai_services_subnets.services.name}-nsg"
  location            = azurerm_resource_group.ai_services.location
  resource_group_name = azurerm_resource_group.ai_services.name

  # Allow HTTPS traffic from hub and other landing zones
  security_rule {
    name                       = "Allow-HTTPS-From-Hub"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.hub_vnet_address_space
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS-From-AI-Apps"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.ai_apps_vnet_address_space
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS-From-AI-Hub"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.ai_hub_vnet_address_space
    destination_address_prefix = "*"
  }

  # Allow internal subnet communication
  security_rule {
    name                       = "Allow-Internal-Communication"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.ai_services_vnet_address_space
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Associate NSG with AI Services subnet
resource "azurerm_subnet_network_security_group_association" "ai_services" {
  subnet_id                 = azurerm_subnet.ai_services_services.id
  network_security_group_id = azurerm_network_security_group.ai_services.id
}

# Cognitive Services Account - OpenAI
resource "azurerm_cognitive_account" "openai" {
  for_each = { for k, v in var.ai_services : k => v if v.kind == "OpenAI" }

  name                = "${local.name_prefix}-${each.key}"
  location            = azurerm_resource_group.ai_services.location
  resource_group_name = azurerm_resource_group.ai_services.name
  kind                = each.value.kind
  sku_name            = each.value.sku

  # Security configurations - Security pillar
  public_network_access_enabled = false
  custom_subdomain_name          = "${local.name_prefix}-${each.key}"

  # Network access restrictions
  network_acls {
    default_action = "Deny"
    virtual_network_rules {
      subnet_id = azurerm_subnet.ai_services_services.id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Cognitive Services Account - General Cognitive Services
resource "azurerm_cognitive_account" "cognitive_services" {
  for_each = { for k, v in var.ai_services : k => v if v.kind == "CognitiveServices" }

  name                = "${local.name_prefix}-${each.key}"
  location            = azurerm_resource_group.ai_services.location
  resource_group_name = azurerm_resource_group.ai_services.name
  kind                = each.value.kind
  sku_name            = each.value.sku

  # Security configurations - Security pillar
  public_network_access_enabled = false
  custom_subdomain_name          = "${local.name_prefix}-${each.key}"

  # Network access restrictions
  network_acls {
    default_action = "Deny"
    virtual_network_rules {
      subnet_id = azurerm_subnet.ai_services_services.id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Storage Account for AI Services - Store models, data, and logs
resource "azurerm_storage_account" "ai_services" {
  name                     = "${replace(local.name_prefix, "-", "")}aiservsa${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.ai_services.name
  location                 = azurerm_resource_group.ai_services.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-redundant for Reliability pillar

  # Security configurations - Security pillar
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false

  # Enable hierarchical namespace for Data Lake Gen2 (for big data scenarios)
  is_hns_enabled = true

  # Network rules - restrict access
  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.ai_services_services.id
    ]
  }

  # Blob properties for lifecycle management - Cost Optimization
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 90 # Longer retention for AI models and training data
    }

    container_delete_retention_policy {
      days = 90
    }
  }

  tags = local.common_tags
}

# Storage Account Lifecycle Management - Cost Optimization
resource "azurerm_storage_management_policy" "ai_services" {
  storage_account_id = azurerm_storage_account.ai_services.id

  rule {
    name    = "ai-data-lifecycle"
    enabled = true

    filters {
      prefix_match = ["models/", "training-data/", "logs/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
    }
  }
}

# Private Endpoints for AI Services
resource "azurerm_private_endpoint" "openai" {
  for_each = azurerm_cognitive_account.openai

  name                = "${each.value.name}-pe"
  location            = azurerm_resource_group.ai_services.location
  resource_group_name = azurerm_resource_group.ai_services.name
  subnet_id           = azurerm_subnet.ai_services_pe.id

  private_service_connection {
    name                           = "${each.value.name}-psc"
    private_connection_resource_id = each.value.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "cognitive_services" {
  for_each = azurerm_cognitive_account.cognitive_services

  name                = "${each.value.name}-pe"
  location            = azurerm_resource_group.ai_services.location
  resource_group_name = azurerm_resource_group.ai_services.name
  subnet_id           = azurerm_subnet.ai_services_pe.id

  private_service_connection {
    name                           = "${each.value.name}-psc"
    private_connection_resource_id = each.value.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Private Endpoint for AI Services Storage Account
resource "azurerm_private_endpoint" "ai_services_storage" {
  name                = "${azurerm_storage_account.ai_services.name}-pe"
  location            = azurerm_resource_group.ai_services.location
  resource_group_name = azurerm_resource_group.ai_services.name
  subnet_id           = azurerm_subnet.ai_services_pe.id

  private_service_connection {
    name                           = "${azurerm_storage_account.ai_services.name}-psc"
    private_connection_resource_id = azurerm_storage_account.ai_services.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# SECURITY NOTE: API keys are NOT stored in Terraform state for security
# Instead, use managed identities and RBAC for authentication to AI services
# If API keys are absolutely required, they should be managed separately using:
# 1. Azure Key Vault automatic rotation
# 2. External secret management tools
# 3. Manual rotation procedures

# Create user-assigned managed identity for AI applications
resource "azurerm_user_assigned_identity" "ai_applications" {
  name                = "${local.name_prefix}-ai-app-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_services.name
  tags                = local.common_tags
}

# RBAC: Grant managed identity access to OpenAI services
resource "azurerm_role_assignment" "ai_identity_to_openai" {
  for_each             = azurerm_cognitive_account.openai
  scope                = each.value.id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_user_assigned_identity.ai_applications.principal_id
}

# RBAC: Grant managed identity access to Cognitive Services
resource "azurerm_role_assignment" "ai_identity_to_cognitive" {
  for_each             = azurerm_cognitive_account.cognitive_services
  scope                = each.value.id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_user_assigned_identity.ai_applications.principal_id
}

# RBAC: Grant managed identity access to storage account
resource "azurerm_role_assignment" "ai_identity_to_storage" {
  scope                = azurerm_storage_account.ai_services.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.ai_applications.principal_id
}