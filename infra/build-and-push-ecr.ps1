# Infrastructure Automation: Build, Tag & Push Microservices to Amazon ECR
# Target Region: ap-south-1 (Mumbai)

$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "ap-south-1" }
$AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text).Trim()
$ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
$TAG = if ($args[0]) { $args[0] } else { "v1.0.0" }

Write-Host "=== Authenticating Docker to Amazon ECR: $ECR_REGISTRY ==="
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

$services = @(
    @{ Name = "streamingapp-frontend"; Context = "./frontend" },
    @{ Name = "streamingapp-auth";     Context = "./backend/authService" },
    @{ Name = "streamingapp-streaming"; Context = "./backend/streamingService" },
    @{ Name = "streamingapp-admin";    Context = "./backend/adminService" },
    @{ Name = "streamingapp-chat";     Context = "./backend/chatService" }
)

foreach ($svc in $services) {
    $repoUri = "${ECR_REGISTRY}/$($svc.Name)"
    Write-Host "`n=== Building & Pushing: $($svc.Name) -> $repoUri ($TAG, latest) ==="
    
    docker build -t "${repoUri}:${TAG}" -t "${repoUri}:latest" $svc.Context
    docker push "${repoUri}:${TAG}"
    docker push "${repoUri}:latest"
}

Write-Host "`n=== All images pushed successfully to Amazon ECR! ==="
