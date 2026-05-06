output "hub_vnet_id" {
  description = "Resource ID of the hub Virtual Network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub Virtual Network"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_private_ip" {
  description = "Private IP of the Azure Firewall (use as next-hop in route tables)"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_policy_id" {
  description = "Resource ID of the Firewall Policy (for child policy association)"
  value       = azurerm_firewall_policy.hub.id
}

output "spoke_vnet_ids" {
  description = "Map of spoke VNet resource IDs keyed by workload name"
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}

output "bastion_host_id" {
  description = "Resource ID of the Azure Bastion host"
  value       = azurerm_bastion_host.hub.id
}
