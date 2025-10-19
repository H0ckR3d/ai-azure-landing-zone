# Platform Landing Zone - Shared Infrastructure
# Following Well-Architected Framework: Reliability, Security, and Operational Excellence

# Generate random suffix for globally unique resources
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Platform Resource Group
resource "azurerm_resource_group" "platform" {
  name     = local.resource_names.platform_rg
  location = var.location
  tags     = local.common_tags
}

# Connectivity Resource Group
resource "azurerm_resource_group" "connectivity" {
  name     = local.resource_names.connectivity_rg
  location = var.location
  tags     = local.common_tags
}

# Monitoring Resource Group
resource "azurerm_resource_group" "monitoring" {
  name     = local.resource_names.monitoring_rg
  location = var.location
  tags     = local.common_tags
}

# DNS Zones Resource Group
resource "azurerm_resource_group" "dns_zones" {
  name     = local.resource_names.dns_zones_rg
  location = var.location
  tags     = local.common_tags
}

# Log Analytics Workspace - Operational Excellence pillar
resource "azurerm_log_analytics_workspace" "main" {
  name                = local.resource_names.log_analytics
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = local.common_tags
}

# Hub Virtual Network - Core networking component
resource "azurerm_virtual_network" "hub" {
  name                = local.resource_names.hub_vnet
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  address_space       = var.hub_vnet_address_space

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

# DDoS Protection Plan (conditional)
resource "azurerm_network_ddos_protection_plan" "main" {
  count               = var.enable_ddos_protection ? 1 : 0
  name                = "${local.name_prefix}-ddos-plan"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name

  tags = local.common_tags
}

# Hub Subnets
resource "azurerm_subnet" "hub_firewall" {
  name                 = local.hub_subnets.firewall.name
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = local.hub_subnets.firewall.address_prefixes
}

resource "azurerm_subnet" "hub_bastion" {
  name                 = local.hub_subnets.bastion.name
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = local.hub_subnets.bastion.address_prefixes
}

resource "azurerm_subnet" "hub_gateway" {
  name                 = local.hub_subnets.gateway.name
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = local.hub_subnets.gateway.address_prefixes
}

resource "azurerm_subnet" "hub_management" {
  name                 = local.hub_subnets.management.name
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = local.hub_subnets.management.address_prefixes
}

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "${local.resource_names.hub_firewall}-pip"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Azure Firewall - Security pillar
resource "azurerm_firewall" "hub" {
  name                = local.resource_names.hub_firewall
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = local.common_tags
}

# Firewall Policy
resource "azurerm_firewall_policy" "hub" {
  name                = "${local.resource_names.hub_firewall}-policy"
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location

  dns {
    proxy_enabled = true
  }

  threat_intelligence_mode = "Alert"

  tags = local.common_tags
}

# Associate Firewall Policy
resource "azurerm_firewall_policy_rule_collection_group" "hub" {
  name               = "DefaultRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 500

  # Application rules - restrict to specific sources and destinations
  application_rule_collection {
    name     = "AllowAzureAIServices"
    priority = 300
    action   = "Allow"

    rule {
      name = "AllowOpenAIFromSpokes"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = concat(
        var.ai_apps_vnet_address_space,
        var.ai_hub_vnet_address_space,
        var.ai_services_vnet_address_space
      )
      destination_fqdns = [
        "*.openai.azure.com",
        "*.cognitiveservices.azure.com"
      ]
    }

    rule {
      name = "AllowAzureManagementFromHub"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = var.hub_vnet_address_space
      destination_fqdns = [
        "management.azure.com",
        "login.microsoftonline.com",
        "graph.microsoft.com",
        "*.vault.azure.net"
      ]
    }
  }

  # Network rules - more restrictive than original
  network_rule_collection {
    name     = "AllowAzureServices"
    priority = 400
    action   = "Allow"

    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP"]
      source_addresses      = concat(
        var.hub_vnet_address_space,
        var.ai_apps_vnet_address_space,
        var.ai_hub_vnet_address_space,
        var.ai_services_vnet_address_space
      )
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "AllowHTTPS"
      protocols             = ["TCP"]
      source_addresses      = concat(
        var.hub_vnet_address_space,
        var.ai_apps_vnet_address_space,
        var.ai_hub_vnet_address_space,
        var.ai_services_vnet_address_space
      )
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443"]
    }
  }

  # Explicit deny rules for additional security
  network_rule_collection {
    name     = "DenyUnauthorizedTraffic"
    priority = 4000
    action   = "Deny"

    rule {
      name                  = "DenyInternetFromSpokes"
      protocols             = ["Any"]
      source_addresses      = concat(
        var.ai_apps_vnet_address_space,
        var.ai_hub_vnet_address_space,
        var.ai_services_vnet_address_space
      )
      destination_addresses = ["Internet"]
      destination_ports     = ["*"]
    }
  }
}

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "${local.resource_names.bastion}-pip"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Azure Bastion - Security pillar (secure remote access)
resource "azurerm_bastion_host" "hub" {
  name                = local.resource_names.bastion
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.hub_bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.common_tags
}

# Key Vault for secrets management - Security pillar
resource "azurerm_key_vault" "main" {
  name                       = "${local.resource_names.key_vault}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.platform.location
  resource_group_name        = azurerm_resource_group.platform.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium" # Upgraded to Premium for HSM support
  soft_delete_retention_days = 90        # Increased from 7 to 90 days
  purge_protection_enabled   = true      # Prevents permanent deletion

  # Network access restrictions - Security best practice
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"

    # Allow access from specific subnets only
    virtual_network_subnet_ids = [
      azurerm_subnet.hub_management.id,
      azurerm_subnet.ai_apps_workload.id,
      azurerm_subnet.ai_hub_workload.id,
      azurerm_subnet.ai_services_services.id
    ]
  }

  tags = local.common_tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault" {
  name                = "${azurerm_key_vault.main.name}-pe"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  subnet_id           = azurerm_subnet.hub_management.id

  private_service_connection {
    name                           = "${azurerm_key_vault.main.name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "key-vault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }

  tags = local.common_tags
}

# Current client configuration
data "azurerm_client_config" "current" {}

# Key Vault access policy for current client - Limited permissions
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  # Reduced permissions for security
  secret_permissions = [
    "Get", "List", "Set" # Removed Delete, Purge, Recover for safety
  ]

  key_permissions = [
    "Get", "List", "Create", "Update", "GetRotationPolicy" # Removed Delete, Purge for safety
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Update" # Removed Delete, Purge, Recover for safety
  ]
}