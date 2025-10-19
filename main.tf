# Azure AI Landing Zone - Main Configuration
# This file serves as the entry point and overview of the infrastructure
#
# Architecture Overview:
# ┌─────────────────────────────────────────────────────────────────────────┐
# │                          Azure AI Landing Zone                         │
# │                                                                         │
# │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐ │
# │  │   AI Apps LZ    │  │  AI Hub GW LZ   │  │     AI Services LZ      │ │
# │  │                 │  │                 │  │                         │ │
# │  │ • App Gateway   │  │ • API Mgmt      │  │ • OpenAI Services       │ │
# │  │ • WAF           │  │ • Container Reg │  │ • Cognitive Services    │ │
# │  │ • Web Apps      │  │ • App Insights  │  │ • Private Endpoints     │ │
# │  └─────────────────┘  └─────────────────┘  └─────────────────────────┘ │
# │           │                     │                         │             │
# │           └─────────────────────┼─────────────────────────┘             │
# │                                 │                                       │
# │  ┌─────────────────────────────────────────────────────────────────────┐ │
# │  │                     Platform Landing Zone                          │ │
# │  │                                                                     │ │
# │  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐ │ │
# │  │ │ Hub VNet    │ │ Connectivity│ │ Monitoring  │ │ Security        │ │ │
# │  │ │ • Firewall  │ │ • Peering   │ │ • Log Analyt│ │ • Key Vault     │ │ │
# │  │ │ • Bastion   │ │ • DNS Zones │ │ • App Insght│ │ • Policies      │ │ │
# │  │ │ • Gateway   │ │ • Routing   │ │ • Alerting  │ │ • RBAC          │ │ │
# │  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────────┘ │ │
# │  └─────────────────────────────────────────────────────────────────────┘ │
# └─────────────────────────────────────────────────────────────────────────┘
#
# This infrastructure follows the Microsoft Azure Well-Architected Framework:
# 🛡️  Security:           Private endpoints, network isolation, managed identities
# 🔧 Operational Excellence: Comprehensive monitoring, IaC, standardized processes
# 🏗️  Reliability:          Geo-redundancy, health checks, disaster recovery
# 💰 Cost Optimization:    Appropriate SKUs, lifecycle policies, budget alerts
# ⚡ Performance Efficiency: Auto-scaling, premium tiers, optimized routing

# The infrastructure is organized into the following components:
# 1. Platform Landing Zone (platform-landing-zone.tf) - Shared services foundation
# 2. AI Apps Landing Zone (ai-apps-landing-zone.tf) - Public-facing AI applications
# 3. AI Hub Gateway Landing Zone (ai-hub-gateway-landing-zone.tf) - API management
# 4. AI Services Landing Zone (ai-services-landing-zone.tf) - Core AI services
# 5. Monitoring & Security (monitoring-security.tf) - Observability and compliance
# 6. Networking & DNS (networking-dns.tf) - Private connectivity and DNS resolution

# Key Features Implemented:
# ✅ Zero-trust network architecture with private endpoints
# ✅ Centralized API management with Azure API Management
# ✅ Web Application Firewall for public-facing applications
# ✅ Comprehensive monitoring and alerting
# ✅ Cost optimization with lifecycle policies and budgets
# ✅ High availability with geo-redundant storage
# ✅ Security best practices with Key Vault and managed identities
# ✅ Standardized tagging and naming conventions
# ✅ Infrastructure as Code with Terraform

# Deployment Instructions:
# 1. Copy terraform.tfvars.example to terraform.tfvars
# 2. Customize variables for your environment
# 3. Run: terraform init
# 4. Run: terraform plan
# 5. Run: terraform apply

# For detailed information, see README.md

terraform {
  # This is the main configuration block that includes all other resources
  # All resource definitions are in their respective files:
  # - versions.tf: Version constraints
  # - providers.tf: Provider configurations
  # - variables.tf: Input variables
  # - locals.tf: Local values
  # - platform-landing-zone.tf: Shared platform infrastructure
  # - ai-apps-landing-zone.tf: AI Apps landing zone
  # - ai-hub-gateway-landing-zone.tf: AI Hub Gateway landing zone
  # - ai-services-landing-zone.tf: AI Services landing zone
  # - monitoring-security.tf: Monitoring and security
  # - networking-dns.tf: Private DNS and networking
  # - outputs.tf: Output values
}