# Infrastructure Automation: Amazon ECR Repositories Provisioning
# Target Region: ap-south-1 (Mumbai)

$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "ap-south-1" }
$repos = @(
    "streamingapp-frontend",
    "streamingapp-auth",
    "streamingapp-streaming",
    "streamingapp-admin",
    "streamingapp-chat"
)

Write-Host "=== Provisioning 5 Dedicated Amazon ECR Repositories in $AWS_REGION ==="

foreach ($repo in $repos) {
    Write-Host "Creating repository: $repo (scanOnPush=true)..."
    aws ecr create-repository `
        --repository-name $repo `
        --image-scanning-configuration scanOnPush=true `
        --region $AWS_REGION `
        --output json
}

Write-Host "`n=== Verifying Created ECR Repositories ==="
aws ecr describe-repositories `
    --region $AWS_REGION `
    --query "repositories[].{Name:repositoryName,URI:repositoryUri}" `
    --output table
