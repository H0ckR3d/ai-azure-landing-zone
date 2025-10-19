# Input variables for the AI Landing Zone
# Following Well-Architected Framework: Cost Optimization and Operational Excellence

# Global Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "contoso"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ai-landing-zone"
}

# Networking Configuration
variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "ai_apps_vnet_address_space" {
  description = "Address space for AI Apps landing zone VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "ai_hub_vnet_address_space" {
  description = "Address space for AI Hub Gateway VNet"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "ai_services_vnet_address_space" {
  description = "Address space for AI Services VNet"
  type        = list(string)
  default     = ["10.3.0.0/16"]
}

# Security Configuration
variable "enable_ddos_protection" {
  description = "Enable DDoS protection on VNets (recommended for production)"
  type        = bool
  default     = true # Enabled by default for security
}

variable "allowed_source_ips" {
  description = "List of allowed source IP ranges for security rules"
  type        = list(string)
  default     = [] # Force explicit configuration - no default access

  validation {
    condition     = length(var.allowed_source_ips) > 0 && !contains(var.allowed_source_ips, "0.0.0.0/0")
    error_message = "allowed_source_ips must be specified and cannot include 0.0.0.0/0 for security reasons."
  }
}

# AI Services Configuration
variable "ai_services" {
  description = "Map of AI services to deploy"
  type = map(object({
    kind = string
    sku  = string
  }))
  default = {
    openai = {
      kind = "OpenAI"
      sku  = "S0"
    }
    cognitive_services = {
      kind = "CognitiveServices"
      sku  = "S0"
    }
  }
}

# Monitoring Configuration
variable "log_retention_days" {
  description = "Number of days to retain logs (minimum 30 days, 90+ recommended for production)"
  type        = number
  default     = 90 # Increased from 30 for better security monitoring

  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Log retention must be at least 30 days."
  }
}

# Tags - Cost Optimization pillar
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment   = "dev"
    Project       = "ai-landing-zone"
    CostCenter    = "IT"
    Owner         = "Platform Team"
    CreatedBy     = "Terraform"
  }
}