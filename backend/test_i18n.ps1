# Test script for i18n functionality
# This script tests the internationalization system

$baseUrl = "http://192.168.31.37:8000"

# Required security headers (placeholder values for testing)
$headers = @{
    "X-Security-Token" = "test-token"
    "X-Client-Signature" = "test-signature"
    "X-Request-Timestamp" = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    "X-Origin-Validation" = "test-origin"
}

Write-Host "Testing i18n endpoints..." -ForegroundColor Green

# Test 1: Health check with default language
Write-Host "`n1. Testing health check with default language (English):" -ForegroundColor Yellow
try {
    $response1 = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET -Headers $headers
    $json1 = $response1.Content | ConvertFrom-Json
    Write-Host "   Response: $($json1 | ConvertTo-Json -Compress)" -ForegroundColor Cyan
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Health check with Vietnamese language header
Write-Host "`n2. Testing health check with Vietnamese language (Accept-Language header):" -ForegroundColor Yellow
try {
    $headersVi = $headers.Clone()
    $headersVi["Accept-Language"] = "vi"
    $response2 = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET -Headers $headersVi
    $json2 = $response2.Content | ConvertFrom-Json
    Write-Host "   Response: $($json2 | ConvertTo-Json -Compress)" -ForegroundColor Cyan
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Health check with Vietnamese language query parameter
Write-Host "`n3. Testing health check with Vietnamese language (query parameter):" -ForegroundColor Yellow
try {
    $response3 = Invoke-WebRequest -Uri "$baseUrl/health?lang=vi" -Method GET -Headers $headers
    $json3 = $response3.Content | ConvertFrom-Json
    Write-Host "   Response: $($json3 | ConvertTo-Json -Compress)" -ForegroundColor Cyan
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Test i18n languages endpoint
Write-Host "`n4. Testing i18n languages endpoint:" -ForegroundColor Yellow
try {
    $response4 = Invoke-WebRequest -Uri "$baseUrl/api/v1/i18n/languages" -Method GET -Headers $headers
    $json4 = $response4.Content | ConvertFrom-Json
    Write-Host "   Response: $($json4 | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Test current language endpoint
Write-Host "`n5. Testing current language endpoint with Vietnamese:" -ForegroundColor Yellow
try {
    $headersVi = $headers.Clone()
    $headersVi["X-Language"] = "vi"
    $response5 = Invoke-WebRequest -Uri "$baseUrl/api/v1/i18n/current" -Method GET -Headers $headersVi
    $json5 = $response5.Content | ConvertFrom-Json
    Write-Host "   Response: $($json5 | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Test translation endpoint
Write-Host "`n6. Testing translation endpoint:" -ForegroundColor Yellow
try {
    $headersVi = $headers.Clone()
    $headersVi["Accept-Language"] = "vi"
    $response6 = Invoke-WebRequest -Uri "$baseUrl/api/v1/i18n/translate?key=login_successful" -Method GET -Headers $headersVi
    $json6 = $response6.Content | ConvertFrom-Json
    Write-Host "   Response: $($json6 | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTesting complete!" -ForegroundColor Green
