$ErrorActionPreference = "Continue"
$elb = "http://a58ecf898ca284bbf9056d00d934692a-1428735725.ap-south-1.elb.amazonaws.com"
$headers = @{
    "Origin" = $elb
}

Write-Host "=== 1. Testing Frontend UI ==="
$frontend = Invoke-WebRequest -Uri $elb -UseBasicParsing
Write-Host "Status:" $frontend.StatusCode "Length:" $frontend.Content.Length

Write-Host "`n=== 2. Testing Streaming Service with Browser Origin ==="
$streaming = Invoke-RestMethod -Uri "$elb/api/streaming/videos" -Method Get -Headers $headers
Write-Host "Streaming Videos Response:" ($streaming | ConvertTo-Json -Compress)

Write-Host "`n=== 3. Testing Auth Service Registration with Browser Origin ==="
$userEmail = "user_" + (Get-Random -Minimum 1000 -Maximum 9999) + "@testcorp.com"
$regBody = @{
    name = "Shashank Dubey"
    email = $userEmail
    password = "SecurePassword123!"
} | ConvertTo-Json

try {
    $regResponse = Invoke-RestMethod -Uri "$elb/api/auth/register" -Method Post -Body $regBody -ContentType "application/json" -Headers $headers
    Write-Host "Register Response:" ($regResponse | ConvertTo-Json -Compress)
} catch {
    Write-Host "Register Result:" $_.Exception.Message
}

Write-Host "`n=== 4. Testing Auth Service Login with Browser Origin ==="
$loginBody = @{
    email = $userEmail
    password = "SecurePassword123!"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$elb/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json" -Headers $headers
    Write-Host "Login Response Success:" $loginResponse.success
    Write-Host "Token Received:" ($loginResponse.token.Substring(0, 20) + "...")
} catch {
    Write-Host "Login Result:" $_.Exception.Message
}

Write-Host "`n=== 5. Ingress Routing & CORS Verification Complete ==="
