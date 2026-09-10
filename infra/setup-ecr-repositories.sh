#!/usr/bin/env bash
set -euo pipefail

# Infrastructure Automation: Amazon ECR Repositories Provisioning
# Target Region: ap-south-1 (Mumbai)

AWS_REGION="${AWS_REGION:-ap-south-1}"
repos=(
    "streamingapp-frontend"
    "streamingapp-auth"
    "streamingapp-streaming"
    "streamingapp-admin"
    "streamingapp-chat"
)

echo "=== Provisioning 5 Dedicated Amazon ECR Repositories in ${AWS_REGION} ==="

for repo in "${repos[@]}"; do
    echo "Creating repository: ${repo} (scanOnPush=true)..."
    aws ecr create-repository \
        --repository-name "${repo}" \
        --image-scanning-configuration scanOnPush=true \
        --region "${AWS_REGION}" \
        --output json
done

echo ""
echo "=== Verifying Created ECR Repositories ==="
aws ecr describe-repositories \
    --region "${AWS_REGION}" \
    --query "repositories[].{Name:repositoryName,URI:repositoryUri}" \
    --output table
