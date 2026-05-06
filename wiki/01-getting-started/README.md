# Getting Started

## Onboarding Checklist

- [ ] Request Azure subscription access (Platform team)
- [ ] Request Azure DevOps project access — `azure-migration` project
- [ ] Clone all repositories (see [repo list](../03-iac-standards/module-catalogue.md))
- [ ] Run `scripts/powershell/00-bootstrap-toolchain.ps1` on your workstation
- [ ] Verify tool versions match the required toolchain (see below)
- [ ] Request service principal credentials from the security team
- [ ] Configure local Azure CLI: `az login` → `az account set --subscription <id>`
- [ ] Configure Terraform backend: copy `backend.tf` from Confluence and update key

## Required Tool Versions

| Tool | Minimum Version | Install |
|------|----------------|---------|
| Terraform | 1.5.0 | `tfenv install 1.8.3` |
| Azure CLI | 2.58.0 | `az upgrade` |
| tflint | 0.51.0 | See bootstrap script |
| tfsec | 1.28.0 | See bootstrap script |
| Checkov | 3.2.0 | `pip install checkov` |
| Python | 3.11.0 | `pyenv install 3.11.9` |
| kubectl | Matches AKS version | `az aks install-cli` |
| Helm | 3.x | See bootstrap script |

## First-Day Tasks

1. Read the [Architecture Overview](../02-architecture/landing-zone-design.md)
2. Read the [IaC Coding Standards](../03-iac-standards/terraform-standards.md)
3. Review the [Migration Pattern Catalogue](../06-migration-patterns/pattern-catalogue.md)
4. Attend the next sprint planning session
5. Pick up your first story from the Azure Boards backlog
