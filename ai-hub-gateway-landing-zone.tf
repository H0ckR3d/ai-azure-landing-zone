# AI Hub Gateway Application Landing Zone
# Following Well-Architected Framework: Performance Efficiency, Security, and Cost Optimization

# AI Hub Resource Group
resource "azurerm_resource_group" "ai_hub" {
  name     = local.resource_names.ai_hub_rg
  location = var.location
  tags     = local.common_tags
}

# AI Hub Virtual Network
resource "azurerm_virtual_network" "ai_hub" {
  name                = local.resource_names.ai_hub_vnet
  location            = azurerm_resource_group.ai_hub.location
  resource_group_name = azurerm_resource_group.ai_hub.name
  address_space       = var.ai_hub_vnet_address_space

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

# AI Hub Subnets
resource "azurerm_subnet" "ai_hub_workload" {
  name                 = local.ai_hub_subnets.workload.name
  resource_group_name  = azurerm_resource_group.ai_hub.name
  virtual_network_name = azurerm_virtual_network.ai_hub.name
  address_prefixes     = local.ai_hub_subnets.workload.address_prefixes

  # Service endpoints for Azure services
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.CognitiveServices",
    "Microsoft.ContainerRegistry"
  ]

  # Delegation for container instances (if needed)
  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "ai_hub_pe" {
  name                 = local.ai_hub_subnets.private_endpoints.name
  resource_group_name  = azurerm_resource_group.ai_hub.name
  virtual_network_name = azurerm_virtual_network.ai_hub.name
  address_prefixes     = local.ai_hub_subnets.private_endpoints.address_prefixes

  # Disable private endpoint network policies
  private_endpoint_network_policies_enabled = false
}

# VNet Peering to Hub - Connectivity to shared services
resource "azurerm_virtual_network_peering" "ai_hub_to_hub" {
  name                      = "ai-hub-to-hub"
  resource_group_name       = azurerm_resource_group.ai_hub.name
  virtual_network_name      = azurerm_virtual_network.ai_hub.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways         = false
}

resource "azurerm_virtual_network_peering" "hub_to_ai_hub" {
  name                      = "hub-to-ai-hub"
  resource_group_name       = azurerm_resource_group.connectivity.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.ai_hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways         = false
}

# Network Security Group for Workload subnet
resource "azurerm_network_security_group" "ai_hub_workload" {
  name                = "${local.ai_hub_subnets.workload.name}-nsg"
  location            = azurerm_resource_group.ai_hub.location
  resource_group_name = azurerm_resource_group.ai_hub.name

  # Allow HTTPS traffic
  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.allowed_source_ips
    destination_address_prefix = "*"
  }

  # Allow internal hub communication
  security_rule {
    name                       = "Allow-Hub-Communication"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.hub_vnet_address_space
    destination_address_prefix = "*"
  }

  # Allow internal subnet communication
  security_rule {
    name                       = "Allow-Internal-Communication"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.ai_hub_vnet_address_space
    destination_address_prefix = "*"
  }

  # Allow outbound to Azure services
  security_rule {
    name                       = "Allow-Azure-Services-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  tags = local.common_tags
}

# Associate NSG with Workload subnet
resource "azurerm_subnet_network_security_group_association" "ai_hub_workload" {
  subnet_id                 = azurerm_subnet.ai_hub_workload.id
  network_security_group_id = azurerm_network_security_group.ai_hub_workload.id
}

# Container Registry for AI Hub - Store container images
resource "azurerm_container_registry" "ai_hub" {
  name                = "${replace(local.name_prefix, "-", "")}aihubacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.ai_hub.name
  location            = azurerm_resource_group.ai_hub.location
  sku                 = "Premium" # Premium for private endpoints and geo-replication
  admin_enabled       = false     # Use managed identity instead

  # Network access - Security pillar
  public_network_access_enabled = false

  # Retention policy - Cost Optimization
  retention_policy {
    days    = 30
    enabled = true
  }

  # Trust policy - Security
  trust_policy {
    enabled = true
  }

  tags = local.common_tags
}

# API Management Service for AI Hub Gateway - Central API management
resource "azurerm_api_management" "ai_hub" {
  name                = "${local.name_prefix}-ai-hub-apim"
  location            = azurerm_resource_group.ai_hub.location
  resource_group_name = azurerm_resource_group.ai_hub.name
  publisher_name      = var.organization_name
  publisher_email     = "admin@${var.organization_name}.com"

  sku_name = "Developer_1" # Change to Standard or Premium for production

  # Virtual network integration - Security pillar
  virtual_network_type = "Internal"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.ai_hub_workload.id
  }

  identity {
    type = "SystemAssigned"
  }

  # Security protocols
  protocols {
    enable_http2 = true
  }

  tags = local.common_tags
}

# Storage Account for AI Hub - Store artifacts and logs
resource "azurerm_storage_account" "ai_hub" {
  name                     = "${replace(local.name_prefix, "-", "")}aihubsa${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.ai_hub.name
  location                 = azurerm_resource_group.ai_hub.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-redundant for Reliability pillar

  # Security configurations - Security pillar
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false

  # Network rules - restrict access
  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.ai_hub_workload.id
    ]
  }

  # Blob properties for lifecycle management - Cost Optimization
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags
}

# Private Endpoint for Container Registry
resource "azurerm_private_endpoint" "acr" {
  name                = "${azurerm_container_registry.ai_hub.name}-pe"
  location            = azurerm_resource_group.ai_hub.location
  resource_group_name = azurerm_resource_group.ai_hub.name
  subnet_id           = azurerm_subnet.ai_hub_pe.id

  private_service_connection {
    name                           = "${azurerm_container_registry.ai_hub.name}-psc"
    private_connection_resource_id = azurerm_container_registry.ai_hub.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = "${azurerm_storage_account.ai_hub.name}-pe"
  location            = azurerm_resource_group.ai_hub.location
  resource_group_name = azurerm_resource_group.ai_hub.name
  subnet_id           = azurerm_subnet.ai_hub_pe.id

  private_service_connection {
    name                           = "${azurerm_storage_account.ai_hub.name}-psc"
    private_connection_resource_id = azurerm_storage_account.ai_hub.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Application Insights for monitoring - Operational Excellence pillar
resource "azurerm_application_insights" "ai_hub" {
  name                = "${local.name_prefix}-ai-hub-ai"
  location            = azurerm_resource_group.ai_hub.location
  resource_group_name = azurerm_resource_group.ai_hub.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = local.common_tags
}