$ErrorActionPreference = "Stop"
$workDir = "d:\Study\HeroVired\assignments\Orchestration and Scaling"
$binDir = Join-Path $workDir "bin"

if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

Write-Host "Setting up eksctl and helm in $binDir..."

# 1. Download eksctl
$eksctlExe = Join-Path $binDir "eksctl.exe"
if (-not (Test-Path $eksctlExe)) {
    Write-Host "Downloading eksctl..."
    $eksctlZip = Join-Path $binDir "eksctl.zip"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Windows_amd64.zip" -OutFile $eksctlZip -UseBasicParsing
    Expand-Archive -Path $eksctlZip -DestinationPath $binDir -Force
    Remove-Item $eksctlZip -Force
    Write-Host "eksctl installed successfully."
} else {
    Write-Host "eksctl is already present."
}

# 2. Download helm
$helmExe = Join-Path $binDir "helm.exe"
if (-not (Test-Path $helmExe)) {
    Write-Host "Downloading helm..."
    $helmZip = Join-Path $binDir "helm.zip"
    Invoke-WebRequest -Uri "https://get.helm.sh/helm-v3.17.0-windows-amd64.zip" -OutFile $helmZip -UseBasicParsing
    $helmTemp = Join-Path $binDir "helm_temp"
    Expand-Archive -Path $helmZip -DestinationPath $helmTemp -Force
    Move-Item (Join-Path $helmTemp "windows-amd64\helm.exe") $helmExe -Force
    Remove-Item $helmTemp -Recurse -Force
    Remove-Item $helmZip -Force
    Write-Host "helm installed successfully."
} else {
    Write-Host "helm is already present."
}

# Verify versions
Write-Host "--- Tool Verification ---"
& $eksctlExe version
& $helmExe version --short
