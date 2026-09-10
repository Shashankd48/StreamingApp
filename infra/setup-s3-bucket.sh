#!/usr/bin/env bash
set -euo pipefail

# Infrastructure Automation: S3 Media Bucket Setup
# Target Region: ap-south-1 (Mumbai)

AWS_REGION="${AWS_REGION:-ap-south-1}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text | tr -d '\r')"
BUCKET_NAME="streamingapp-media-${AWS_ACCOUNT_ID}-${AWS_REGION}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Setting up Amazon S3 Bucket: ${BUCKET_NAME} ==="

if [ "${AWS_REGION}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}"
else
    aws s3api create-bucket \
        --bucket "${BUCKET_NAME}" \
        --region "${AWS_REGION}" \
        --create-bucket-configuration LocationConstraint="${AWS_REGION}"
fi

echo "Applying CORS configuration from: ${SCRIPT_DIR}/s3-cors.json"
aws s3api put-bucket-cors --bucket "${BUCKET_NAME}" --cors-configuration "file://${SCRIPT_DIR}/s3-cors.json"

echo "Verifying CORS configuration..."
aws s3api get-bucket-cors --bucket "${BUCKET_NAME}"

echo "=== S3 Setup Complete! Bucket: ${BUCKET_NAME} ==="
