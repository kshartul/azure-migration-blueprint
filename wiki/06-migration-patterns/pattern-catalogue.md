# Migration Pattern Catalogue

## Pattern Decision Tree

```
Is the workload end-of-life or unused?
  └── YES → RETIRE (decommission + data archive)

Is the workload covered by a SaaS replacement?
  └── YES → RE-PURCHASE (M365, Dynamics, ServiceNow)

Does a regulatory or latency constraint prevent Azure hosting?
  └── YES → RETAIN (ExpressRoute + Azure Arc)

Is the workload containerisable and cloud-native ready?
  └── YES → REFACTOR (AKS, App Service, Functions)

Is an OS or DB upgrade needed during migration?
  └── YES → REPLATFORM (Terraform + Ansible config)

Default → REHOST (ASR lift-and-shift)
```

## Pattern Catalogue

### REHOST — Lift & Shift

- **Target:** Azure VM (IaaS)
- **Module:** `modules/migration/asr-replication/`
- **Cutover script:** `scripts/powershell/P4-01-wave-cutover.ps1`
- **Timeline:** 1–3 weeks per wave (after 30-day replication)
- **When to use:** VM with no application changes required; Windows/Linux IaaS

### REPLATFORM — Lift & Reshape

- **Target:** Azure VM with managed DB, or App Service
- **Module:** `modules/networking/hub-spoke/` + Ansible playbooks
- **Timeline:** 3–6 weeks (includes OS/DB upgrade testing)
- **When to use:** End-of-support OS; on-premises SQL to Azure SQL Managed Instance

### REFACTOR — Re-architect for Cloud

- **Target:** AKS, Azure App Service, Azure Functions, Azure SQL
- **Modules:** `modules/networking/` + Helm charts
- **Timeline:** 6–16 weeks (includes containerisation sprint)
- **When to use:** Microservices-ready app; PaaS cost optimisation required

### RETIRE — Decommission

- **Process:** Data archive → dependency validation → terraform destroy pipeline
- **Timeline:** 2–4 weeks
- **When to use:** Duplicate systems, unused servers (>90 days no login)

### RETAIN — Keep On-Premises

- **Process:** ExpressRoute/VPN configuration + Azure Arc agent deployment
- **When to use:** Data sovereignty, ultra-low latency, regulatory constraints

## SLO Tiers by Pattern

| Pattern | Tier | Availability SLO | RPO | RTO |
|---------|------|-----------------|-----|-----|
| Rehost (Tier 1) | Mission Critical | 99.95% | 5 min | 1 hr |
| Rehost (Tier 2) | Business Critical | 99.9% | 15 min | 4 hr |
| Replatform | Standard | 99.5% | 1 hr | 8 hr |
| Refactor (PaaS) | Varies | 99.9–99.95% | N/A | N/A |
