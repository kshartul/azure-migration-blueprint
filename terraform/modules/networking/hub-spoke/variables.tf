variable "environment" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod"
  }
}

variable "location" {
  description = "Primary Azure region for hub resources"
  type        = string
}

variable "location_short" {
  description = "Short location code used in resource names (e.g. uks, eun)"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group for all hub networking resources"
  type        = string
}

variable "hub_address_space" {
  description = "CIDR block for the hub VNet (e.g. 10.0.0.0/16)"
  type        = string
}

variable "firewall_subnet_prefix" {
  description = "CIDR for AzureFirewallSubnet — must be /26 or larger"
  type        = string
}

variable "gateway_subnet_prefix" {
  description = "CIDR for GatewaySubnet — must be /27 or larger"
  type        = string
}

variable "bastion_subnet_prefix" {
  description = "CIDR for AzureBastionSubnet — must be /26 or larger"
  type        = string
}

variable "custom_dns_servers" {
  description = "Custom DNS server IPs applied to all VNets (Private DNS Resolver IPs)"
  type        = list(string)
  default     = []
}

variable "spokes" {
  description = "Map of spoke VNet configurations keyed by workload name"
  type = map(object({
    resource_group_name = string
    address_space       = string
    tags                = map(string)
  }))
  default = {}
}

variable "cost_centre" {
  description = "Cost centre tag value for FinOps allocation"
  type        = string
}

variable "owner" {
  description = "Owner email tag value"
  type        = string
}

variable "migration_wave" {
  description = "Migration wave tag (e.g. Wave-1, Wave-2, Wave-3)"
  type        = string
  default     = "Platform"
}
