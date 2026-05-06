# Azure Migration Blueprint

<div align="center">

![Azure Migration](https://img.shields.io/badge/Azure-Migration%20Blueprint-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Azure DevOps](https://img.shields.io/badge/Azure%20DevOps-CI%2FCD-0078D4?style=for-the-badge&logo=azuredevops&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-Scripts-5391FE?style=for-the-badge&logo=powershell&logoColor=white)

**End-to-End Engineering Framework for Large-Scale Azure Migration Programmes**

*6 Phases · 13 Sprints · 22+ Scripts & Terraform Modules · 500+ Workload Scale*

[![Live Post](https://img.shields.io/badge/🌐%20Live%20Post-GitHub%20Pages-0D2B4E?style=flat-square)](https://ShartulKumar.github.io/azure-migration-blueprint)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Shartul%20Kumar-0A66C2?style=flat-square&logo=linkedin)](https://linkedin.com/in/shartul-kumar)
[![Blueprint](https://img.shields.io/badge/📄%20Blueprint%20Doc-Download%20DOCX-1F4E79?style=flat-square)](docs/AzureMigrationEngineer_Blueprint.docx)
[![Implementation Plan](https://img.shields.io/badge/📋%20Implementation%20Plan-Download%20DOCX-007B8A?style=flat-square)](docs/AzureMigration_ImplementationPlan.docx)

</div>

---

## About This Repository

This repository is the complete technical companion to the Azure Migration Blueprint — a practitioner's framework covering every engineering discipline required to plan, automate, govern, execute, and operationalise large-scale Azure migration programmes.

It is built and maintained by **Shartul Kumar**, Senior Azure Migration Architect with 10+ years of enterprise cloud experience across Azure, AWS, and GCP, specialising in Landing Zone design, Terraform IaC, multi-cloud Kubernetes, and site reliability engineering.

> 📖 **Read the full post:** [kshartul.github.io/azure-migration-blueprint](https://kshartul.github.io/azure-migration-blueprint)
> 
> 🔗 **Connect:** [linkedin.com/in/shartul](https://www.linkedin.com/in/shartul-kumar)

---

## Documents

| Document | Description | Format | Link |
|----------|-------------|--------|------|
| **Technical Reference Blueprint** | Skills framework, migration patterns, governance standards, RACI matrices, toolchain reference, certification path | DOCX | [Download](docs/AzureMigrationEngineer_Blueprint.docx) |
| **End-to-End Implementation Plan** | Phase-by-phase delivery plan with all PowerShell, Python, Terraform, KQL and Azure DevOps YAML scripts | DOCX | [Download](docs/AzureMigration_ImplementationPlan.docx) |

---

## What's Covered

### Phase 1 — Discover & Assess *(Weeks 1–4 · Sprints 1–2)*
- Azure Migrate appliance deployment via PowerShell
- Agentless and agent-based dependency mapping at scale
- Python inventory export: complexity scoring, wave auto-assignment
- 30-day observation window → wave prioritisation matrix

### Phase 2 — Design & Landing Zone *(Weeks 5–10 · Sprints 3–5)*
- CAF-aligned Management Group hierarchy (Terraform)
- Hub-spoke networking: Azure Firewall Premium, ExpressRoute, Bastion, Private DNS
- Identity baseline: AAD groups, PIM, workload managed identities, RBAC
- Terraform remote state backend with GRS, soft-delete, versioning, and resource lock

### Phase 3 — Build & Automate *(Weeks 11–16 · Sprints 6–8)*
- Reusable 6-stage Azure DevOps CI/CD pipeline template
- Static analysis gates: `tflint`, `tfsec`, `Checkov`, `terraform validate`, `fmt --check`
- Manual approval gate — plan review before every PROD apply
- terraform-docs auto-generation on every merge
- Post-apply Python validation script (VNet, firewall, peering, policy)

### Phase 4 — Migrate & Execute *(Weeks 17–24 · Sprints 9–12)*
- ASR replication Terraform module (vault, fabrics, containers, replication policy)
- Wave cutover orchestration: pre-flight checks, quiesce, failover, DNS cutover
- Python smoke test suite: VM state, DNS, port reachability, no public IP
- Automated rollback/failback script with Log Analytics event logging

### Phase 5 — Govern & Secure *(Ongoing · Sprints 3–12)*
- Mandatory Azure Policy initiative: locations, tagging, diagnostics, security
- Defender for Cloud — all plans enabled via Terraform
- FinOps: budget alerts at 80%/100%, tag compliance weekly report
- Key Vault per workload, NSG flow logs, Sentinel SIEM

### Phase 6 — Operate & Optimise *(Post go-live · Sprint 13+)*
- SLO/SLI framework: availability, latency, error budget fast-burn KQL alerts
- Automated quarterly DR test pipeline (ASR test failover → smoke tests → cleanup)
- 12-track knowledge transfer programme
- Handover readiness criteria and witnessed client independence exercise

---

## Repository Structure

```
azure-migration-blueprint/
│
├── index.html                          # Live post (GitHub Pages homepage)
│
├── docs/                               # Reference documents
│   ├── AzureMigrationEngineer_Blueprint.docx
│   ├── AzureMigration_ImplementationPlan.docx
│   
│
├── scripts/
│   ├── powershell/                     # PowerShell automation scripts
│   │   ├── P1-01-deploy-migrate-appliance.ps1
│   │   ├── P1-03-enable-dependency-agents.ps1
│   │   ├── P2-01-setup-tf-backend.ps1
│   │   ├── P4-01-wave-cutover.ps1
│   │   ├── P4-02-rollback-failback.ps1
│   │   └── P5-01-finops-tag-report.ps1
│   │
│   ├── python/                         # Python automation scripts
│   │   └── P1-02-export-inventory.py
│   │
│   └── bash/                           # Bash setup scripts
│       └── P2-00-repo-init.sh
│
├── terraform/
│   ├── modules/
│   │   ├── networking/
│   │   │   └── hub-spoke/              # Hub-spoke VNet, Firewall, Bastion, DNS
│   │   ├── identity/
│   │   │   └── rbac-baseline/          # AAD groups, role assignments, managed identities
│   │   ├── governance/
│   │   │   ├── management-groups/      # CAF Management Group hierarchy
│   │   │   ├── policy-initiative/      # Mandatory governance policy set
│   │   │   └── finops/                 # Budget alerts, tag inheritance
│   │   ├── security/
│   │   │   ├── defender/               # Defender for Cloud all plans
│   │   │   └── key-vault/              # Per-workload Key Vault
│   │   ├── migration/
│   │   │   └── asr-replication/        # ASR vault, fabrics, replication policy
│   │   └── monitoring/
│   │       └── slo-alerts/             # SLO/SLI alert rules, error budget burn
│   │
│   └── envs/
│       ├── dev/                        # Dev environment variable files
│       ├── qa/                         # QA environment variable files
│       └── prod/                       # Prod environment variable files
│
├── pipelines/
│   └── templates/
│       ├── terraform-cicd.yml          # Reusable 6-stage Terraform pipeline
│       └── dr-test-pipeline.yml        # Automated quarterly DR test pipeline
│
├── tests/
│   ├── post-apply/
│   │   └── post_apply_validate.py      # Post-apply infrastructure validation
│   ├── smoke/
│   │   └── run_wave_smoke_tests.py     # Post-cutover smoke test suite
│   └── dr/
│       └── run_dr_test.py              # DR failover test script
│
├── wiki/
│   ├── 01-getting-started/             # Onboarding, tooling setup, access requests
│   ├── 02-architecture/                # Landing Zone design, network diagrams, ADRs
│   ├── 03-iac-standards/               # Terraform module catalogue, coding standards
│   ├── 04-pipeline-patterns/           # Azure DevOps YAML templates, approval config
│   ├── 05-governance/                  # Policy catalogue, Blueprint definitions
│   ├── 06-migration-patterns/          # Pattern decision tree, runbooks, checklists
│   ├── 07-operations/                  # Per-workload runbooks, SLO definitions
│   └── 08-wave-reports/                # Assessments, retrospectives, handover packs
│
└── .github/
    ├── workflows/
    │   └── pages-deploy.yml            # GitHub Actions: auto-deploy index.html to Pages
    └── ISSUE_TEMPLATE/
        ├── pattern-request.md          # Request a new migration pattern
        └── bug-report.md               # Report an issue with a script or module
```

---

## Tech Stack

| Category | Tools |
|----------|-------|
| **Cloud Platform** | Microsoft Azure (Expert) · AWS (SA Associate) · GCP (Cloud Engineer) |
| **IaC** | Terraform (Azure RM + API providers) · ARM Templates · Pulumi |
| **CI/CD** | Azure DevOps Pipelines · GitHub Actions · GitOps (ArgoCD, Flux) |
| **Security Scan** | tfsec · Checkov · SonarQube · tflint |
| **Migration** | Azure Migrate · Azure Site Recovery · Azure DMS |
| **Containers** | AKS · Docker · Helm · Istio · OpenShift |
| **Governance** | Azure Policy · Azure Blueprints · Defender for Cloud · Sentinel |
| **Monitoring** | Azure Monitor · Dynatrace · Prometheus · Datadog |
| **Scripting** | PowerShell · Python 3.11+ · Bash · HCL |

---

## Certifications

| Certification | Issuer |
|---------------|--------|
| Azure Solutions Architect Expert | Microsoft |
| Azure DevOps Engineer Expert | Microsoft |
| Azure Administrator Associate | Microsoft |
| Azure Security Engineer Associate | Microsoft |
| Azure Data Engineer Associate | Microsoft |
| AWS Solutions Architect – Associate | Amazon Web Services |
| GCP Associate Cloud Engineer | Google Cloud |
| GCP Professional Machine Learning Engineer | Google Cloud |
| Certified Kubernetes Administrator (CKA) | CNCF |
| Terraform Associate | HashiCorp |
| Databricks Data Engineer Associate | Databricks |

---

## Quick Start — Using the Scripts

### Prerequisites
```powershell
# Run the bootstrap script on your workstation or build agent (as Administrator)
.\scripts\powershell\00-bootstrap-toolchain.ps1 -TerraformVersion "1.8.3"
```

### Phase 1 — Deploy Azure Migrate Project
```powershell
.\scripts\powershell\P1-01-deploy-migrate-appliance.ps1 `
  -ResourceGroupName "rg-migrate-prod" `
  -ProjectName       "migration-project-01" `
  -Location          "uksouth" `
  -SubscriptionId    "YOUR-SUBSCRIPTION-ID"
```

### Phase 1 — Export & Score Inventory
```bash
export AZURE_SUBSCRIPTION_ID="YOUR-SUBSCRIPTION-ID"
export MIGRATE_RG="rg-migrate-prod"
export MIGRATE_PROJECT="migration-project-01"

python scripts/python/P1-02-export-inventory.py
# Output: migration_inventory.csv with Wave assignments
```

### Phase 2 — Setup Terraform Backend
```powershell
.\scripts\powershell\P2-01-setup-tf-backend.ps1 `
  -ResourceGroupName  "rg-tfstate-prod" `
  -Location           "uksouth" `
  -StorageAccountName "stmigrationtfstate01" `
  -SubscriptionId     "YOUR-SUBSCRIPTION-ID"
```

### Phase 4 — Wave Cutover
```powershell
.\scripts\powershell\P4-01-wave-cutover.ps1 `
  -VaultName           "rsv-migration-prod-uks" `
  -VaultResourceGroup  "rg-migration-prod" `
  -VMNames             @("vm-app01","vm-app02","vm-db01") `
  -TargetResourceGroup "rg-workload-prod" `
  -DnsZoneName         "internal.contoso.com" `
  -DnsResourceGroup    "rg-dns-prod"
```

---

## LinkedIn Post

The full technical post is published at:

> 🌐 **[kshartul.github.io/azure-migration-blueprint](https://kshartul.github.io/azure-migration-blueprint)**

Share on LinkedIn using this feed post template:

---

*I built a complete engineering blueprint for large-scale Azure migrations.*

*Not slides. Not a deck. An actual technical framework with:*

*→ PowerShell scripts for Azure Migrate assessment automation*  
*→ Terraform hub-spoke Landing Zone modules*  
*→ Reusable 6-stage Azure DevOps CI/CD pipeline template*  
*→ Wave cutover orchestration with ASR + automated smoke tests*  
*→ Azure Policy initiative — governance from Day 1, not bolted on*  
*→ SLO/SLI KQL alert rules and automated quarterly DR tests*  

*6 phases. 13 sprints. 500+ workload scale.*  

*Full post + downloadable docs below 👇*

*#AzureMigration #Terraform #AzureDevOps #CloudArchitecture #InfrastructureAsCode #MicrosoftAzure #DevOps #SRE #FinOps #CAF #GitOps #CloudMigration*

---

*(Paste your GitHub Pages URL in the first comment, not the post body)*

---

## Contributing

Found an issue with a script or module? Have a new migration pattern to contribute?

1. Open an [Issue](https://github.com/kshartul/azure-migration-blueprint/issues) using the appropriate template
2. Fork the repository
3. Create a feature branch: `git checkout -b pattern/your-pattern-name`
4. Commit your changes: `git commit -m 'feat: add rehost pattern for SQL workloads'`
5. Push and open a Pull Request

---

## Licence

MIT — free to use, adapt, and share with attribution.

---

<div align="center">

**Built by [Shartul Kumar](https://www.linkedin.com/in/shartul)**  
Senior Azure Migration Architect · Azure Solutions Architect Expert · CKA · Terraform Associate

[LinkedIn](https://www.linkedin.com/in/shartul) · [GitHub](https://github.com/kshartul) · [Live Post](https://kshartul.github.io/azure-migration-blueprint)

</div>
