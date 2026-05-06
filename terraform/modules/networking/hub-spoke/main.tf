terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
  required_version = ">= 1.5.0"
}

# ── Hub Virtual Network ──────────────────────────────────────────────────────
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}-${var.location_short}"
  resource_group_name = var.hub_resource_group_name
  location            = var.location
  address_space       = [var.hub_address_space]
  dns_servers         = var.custom_dns_servers
  tags                = local.common_tags
}

resource "azurerm_subnet" "azure_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.hub_resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_prefix]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.hub_resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_prefix]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.hub_resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

# ── Azure Firewall Premium ────────────────────────────────────────────────────
resource "azurerm_public_ip" "firewall" {
  name                = "pip-fw-${var.environment}-${var.location_short}"
  resource_group_name = var.hub_resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_firewall_policy" "hub" {
  name                     = "fwpol-hub-${var.environment}"
  resource_group_name      = var.hub_resource_group_name
  location                 = var.location
  sku                      = "Premium"
  threat_intelligence_mode = "Alert"
  intrusion_detection { mode = "Alert" }
  tags = local.common_tags
}

resource "azurerm_firewall" "hub" {
  name                = "fw-hub-${var.environment}-${var.location_short}"
  resource_group_name = var.hub_resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.azure_firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
  tags = local.common_tags
}

# ── Spoke VNets & Peering ─────────────────────────────────────────────────────
resource "azurerm_virtual_network" "spoke" {
  for_each            = var.spokes
  name                = "vnet-${each.key}-${var.environment}-${var.location_short}"
  resource_group_name = each.value.resource_group_name
  location            = var.location
  address_space       = [each.value.address_space]
  dns_servers         = var.custom_dns_servers
  tags                = merge(local.common_tags, each.value.tags)
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                     = var.spokes
  name                         = "peer-hub-to-${each.key}"
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke[each.key].id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                  = var.spokes
  name                      = "peer-${each.key}-to-hub"
  resource_group_name       = each.value.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  use_remote_gateways       = true
}

# ── Azure Bastion ─────────────────────────────────────────────────────────────
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.environment}-${var.location_short}"
  resource_group_name = var.hub_resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_bastion_host" "hub" {
  name                = "bastion-hub-${var.environment}-${var.location_short}"
  resource_group_name = var.hub_resource_group_name
  location            = var.location
  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
  tags = local.common_tags
}

locals {
  common_tags = {
    Environment   = var.environment
    ManagedBy     = "Terraform"
    Programme     = "AzureMigration"
    CostCentre    = var.cost_centre
    Owner         = var.owner
    MigrationWave = var.migration_wave
  }
}
