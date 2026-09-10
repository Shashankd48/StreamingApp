# Infrastructure Automation: S3 Media Bucket Setup
# Target Region: ap-south-1 (Mumbai)

$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "ap-south-1" }
$AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text).Trim()
$BUCKET_NAME = "streamingapp-media-${AWS_ACCOUNT_ID}-${AWS_REGION}"

Write-Host "=== Setting up Amazon S3 Bucket: $BUCKET_NAME ==="

# 1. Create S3 Bucket
if ($AWS_REGION -eq "us-east-1") {
    aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
} else {
    aws s3api create-bucket `
        --bucket $BUCKET_NAME `
        --region $AWS_REGION `
        --create-bucket-configuration LocationConstraint=$AWS_REGION
}

# 2. Configure CORS for direct browser streaming and uploads
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$CORS_FILE = Join-Path $SCRIPT_DIR "s3-cors.json"

Write-Host "Applying CORS configuration from: $CORS_FILE"
aws s3api put-bucket-cors --bucket $BUCKET_NAME --cors-configuration "file://$CORS_FILE"

# 3. Verify
Write-Host "Verifying CORS configuration..."
aws s3api get-bucket-cors --bucket $BUCKET_NAME

Write-Host "=== S3 Setup Complete! Bucket: $BUCKET_NAME ==="
