# Outputs for Azure AI Landing Zone
# Following Well-Architected Framework: Operational Excellence and Documentation

# Platform Landing Zone Outputs
output "platform_resource_group_name" {
  description = "Name of the platform resource group"
  value       = azurerm_resource_group.platform.name
}

output "hub_virtual_network_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_virtual_network_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "azure_firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "azure_firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion"
  value       = azurerm_public_ip.bastion.ip_address
}

output "key_vault_uri" {
  description = "URI of the main Key Vault"
  value       = azurerm_key_vault.main.vault_uri
  sensitive   = true
}

# Monitoring and Security Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key for AI Hub"
  value       = azurerm_application_insights.ai_hub.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string for AI Hub"
  value       = azurerm_application_insights.ai_hub.connection_string
  sensitive   = true
}

# AI Apps Landing Zone Outputs
output "ai_apps_resource_group_name" {
  description = "Name of the AI Apps resource group"
  value       = azurerm_resource_group.ai_apps.name
}

output "ai_apps_virtual_network_id" {
  description = "ID of the AI Apps virtual network"
  value       = azurerm_virtual_network.ai_apps.id
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "application_gateway_fqdn" {
  description = "FQDN of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.fqdn
}

# AI Hub Gateway Landing Zone Outputs
output "ai_hub_resource_group_name" {
  description = "Name of the AI Hub resource group"
  value       = azurerm_resource_group.ai_hub.name
}

output "ai_hub_virtual_network_id" {
  description = "ID of the AI Hub virtual network"
  value       = azurerm_virtual_network.ai_hub.id
}

output "container_registry_login_server" {
  description = "Login server of the Container Registry"
  value       = azurerm_container_registry.ai_hub.login_server
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management service"
  value       = azurerm_api_management.ai_hub.gateway_url
}

output "ai_hub_storage_account_name" {
  description = "Name of the AI Hub storage account"
  value       = azurerm_storage_account.ai_hub.name
}

# AI Services Landing Zone Outputs
output "ai_services_resource_group_name" {
  description = "Name of the AI Services resource group"
  value       = azurerm_resource_group.ai_services.name
}

output "ai_services_virtual_network_id" {
  description = "ID of the AI Services virtual network"
  value       = azurerm_virtual_network.ai_services.id
}

output "openai_endpoints" {
  description = "Endpoints for OpenAI services"
  value = {
    for k, v in azurerm_cognitive_account.openai : k => {
      endpoint = v.endpoint
      name     = v.name
      id       = v.id
    }
  }
  sensitive = true
}

output "cognitive_services_endpoints" {
  description = "Endpoints for Cognitive Services"
  value = {
    for k, v in azurerm_cognitive_account.cognitive_services : k => {
      endpoint = v.endpoint
      name     = v.name
      id       = v.id
    }
  }
  sensitive = true
}

output "ai_services_storage_account_name" {
  description = "Name of the AI Services storage account"
  value       = azurerm_storage_account.ai_services.name
}

# Network and DNS Outputs
output "private_dns_zones" {
  description = "Private DNS zones created"
  value = {
    blob              = azurerm_private_dns_zone.blob.name
    openai            = azurerm_private_dns_zone.openai.name
    cognitive_services = azurerm_private_dns_zone.cognitive_services.name
    key_vault         = azurerm_private_dns_zone.key_vault.name
    container_registry = azurerm_private_dns_zone.container_registry.name
  }
}

output "virtual_network_peerings" {
  description = "Virtual network peering connections"
  value = {
    ai_apps_to_hub = azurerm_virtual_network_peering.ai_apps_to_hub.id
    ai_hub_to_hub  = azurerm_virtual_network_peering.ai_hub_to_hub.id
    ai_services_to_hub = azurerm_virtual_network_peering.ai_services_to_hub.id
  }
}

# Resource Summary
output "resource_summary" {
  description = "Summary of created resources per landing zone"
  value = {
    platform_landing_zone = {
      resource_group = azurerm_resource_group.platform.name
      hub_vnet       = azurerm_virtual_network.hub.name
      firewall       = azurerm_firewall.hub.name
      bastion        = azurerm_bastion_host.hub.name
      key_vault      = azurerm_key_vault.main.name
    }
    ai_apps_landing_zone = {
      resource_group      = azurerm_resource_group.ai_apps.name
      vnet                = azurerm_virtual_network.ai_apps.name
      application_gateway = azurerm_application_gateway.ai_apps.name
      waf_policy          = azurerm_web_application_firewall_policy.ai_apps.name
    }
    ai_hub_landing_zone = {
      resource_group       = azurerm_resource_group.ai_hub.name
      vnet                 = azurerm_virtual_network.ai_hub.name
      container_registry   = azurerm_container_registry.ai_hub.name
      api_management       = azurerm_api_management.ai_hub.name
      storage_account      = azurerm_storage_account.ai_hub.name
      application_insights = azurerm_application_insights.ai_hub.name
    }
    ai_services_landing_zone = {
      resource_group     = azurerm_resource_group.ai_services.name
      vnet               = azurerm_virtual_network.ai_services.name
      openai_services    = [for k, v in azurerm_cognitive_account.openai : v.name]
      cognitive_services = [for k, v in azurerm_cognitive_account.cognitive_services : v.name]
      storage_account    = azurerm_storage_account.ai_services.name
    }
    monitoring = {
      resource_group         = azurerm_resource_group.monitoring.name
      log_analytics          = azurerm_log_analytics_workspace.main.name
      action_group           = azurerm_monitor_action_group.main.name
    }
    connectivity = {
      resource_group = azurerm_resource_group.connectivity.name
      hub_vnet       = azurerm_virtual_network.hub.name
    }
    dns = {
      resource_group      = azurerm_resource_group.dns_zones.name
      private_dns_zones   = [
        azurerm_private_dns_zone.blob.name,
        azurerm_private_dns_zone.openai.name,
        azurerm_private_dns_zone.cognitive_services.name,
        azurerm_private_dns_zone.key_vault.name,
        azurerm_private_dns_zone.container_registry.name
      ]
    }
  }
}

# Well-Architected Framework Compliance Summary
output "well_architected_compliance" {
  description = "Summary of Well-Architected Framework implementation"
  value = {
    reliability = {
      implemented = [
        "Multi-region storage with GRS replication",
        "Azure Firewall for network security",
        "DDoS protection (configurable)",
        "Private endpoints for secure connectivity",
        "Health probes and monitoring"
      ]
    }
    security = {
      implemented = [
        "Private endpoints for all PaaS services",
        "Network security groups with least privilege",
        "Azure Firewall with threat intelligence",
        "Web Application Firewall on Application Gateway",
        "Key Vault for secret management",
        "Managed identities for authentication",
        "Security Center integration",
        "Diagnostic logging and monitoring"
      ]
    }
    cost_optimization = {
      implemented = [
        "Appropriate SKUs for each service tier",
        "Storage lifecycle policies",
        "Budget alerts and monitoring",
        "Auto-scaling on Application Gateway",
        "Retention policies for logs and data"
      ]
    }
    operational_excellence = {
      implemented = [
        "Comprehensive monitoring with Log Analytics",
        "Application Insights for application monitoring",
        "Diagnostic settings on all resources",
        "Standardized tagging strategy",
        "Infrastructure as Code with Terraform",
        "Automated alerting and notifications"
      ]
    }
    performance_efficiency = {
      implemented = [
        "Auto-scaling capabilities",
        "Premium tiers for critical services",
        "Geo-redundant storage",
        "Content Delivery Network ready",
        "Performance monitoring and alerting"
      ]
    }
  }
}