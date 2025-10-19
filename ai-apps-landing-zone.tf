# AI Apps Landing Zone
# Following Well-Architected Framework: Performance Efficiency, Security, and Reliability

# AI Apps Resource Group
resource "azurerm_resource_group" "ai_apps" {
  name     = local.resource_names.ai_apps_rg
  location = var.location
  tags     = local.common_tags
}

# AI Apps Virtual Network
resource "azurerm_virtual_network" "ai_apps" {
  name                = local.resource_names.ai_apps_vnet
  location            = azurerm_resource_group.ai_apps.location
  resource_group_name = azurerm_resource_group.ai_apps.name
  address_space       = var.ai_apps_vnet_address_space

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

# AI Apps Subnets
resource "azurerm_subnet" "ai_apps_appgw" {
  name                 = local.ai_apps_subnets.app_gateway.name
  resource_group_name  = azurerm_resource_group.ai_apps.name
  virtual_network_name = azurerm_virtual_network.ai_apps.name
  address_prefixes     = local.ai_apps_subnets.app_gateway.address_prefixes
}

resource "azurerm_subnet" "ai_apps_workload" {
  name                 = local.ai_apps_subnets.workload.name
  resource_group_name  = azurerm_resource_group.ai_apps.name
  virtual_network_name = azurerm_virtual_network.ai_apps.name
  address_prefixes     = local.ai_apps_subnets.workload.address_prefixes

  # Service endpoints for Azure services
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.CognitiveServices"
  ]
}

resource "azurerm_subnet" "ai_apps_pe" {
  name                 = local.ai_apps_subnets.private_endpoints.name
  resource_group_name  = azurerm_resource_group.ai_apps.name
  virtual_network_name = azurerm_virtual_network.ai_apps.name
  address_prefixes     = local.ai_apps_subnets.private_endpoints.address_prefixes

  # Disable private endpoint network policies
  private_endpoint_network_policies_enabled = false
}

# VNet Peering to Hub - Connectivity to shared services
resource "azurerm_virtual_network_peering" "ai_apps_to_hub" {
  name                      = "ai-apps-to-hub"
  resource_group_name       = azurerm_resource_group.ai_apps.name
  virtual_network_name      = azurerm_virtual_network.ai_apps.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways         = false
}

resource "azurerm_virtual_network_peering" "hub_to_ai_apps" {
  name                      = "hub-to-ai-apps"
  resource_group_name       = azurerm_resource_group.connectivity.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.ai_apps.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways         = false
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "app_gateway" {
  name                = "${local.resource_names.app_gateway}-pip"
  location            = azurerm_resource_group.ai_apps.location
  resource_group_name = azurerm_resource_group.ai_apps.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Web Application Firewall Policy - Security pillar
resource "azurerm_web_application_firewall_policy" "ai_apps" {
  name                = "${local.resource_names.app_gateway}-waf-policy"
  resource_group_name = azurerm_resource_group.ai_apps.name
  location            = azurerm_resource_group.ai_apps.location

  policy_settings {
    enabled                     = true
    mode                       = "Prevention"
    request_body_check         = true
    file_upload_limit_in_mb    = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }

    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "0.1"
    }
  }

  tags = local.common_tags
}

# Self-Signed SSL Certificate for Application Gateway
resource "azurerm_key_vault_certificate" "app_gateway_ssl" {
  name         = "app-gateway-ssl"
  key_vault_id = azurerm_key_vault.main.id

  certificate_policy {
    issuer_parameters {
      name = "Self" # For production, use a trusted CA
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject = "CN=${var.organization_name}.com"
      validity_in_months = 12

      subject_alternative_names {
        dns_names = [
          "${var.organization_name}.com",
          "api.${var.organization_name}.com"
        ]
      }
    }
  }

  depends_on = [azurerm_key_vault_access_policy.current]
  tags       = local.common_tags
}

# Application Gateway - Performance Efficiency and Security pillars
resource "azurerm_application_gateway" "ai_apps" {
  name                = local.resource_names.app_gateway
  resource_group_name = azurerm_resource_group.ai_apps.name
  location            = azurerm_resource_group.ai_apps.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  # Auto-scaling for Performance Efficiency
  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }

  # Managed identity for Key Vault access
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gateway.id]
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.ai_apps_appgw.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_port {
    name = "frontend-port-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGatewayFrontendIP"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  # SSL certificate from Key Vault
  ssl_certificate {
    name                = "app-gateway-ssl-cert"
    key_vault_secret_id = azurerm_key_vault_certificate.app_gateway_ssl.secret_id
  }

  backend_address_pool {
    name = "ai-apps-backend-pool"
  }

  # HTTPS backend settings
  backend_http_settings {
    name                  = "ai-apps-https-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    probe_name            = "ai-apps-health-probe"
  }

  # HTTPS listener
  http_listener {
    name                           = "ai-apps-https-listener"
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name             = "frontend-port-443"
    protocol                       = "Https"
    ssl_certificate_name           = "app-gateway-ssl-cert"
    require_sni                    = true
  }

  # HTTP listener for redirect
  http_listener {
    name                           = "ai-apps-http-listener"
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  # HTTP to HTTPS redirect
  redirect_configuration {
    name                 = "http-to-https-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "ai-apps-https-listener"
    include_path         = true
    include_query_string = true
  }

  # HTTPS routing rule
  request_routing_rule {
    name                       = "ai-apps-https-rule"
    rule_type                  = "Basic"
    http_listener_name         = "ai-apps-https-listener"
    backend_address_pool_name  = "ai-apps-backend-pool"
    backend_http_settings_name = "ai-apps-https-settings"
    priority                   = 100
  }

  # HTTP redirect rule
  request_routing_rule {
    name                        = "ai-apps-http-redirect-rule"
    rule_type                   = "Basic"
    http_listener_name          = "ai-apps-http-listener"
    redirect_configuration_name = "http-to-https-redirect"
    priority                    = 200
  }

  # HTTPS health probe
  probe {
    name                                      = "ai-apps-health-probe"
    protocol                                  = "Https"
    path                                      = "/health"
    host                                      = "api.${var.organization_name}.com"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
  }

  # WAF Configuration - Security pillar
  firewall_policy_id = azurerm_web_application_firewall_policy.ai_apps.id

  tags = local.common_tags
}

# User-assigned identity for Application Gateway to access Key Vault
resource "azurerm_user_assigned_identity" "app_gateway" {
  name                = "${local.name_prefix}-appgw-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.ai_apps.name
  tags                = local.common_tags
}

# Grant Application Gateway identity access to Key Vault
resource "azurerm_key_vault_access_policy" "app_gateway_kv_access" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app_gateway.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  certificate_permissions = [
    "Get",
    "List"
  ]
}

# Network Security Group for Application Gateway subnet
resource "azurerm_network_security_group" "ai_apps_appgw" {
  name                = "${local.resource_names.app_gateway}-nsg"
  location            = azurerm_resource_group.ai_apps.location
  resource_group_name = azurerm_resource_group.ai_apps.name

  # Allow HTTP/HTTPS inbound
  security_rule {
    name                       = "Allow-HTTP-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefixes    = var.allowed_source_ips
    destination_address_prefix = "*"
  }

  # Allow Application Gateway management traffic
  security_rule {
    name                       = "Allow-AGW-Management"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Associate NSG with Application Gateway subnet
resource "azurerm_subnet_network_security_group_association" "ai_apps_appgw" {
  subnet_id                 = azurerm_subnet.ai_apps_appgw.id
  network_security_group_id = azurerm_network_security_group.ai_apps_appgw.id
}

# Network Security Group for Workload subnet
resource "azurerm_network_security_group" "ai_apps_workload" {
  name                = "${local.ai_apps_subnets.workload.name}-nsg"
  location            = azurerm_resource_group.ai_apps.location
  resource_group_name = azurerm_resource_group.ai_apps.name

  # Allow traffic from Application Gateway
  security_rule {
    name                         = "Allow-AppGateway-Traffic"
    priority                     = 100
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_ranges      = ["80", "443", "8080"]
    source_address_prefixes      = local.ai_apps_subnets.app_gateway.address_prefixes
    destination_address_prefix   = "*"
  }

  # Allow internal subnet communication
  security_rule {
    name                       = "Allow-Internal-Communication"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.ai_apps_vnet_address_space
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Associate NSG with Workload subnet
resource "azurerm_subnet_network_security_group_association" "ai_apps_workload" {
  subnet_id                 = azurerm_subnet.ai_apps_workload.id
  network_security_group_id = azurerm_network_security_group.ai_apps_workload.id
}