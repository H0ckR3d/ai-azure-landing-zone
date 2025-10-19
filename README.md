# Azure AI Landing Zone - Terraform Infrastructure

This repository contains a comprehensive Terraform implementation of an Azure AI Landing Zone architecture following the Microsoft Azure Well-Architected Framework principles and best practices.

## 🏗️ Architecture Overview

The solution implements three distinct AI service deployment patterns with a shared platform foundation:

### 1. **Platform Landing Zone** (Shared Infrastructure)
- **Hub Virtual Network** with Azure Firewall and Azure Bastion
- **Connectivity Subscription** with private DNS zones
- **Monitoring and Security** services (Log Analytics, Key Vault)
- **Network Security** with centralized firewall and routing

### 2. **AI Apps Landing Zone**
- **Application Gateway** with Web Application Firewall (WAF)
- **Dedicated Virtual Network** for application workloads
- **Network Security Groups** with least privilege access
- **Public-facing web applications** with security controls

### 3. **AI Hub Gateway Landing Zone**
- **API Management Service** for centralized API management
- **Container Registry** for storing container images
- **Application Insights** for monitoring and analytics
- **Storage Account** for artifacts and logs

### 4. **AI Services Landing Zone**
- **Azure OpenAI Services** with private endpoints
- **Cognitive Services** for AI/ML workloads
- **Private Endpoints** for secure access
- **Dedicated Storage** for AI data and models

## 📋 Prerequisites

### Required Tools
- **Terraform** >= 1.5
- **Azure CLI** >= 2.50
- **PowerShell** 7+ or **Bash**

### Azure Prerequisites
- Azure subscription with sufficient permissions
- Service Principal or User with:
  - `Contributor` role on target subscription
  - `User Access Administrator` for role assignments
  - `Security Admin` for Security Center configuration

### Required Providers
- `azurerm` ~> 3.80
- `azuread` ~> 2.45
- `random` ~> 3.5

## 🚀 Quick Start

### 1. Clone and Initialize

```bash
git clone <repository-url>
cd azure-ai-landing-zone
```

### 2. Configure Authentication

#### Option A: Azure CLI
```bash
az login
az account set --subscription "your-subscription-id"
```

#### Option B: Service Principal
```bash
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

### 3. Configure Variables

Create a `terraform.tfvars` file:

```hcl
# Basic Configuration
environment       = "dev"
location         = "East US 2"
organization_name = "your-org"
project_name     = "ai-landing-zone"

# Network Configuration
hub_vnet_address_space         = ["10.0.0.0/16"]
ai_apps_vnet_address_space     = ["10.1.0.0/16"]
ai_hub_vnet_address_space      = ["10.2.0.0/16"]
ai_services_vnet_address_space = ["10.3.0.0/16"]

# Security Configuration
enable_ddos_protection = false  # Set to true for production
allowed_source_ips     = ["your.public.ip.address/32"]

# AI Services Configuration
ai_services = {
  openai = {
    kind = "OpenAI"
    sku  = "S0"
  }
  cognitive_services = {
    kind = "CognitiveServices"
    sku  = "S0"
  }
}

# Monitoring
log_retention_days = 30

# Tags
tags = {
  Environment = "dev"
  Project     = "ai-landing-zone"
  CostCenter  = "IT"
  Owner       = "Platform Team"
}
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Deploy the infrastructure
terraform apply
```

## 📁 Project Structure

```
├── versions.tf                    # Terraform and provider version constraints
├── providers.tf                   # Provider configurations
├── variables.tf                   # Input variables
├── locals.tf                      # Local values and naming conventions
├── platform-landing-zone.tf       # Shared platform infrastructure
├── ai-apps-landing-zone.tf        # AI Apps landing zone
├── ai-hub-gateway-landing-zone.tf # AI Hub Gateway landing zone
├── ai-services-landing-zone.tf    # AI Services landing zone
├── monitoring-security.tf         # Monitoring and security configurations
├── networking-dns.tf              # Private DNS zones and networking
├── outputs.tf                     # Output values
└── README.md                      # This file
```

## 🛡️ Security Features

### Network Security
- **Azure Firewall** with threat intelligence
- **Network Security Groups** with least privilege rules
- **Web Application Firewall** on Application Gateway
- **Private Endpoints** for all PaaS services
- **DDoS Protection** (configurable)

### Identity and Access
- **Managed Identities** for service authentication
- **Key Vault** for secret management
- **Azure AD** integration
- **RBAC** with least privilege

### Data Protection
- **Private Endpoints** for data services
- **Encryption at rest** and in transit
- **Network isolation** for sensitive workloads
- **Audit logging** for compliance

## 📊 Monitoring and Compliance

### Well-Architected Framework Implementation

#### ✅ Reliability
- Multi-region storage with geo-redundant replication
- Health probes and monitoring
- Redundant network paths
- Disaster recovery capabilities

#### 🔒 Security
- Zero-trust network architecture
- Private endpoints for all services
- Comprehensive logging and monitoring
- Security Center integration

#### 💰 Cost Optimization
- Appropriate service tiers
- Storage lifecycle policies
- Budget alerts
- Auto-scaling capabilities

#### 🔧 Operational Excellence
- Infrastructure as Code
- Standardized monitoring
- Automated deployments
- Comprehensive documentation

#### ⚡ Performance Efficiency
- Auto-scaling configurations
- Performance monitoring
- Optimized network routing
- Premium service tiers for critical workloads

### Monitoring Components
- **Log Analytics Workspace** for centralized logging
- **Application Insights** for application monitoring
- **Azure Monitor** alerts and action groups
- **Security Center** for security monitoring
- **Network Watcher** for network diagnostics

## 🔧 Configuration Options

### Environment-Specific Configurations

#### Development Environment
```hcl
environment = "dev"
enable_ddos_protection = false
ai_services = {
  openai = {
    kind = "OpenAI"
    sku  = "S0"
  }
}
```

#### Production Environment
```hcl
environment = "prod"
enable_ddos_protection = true
ai_services = {
  openai = {
    kind = "OpenAI"
    sku  = "S0"
  }
  cognitive_services = {
    kind = "CognitiveServices"
    sku  = "S0"
  }
}
```

### Network Customization

You can customize the network addressing by modifying the CIDR ranges:

```hcl
# Non-overlapping address spaces
hub_vnet_address_space         = ["10.0.0.0/16"]   # Platform/Hub
ai_apps_vnet_address_space     = ["10.1.0.0/16"]   # AI Applications
ai_hub_vnet_address_space      = ["10.2.0.0/16"]   # AI Hub Gateway
ai_services_vnet_address_space = ["10.3.0.0/16"]   # AI Services
```

## 🔄 Post-Deployment Tasks

### 1. Verify Deployment
```bash
# Check resource groups
az group list --query "[?contains(name, 'ai-landing-zone')]" -o table

# Check key vault access
az keyvault secret list --vault-name <key-vault-name>
```

### 2. Configure AI Services
- Set up OpenAI models and deployments
- Configure API Management policies
- Set up Application Gateway backend pools

### 3. Security Hardening
- Review firewall rules
- Configure conditional access policies
- Enable additional security features

## 🧹 Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

⚠️ **Warning**: This will permanently delete all resources. Ensure you have backups of any important data.

## 📚 Additional Resources

### Microsoft Documentation
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
- [Azure Landing Zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure AI Services](https://learn.microsoft.com/en-us/azure/ai-services/)

### Terraform Documentation
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:
1. Check the [Issues](../../issues) page
2. Review the [Discussions](../../discussions) section
3. Contact the platform team

## 🏷️ Version History

- **v1.0.0** - Initial release with complete AI Landing Zone implementation
- **v1.1.0** - Enhanced security features and monitoring
- **v1.2.0** - Added cost optimization features

---

**Built with ❤️ following Azure Well-Architected Framework principles**