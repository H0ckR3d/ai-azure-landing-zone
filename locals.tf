# Local values for consistent naming and configuration
# Following Terraform and Azure naming conventions

locals {
  # Naming convention: {org}-{env}-{location-short}-{project}-{resource-type}
  location_short = {
    "East US"          = "eus"
    "East US 2"        = "eus2"
    "West US"          = "wus"
    "West US 2"        = "wus2"
    "Central US"       = "cus"
    "North Central US" = "ncus"
    "South Central US" = "scus"
    "West Central US"  = "wcus"
    "West Europe"      = "weu"
    "North Europe"     = "neu"
  }

  location_code = lookup(local.location_short, var.location, "unk")
  name_prefix   = "${var.organization_name}-${var.environment}-${local.location_code}-${var.project_name}"

  # Resource naming
  resource_names = {
    # Platform Landing Zone Resources
    platform_rg           = "${local.name_prefix}-platform-rg"
    hub_vnet              = "${local.name_prefix}-hub-vnet"
    hub_firewall          = "${local.name_prefix}-hub-fw"
    bastion               = "${local.name_prefix}-bastion"
    log_analytics         = "${local.name_prefix}-law"

    # AI Apps Landing Zone Resources
    ai_apps_rg            = "${local.name_prefix}-ai-apps-rg"
    ai_apps_vnet          = "${local.name_prefix}-ai-apps-vnet"
    app_gateway           = "${local.name_prefix}-ai-apps-agw"

    # AI Hub Gateway Landing Zone Resources
    ai_hub_rg             = "${local.name_prefix}-ai-hub-rg"
    ai_hub_vnet           = "${local.name_prefix}-ai-hub-vnet"

    # AI Services Landing Zone Resources
    ai_services_rg        = "${local.name_prefix}-ai-services-rg"
    ai_services_vnet      = "${local.name_prefix}-ai-services-vnet"

    # Shared Resources
    connectivity_rg       = "${local.name_prefix}-connectivity-rg"
    monitoring_rg         = "${local.name_prefix}-monitoring-rg"
    dns_zones_rg          = "${local.name_prefix}-dns-rg"
    key_vault            = "${local.name_prefix}-kv"
  }

  # Common tags merged with variable tags
  common_tags = merge(var.tags, {
    Environment      = var.environment
    Location         = var.location
    Project          = var.project_name
    Organization     = var.organization_name
    DeployedDate     = timestamp()
    WellArchitected  = "true"
  })

  # Subnet configurations
  hub_subnets = {
    firewall = {
      name             = "AzureFirewallSubnet"
      address_prefixes = ["10.0.1.0/26"]
    }
    bastion = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.2.0/26"]
    }
    gateway = {
      name             = "GatewaySubnet"
      address_prefixes = ["10.0.3.0/27"]
    }
    management = {
      name             = "management-subnet"
      address_prefixes = ["10.0.4.0/24"]
    }
  }

  ai_apps_subnets = {
    app_gateway = {
      name             = "appgw-subnet"
      address_prefixes = ["10.1.1.0/24"]
    }
    workload = {
      name             = "workload-subnet"
      address_prefixes = ["10.1.2.0/24"]
    }
    private_endpoints = {
      name             = "pe-subnet"
      address_prefixes = ["10.1.3.0/24"]
    }
  }

  ai_hub_subnets = {
    workload = {
      name             = "workload-subnet"
      address_prefixes = ["10.2.1.0/24"]
    }
    private_endpoints = {
      name             = "pe-subnet"
      address_prefixes = ["10.2.2.0/24"]
    }
  }

  ai_services_subnets = {
    services = {
      name             = "services-subnet"
      address_prefixes = ["10.3.1.0/24"]
    }
    private_endpoints = {
      name             = "pe-subnet"
      address_prefixes = ["10.3.2.0/24"]
    }
  }
}