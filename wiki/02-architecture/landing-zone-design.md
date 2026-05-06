# Architecture Overview

## Landing Zone Design

The Landing Zone follows the Microsoft Cloud Adoption Framework (CAF) hub-spoke topology.

### Management Group Hierarchy

```
Tenant Root Group
└── [PREFIX]-Platform
    ├── Identity
    ├── Management
    └── Connectivity
└── [PREFIX]-LandingZones
    ├── Corp          ← All migration workload subscriptions land here
    └── Online
└── [PREFIX]-Sandboxes
```

### Hub VNet Components

| Component | SKU | Purpose |
|-----------|-----|---------|
| Azure Firewall | Premium | Centralised egress inspection, IDPS, TLS |
| ExpressRoute Gateway | ErGw2AZ | On-premises hybrid connectivity |
| Azure Bastion | Standard | Secure RDP/SSH — no public IPs on VMs |
| Private DNS Resolver | Standard | Hybrid DNS forwarding inbound/outbound |
| Log Analytics Workspace | PerGB2018 | Centralised logging for all spokes |

### Network Address Plan

| Segment | CIDR (Prod) | CIDR (Dev) |
|---------|------------|-----------|
| Hub VNet | 10.100.0.0/16 | 10.0.0.0/20 |
| AzureFirewallSubnet | 10.100.0.0/26 | 10.0.0.0/26 |
| GatewaySubnet | 10.100.0.64/27 | 10.0.0.64/27 |
| AzureBastionSubnet | 10.100.0.96/26 | 10.0.0.96/26 |
| Workload Spokes | 10.100.16.0/22+ | 10.0.16.0/24+ |

## Architecture Decision Records (ADRs)

| ADR | Decision | Date |
|-----|----------|------|
| ADR-001 | Azure RM Provider as standard; Azure API Provider for preview only | Sprint 3 |
| ADR-002 | Hub-spoke over vWAN — cost and control tradeoff | Sprint 3 |
| ADR-003 | Terraform remote state in GRS Azure Storage with soft-delete | Sprint 3 |
| ADR-004 | Private DNS Resolver over custom DNS VMs — managed service | Sprint 4 |
