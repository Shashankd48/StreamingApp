#!/usr/bin/env bash
set -euo pipefail

# Infrastructure Automation: Build, Tag & Push Microservices to Amazon ECR
# Target Region: ap-south-1 (Mumbai)

AWS_REGION="${AWS_REGION:-ap-south-1}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text | tr -d '\r')"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
TAG="${1:-v1.0.0}"

echo "=== Authenticating Docker to Amazon ECR: ${ECR_REGISTRY} ==="
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

declare -A services=(
    ["streamingapp-frontend"]="./frontend"
    ["streamingapp-auth"]="./backend/authService"
    ["streamingapp-streaming"]="./backend/streamingService"
    ["streamingapp-admin"]="./backend/adminService"
    ["streamingapp-chat"]="./backend/chatService"
)

for svc in "streamingapp-frontend" "streamingapp-auth" "streamingapp-streaming" "streamingapp-admin" "streamingapp-chat"; do
    context="${services[$svc]}"
    repoUri="${ECR_REGISTRY}/${svc}"
    echo ""
    echo "=== Building & Pushing: ${svc} -> ${repoUri} (${TAG}, latest) ==="
    
    docker build -t "${repoUri}:${TAG}" -t "${repoUri}:latest" "${context}"
    docker push "${repoUri}:${TAG}"
    docker push "${repoUri}:latest"
done

echo ""
echo "=== All images pushed successfully to Amazon ECR! ==="
