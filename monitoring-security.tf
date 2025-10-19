# Monitoring and Security Configurations
# Following Well-Architected Framework: Operational Excellence, Security, and Reliability

# Azure Monitor Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${local.name_prefix}-alerts-ag"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "ai-alerts"

  email_receiver {
    name          = "platform-team"
    email_address = "platform-team@${var.organization_name}.com"
  }

  # Add webhook for integration with external systems (optional)
  # webhook_receiver {
  #   name        = "teams-webhook"
  #   service_uri = "https://your-teams-webhook-url"
  # }

  tags = local.common_tags
}

# Diagnostic Settings for Hub Virtual Network
resource "azurerm_monitor_diagnostic_setting" "hub_vnet" {
  name                       = "hub-vnet-diagnostics"
  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
}

# Diagnostic Settings for Azure Firewall
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "firewall-diagnostics"
  target_resource_id         = azurerm_firewall.hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
}

# Diagnostic Settings for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  name                       = "app-gateway-diagnostics"
  target_resource_id         = azurerm_application_gateway.ai_apps.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
}

# Diagnostic Settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "key-vault-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
}

# Diagnostic Settings for AI Services
resource "azurerm_monitor_diagnostic_setting" "openai" {
  for_each = azurerm_cognitive_account.openai

  name                       = "${each.key}-diagnostics"
  target_resource_id         = each.value.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Audit"
  }

  enabled_log {
    category = "RequestResponse"
  }

  enabled_log {
    category = "Trace"
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
}

# Azure Security Center Contact
resource "azurerm_security_center_contact" "main" {
  email = "security@${var.organization_name}.com"
  phone = "+1-555-0123" # Replace with actual phone

  alert_notifications = true
  alerts_to_admins    = true
}

# Security Center Auto Provisioning
resource "azurerm_security_center_auto_provisioning" "main" {
  auto_provision = "On"
}

# Security Center Workspace
resource "azurerm_security_center_workspace" "main" {
  scope        = data.azurerm_subscription.current.id
  workspace_id = azurerm_log_analytics_workspace.main.id
}

data "azurerm_subscription" "current" {}

# Network Watcher (if not already exists)
resource "azurerm_network_watcher" "main" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "${local.name_prefix}-nw"
  location            = var.location
  resource_group_name = azurerm_resource_group.monitoring.name

  tags = local.common_tags
}

# Network Security Group Flow Logs
resource "azurerm_network_watcher_flow_log" "ai_apps_workload" {
  count = var.environment == "prod" ? 1 : 0

  network_watcher_name = azurerm_network_watcher.main[0].name
  resource_group_name  = azurerm_resource_group.monitoring.name
  name                 = "ai-apps-workload-flow-log"

  network_security_group_id = azurerm_network_security_group.ai_apps_workload.id
  storage_account_id        = azurerm_storage_account.ai_hub.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = var.log_retention_days
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.main.location
    workspace_resource_id = azurerm_log_analytics_workspace.main.id
    interval_in_minutes   = 10
  }

  tags = local.common_tags
}

# Azure Policy Assignment - Security baseline
resource "azurerm_subscription_policy_assignment" "security_baseline" {
  count = var.environment == "prod" ? 1 : 0

  name                 = "azure-security-baseline"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
  subscription_id      = data.azurerm_subscription.current.id
  display_name         = "Azure Security Baseline for AI Landing Zone"
  description          = "Apply Azure Security Baseline policies for compliance"

  parameters = jsonencode({
    # Configure policy parameters as needed
  })

  identity {
    type = "SystemAssigned"
  }

  location = var.location
}

# Budget Alert - Cost Optimization pillar
resource "azurerm_consumption_budget_subscription" "main" {
  name            = "${local.name_prefix}-budget"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 1000 # Adjust based on expected costs
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01", timestamp())
    end_date   = formatdate("YYYY-MM-01", timeadd(timestamp(), "8760h")) # 1 year from now
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        azurerm_resource_group.platform.name,
        azurerm_resource_group.ai_apps.name,
        azurerm_resource_group.ai_hub.name,
        azurerm_resource_group.ai_services.name
      ]
    }
  }

  notification {
    enabled   = true
    threshold = 80
    operator  = "GreaterThan"

    contact_emails = [
      "finance@${var.organization_name}.com",
      "platform-team@${var.organization_name}.com"
    ]
  }

  notification {
    enabled   = true
    threshold = 100
    operator  = "GreaterThan"

    contact_emails = [
      "finance@${var.organization_name}.com",
      "platform-team@${var.organization_name}.com"
    ]
  }
}

# Custom metric alerts for AI services
resource "azurerm_monitor_metric_alert" "ai_services_requests" {
  for_each = merge(azurerm_cognitive_account.openai, azurerm_cognitive_account.cognitive_services)

  name                = "${each.key}-high-requests"
  resource_group_name = azurerm_resource_group.monitoring.name
  scopes              = [each.value.id]
  description         = "Alert when AI service requests are high"

  criteria {
    metric_namespace = "Microsoft.CognitiveServices/accounts"
    metric_name      = "TotalCalls"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 1000

    dimension {
      name     = "ApiName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 2

  tags = local.common_tags
}

# Log Analytics Solutions
resource "azurerm_log_analytics_solution" "security" {
  solution_name         = "Security"
  location              = azurerm_log_analytics_workspace.main.location
  resource_group_name   = azurerm_resource_group.monitoring.name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }

  tags = local.common_tags
}

resource "azurerm_log_analytics_solution" "container_monitoring" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.main.location
  resource_group_name   = azurerm_resource_group.monitoring.name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = local.common_tags
}