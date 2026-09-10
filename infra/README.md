# Infrastructure & Cloud Provisioning Scripts

This directory contains all declarative configuration policies and infrastructure automation scripts used to provision, configure, and maintain the AWS cloud resources for the **StreamingApp** project.

## Directory Contents

| File | Type | Purpose |
| :--- | :--- | :--- |
| **`s3-cors.json`** | JSON Policy | Cross-Origin Resource Sharing (CORS) policy enabling web browsers and backend services to stream and upload video chunks to Amazon S3. |
| **`setup-s3-bucket.sh`** / **`.ps1`** | Automation Script | Provisions the Amazon S3 general-purpose media bucket in region `ap-south-1` and applies the CORS configuration. |
| **`setup-ecr-repositories.sh`** / **`.ps1`** | Automation Script | Automates creation of the 5 dedicated private Amazon Elastic Container Registry (ECR) repositories with `scanOnPush=true` vulnerability scanning. |
| **`build-and-push-ecr.sh`** / **`.ps1`** | Automation Script | Authenticates the local Docker client via `aws ecr get-login-password`, builds each microservice, tags them with semantic version (`v1.0.0`) and `latest`, and pushes all images to Amazon ECR. |

## Quick Usage

### PowerShell (Windows)
```powershell
# 1. Provision S3 Bucket with CORS
.\infra\setup-s3-bucket.ps1

# 2. Create ECR Repositories
.\infra\setup-ecr-repositories.ps1

# 3. Build & Push All Microservice Images
.\infra\build-and-push-ecr.ps1 v1.0.0
```

### Bash (Linux / macOS / Jenkins Agent)
```bash
# 1. Provision S3 Bucket with CORS
chmod +x infra/*.sh
./infra/setup-s3-bucket.sh

# 2. Create ECR Repositories
./infra/setup-ecr-repositories.sh

# 3. Build & Push All Microservice Images
./infra/build-and-push-ecr.sh v1.0.0
```
