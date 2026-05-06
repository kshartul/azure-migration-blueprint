#!/usr/bin/env bash
# P2-00-repo-init.sh
# Initialise Azure DevOps project, repositories, and branch policies
# Usage: ./P2-00-repo-init.sh --org https://dev.azure.com/YOUR-ORG --project azure-migration

set -euo pipefail

ORG="https://dev.azure.com/YOUR-ORG"
PROJECT="azure-migration"

while [[ $# -gt 0 ]]; do
    case $1 in
        --org)     ORG="$2";     shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

echo "Configuring Azure DevOps: $ORG / $PROJECT"
az devops configure --defaults organization="$ORG" project="$PROJECT"

# Create repositories
REPOS=("infra-landing-zone" "infra-migration-patterns" "pipelines-templates"
       "migration-governance" "migration-automation")

for REPO in "${REPOS[@]}"; do
    echo "Creating repo: $REPO"
    az repos create --name "$REPO" --project "$PROJECT" 2>/dev/null || echo "  Already exists: $REPO"
done

# Apply branch policies: require PR + min 1 reviewer on main
POLICY_REPOS=("infra-landing-zone" "infra-migration-patterns" "migration-governance")

for REPO in "${POLICY_REPOS[@]}"; do
    REPO_ID=$(az repos show --repository "$REPO" --query id -o tsv)

    # Require minimum 1 reviewer
    az repos policy approver-count create \
        --repository-id "$REPO_ID" --branch main \
        --minimum-approver-count 1 \
        --creator-vote-counts false \
        --allow-downvotes false \
        --reset-on-source-push true \
        --blocking true \
        --output none

    # Require linked work item
    az repos policy work-item-linking create \
        --repository-id "$REPO_ID" --branch main \
        --blocking false \
        --output none

    # Require comment resolution
    az repos policy comment-required create \
        --repository-id "$REPO_ID" --branch main \
        --blocking true \
        --output none

    echo "Branch policies applied: $REPO/main"
done

# Create variable groups for pipeline secrets
echo "Creating variable groups..."
az pipelines variable-group create \
    --name "migration-tf-backend" \
    --variables TF_BACKEND_RG="" TF_BACKEND_SA="" TF_BACKEND_CONTAINER="tfstate" \
    --output none 2>/dev/null || echo "  Variable group already exists"

az pipelines variable-group create \
    --name "migration-azure-creds" \
    --variables ARM_TENANT_ID="" ARM_SUBSCRIPTION_ID="" \
    --output none 2>/dev/null || echo "  Variable group already exists"

echo ""
echo "Repositories and branch policies configured successfully."
echo "Next: add ARM_CLIENT_ID and ARM_CLIENT_SECRET as secret variables in the 'migration-azure-creds' group."
