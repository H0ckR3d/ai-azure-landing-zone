# Private DNS Zones and Networking Components
# Following Well-Architected Framework: Reliability, Security, and Performance Efficiency

# Private DNS Zones for Azure Services
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.dns_zones.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.dns_zones.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone" "cognitive_services" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.dns_zones.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.dns_zones.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone" "container_registry" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.dns_zones.name

  tags = local.common_tags
}

# Link Private DNS Zones to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob_hub" {
  name                  = "blob-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_hub" {
  name                  = "openai-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_services_hub" {
  name                  = "cognitive-services-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive_services.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault_hub" {
  name                  = "key-vault-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_registry_hub" {
  name                  = "container-registry-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = local.common_tags
}

# Link Private DNS Zones to AI Apps VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob_ai_apps" {
  name                  = "blob-ai-apps-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.ai_apps.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_ai_apps" {
  name                  = "openai-ai-apps-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.ai_apps.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_services_ai_apps" {
  name                  = "cognitive-services-ai-apps-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive_services.name
  virtual_network_id    = azurerm_virtual_network.ai_apps.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault_ai_apps" {
  name                  = "key-vault-ai-apps-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.ai_apps.id
  registration_enabled  = false

  tags = local.common_tags
}

# Link Private DNS Zones to AI Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob_ai_hub" {
  name                  = "blob-ai-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.ai_hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_ai_hub" {
  name                  = "openai-ai-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.ai_hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_services_ai_hub" {
  name                  = "cognitive-services-ai-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive_services.name
  virtual_network_id    = azurerm_virtual_network.ai_hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault_ai_hub" {
  name                  = "key-vault-ai-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.ai_hub.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_registry_ai_hub" {
  name                  = "container-registry-ai-hub-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry.name
  virtual_network_id    = azurerm_virtual_network.ai_hub.id
  registration_enabled  = false

  tags = local.common_tags
}

# Link Private DNS Zones to AI Services VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob_ai_services" {
  name                  = "blob-ai-services-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.ai_services.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_ai_services" {
  name                  = "openai-ai-services-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.ai_services.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_services_ai_services" {
  name                  = "cognitive-services-ai-services-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive_services.name
  virtual_network_id    = azurerm_virtual_network.ai_services.id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault_ai_services" {
  name                  = "key-vault-ai-services-link"
  resource_group_name   = azurerm_resource_group.dns_zones.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.ai_services.id
  registration_enabled  = false

  tags = local.common_tags
}

# Route Tables for custom routing (if needed)
resource "azurerm_route_table" "hub" {
  name                = "${local.resource_names.hub_vnet}-rt"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name

  # Route all traffic through Azure Firewall
  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  tags = local.common_tags
}

# Associate route table with management subnet
resource "azurerm_subnet_route_table_association" "hub_management" {
  subnet_id      = azurerm_subnet.hub_management.id
  route_table_id = azurerm_route_table.hub.id
}

# Custom route tables for spoke networks (optional - forces traffic through firewall)
resource "azurerm_route_table" "ai_apps" {
  name                = "${local.resource_names.ai_apps_vnet}-rt"
  location            = azurerm_resource_group.ai_apps.location
  resource_group_name = azurerm_resource_group.ai_apps.name

  # Route to on-premises or other networks via hub firewall
  route {
    name                   = "hub-via-firewall"
    address_prefix         = "10.0.0.0/8"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  tags = local.common_tags
}

# Associate route table with AI Apps workload subnet
resource "azurerm_subnet_route_table_association" "ai_apps_workload" {
  subnet_id      = azurerm_subnet.ai_apps_workload.id
  route_table_id = azurerm_route_table.ai_apps.id
}

# Private Endpoint DNS Records
resource "azurerm_private_dns_a_record" "openai" {
  for_each = azurerm_private_endpoint.openai

  name                = split(".", azurerm_cognitive_account.openai[each.key].endpoint)[0]
  zone_name           = azurerm_private_dns_zone.openai.name
  resource_group_name = azurerm_resource_group.dns_zones.name
  ttl                 = 300
  records             = [each.value.private_service_connection[0].private_ip_address]

  tags = local.common_tags
}

resource "azurerm_private_dns_a_record" "cognitive_services" {
  for_each = azurerm_private_endpoint.cognitive_services

  name                = azurerm_cognitive_account.cognitive_services[each.key].name
  zone_name           = azurerm_private_dns_zone.cognitive_services.name
  resource_group_name = azurerm_resource_group.dns_zones.name
  ttl                 = 300
  records             = [each.value.private_service_connection[0].private_ip_address]

  tags = local.common_tags
}

# Network Security Rules for inter-zone communication
# Allow communication between AI Hub and AI Services
resource "azurerm_network_security_rule" "ai_hub_to_ai_services" {
  name                        = "Allow-AI-Hub-to-AI-Services"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = var.ai_hub_vnet_address_space
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.ai_services.name
  network_security_group_name = azurerm_network_security_group.ai_services.name
}

# Allow communication from AI Apps to AI Services
resource "azurerm_network_security_rule" "ai_apps_to_ai_services" {
  name                        = "Allow-AI-Apps-to-AI-Services"
  priority                    = 140
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = var.ai_apps_vnet_address_space
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.ai_services.name
  network_security_group_name = azurerm_network_security_group.ai_services.name
}