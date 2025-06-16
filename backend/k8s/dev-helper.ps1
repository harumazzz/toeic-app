# TOEIC Backend Development Helper Script
# This script helps with local development and testing with Kubernetes

param(
    [Parameter(Position = 0)]
    [ValidateSet("dev", "test", "debug", "port-forward", "shell", "db-connect", "redis-connect", "reset-db")]
    [string]$Action = "dev"
)

$NAMESPACE = "toeic-app"

function Write-StatusMessage {
    param([string]$Message, [string]$Type = "Info")
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Info" { "Cyan" }
        default { "White" }
    }
    Write-Host "$(Get-Date -Format 'HH:mm:ss') [$Type] $Message" -ForegroundColor $color
}

function Start-DevMode {
    Write-StatusMessage "🚀 Starting development mode..." "Info"
    
    Write-StatusMessage "Setting up port forwards for local development..." "Info"
    
    # Start port forwards in background
    Start-Process powershell -ArgumentList "-Command", "kubectl port-forward service/toeic-backend-service 8000:8000 -n $NAMESPACE" -WindowStyle Minimized
    Start-Process powershell -ArgumentList "-Command", "kubectl port-forward service/postgres-service 5432:5432 -n $NAMESPACE" -WindowStyle Minimized
    Start-Process powershell -ArgumentList "-Command", "kubectl port-forward service/redis-service 6379:6379 -n $NAMESPACE" -WindowStyle Minimized
    Start-Process powershell -ArgumentList "-Command", "kubectl port-forward service/prometheus-service 9090:9090 -n $NAMESPACE" -WindowStyle Minimized
    Start-Process powershell -ArgumentList "-Command", "kubectl port-forward service/grafana-service 3000:3000 -n $NAMESPACE" -WindowStyle Minimized
    
    Start-Sleep -Seconds 3
    
    Write-Host "`n🌐 Local Development Access Points:" -ForegroundColor Green
    Write-Host "Backend API:     http://localhost:8000" -ForegroundColor Cyan
    Write-Host "API Health:      http://localhost:8000/health" -ForegroundColor Cyan
    Write-Host "PostgreSQL:      localhost:5432" -ForegroundColor Cyan
    Write-Host "Redis:           localhost:6379" -ForegroundColor Cyan
    Write-Host "Prometheus:      http://localhost:9090" -ForegroundColor Cyan
    Write-Host "Grafana:         http://localhost:3000" -ForegroundColor Cyan
    
    Write-Host "`n💡 Development Commands:" -ForegroundColor Yellow
    Write-Host "Test API:        curl http://localhost:8000/health" -ForegroundColor White
    Write-Host "Connect to DB:   psql -h localhost -p 5432 -U toeicuser -d toeicdb" -ForegroundColor White
    Write-Host "Connect to Redis: redis-cli -h localhost -p 6379" -ForegroundColor White
    
    Write-StatusMessage "Port forwards active. Press Ctrl+C to stop monitoring." "Success"
    
    # Monitor the services
    while ($true) {
        Clear-Host
        Write-Host "TOEIC Backend Development Dashboard - $(Get-Date)" -ForegroundColor Green
        Write-Host "=" * 60 -ForegroundColor Green
        
        # Test endpoints
        Write-Host "`nEndpoint Status:" -ForegroundColor Yellow
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5 -UseBasicParsing
            Write-Host "✓ Backend API: Online ($($response.StatusCode))" -ForegroundColor Green
        } catch {
            Write-Host "✗ Backend API: Offline" -ForegroundColor Red
        }
        
        # Show recent logs
        Write-Host "`nRecent Logs:" -ForegroundColor Yellow
        try {
            $backendPod = kubectl get pods -n $NAMESPACE -l app=toeic-backend -o jsonpath='{.items[0].metadata.name}'
            kubectl logs $backendPod -n $NAMESPACE --tail=5 --since=30s
        } catch {
            Write-Host "Could not retrieve logs" -ForegroundColor Red
        }
        
        Start-Sleep -Seconds 10
    }
}

function Run-Tests {
    Write-StatusMessage "🧪 Running integration tests..." "Info"
    
    # Check if backend is accessible
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 10 -UseBasicParsing
        Write-StatusMessage "✓ Backend health check passed" "Success"
    } catch {
        Write-StatusMessage "✗ Backend not accessible. Starting port forward..." "Warning"
        Start-Process powershell -ArgumentList "-Command", "kubectl port-forward service/toeic-backend-service 8000:8000 -n $NAMESPACE" -WindowStyle Hidden
        Start-Sleep -Seconds 5
    }
    
    Write-Host "`n🔍 Running API Tests:" -ForegroundColor Yellow
    
    # Test health endpoint
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET
        Write-StatusMessage "✓ Health endpoint: $($health.status)" "Success"
    } catch {
        Write-StatusMessage "✗ Health endpoint failed" "Error"
    }
    
    # Test API endpoints (add your specific endpoints here)
    $testEndpoints = @(
        @{ url = "http://localhost:8000/api/v1/words"; method = "GET"; description = "Words API" },
        @{ url = "http://localhost:8000/api/v1/exams"; method = "GET"; description = "Exams API" },
        @{ url = "http://localhost:8000/api/v1/users/profile"; method = "GET"; description = "User Profile API" }
    )
    
    foreach ($test in $testEndpoints) {
        try {
            $response = Invoke-WebRequest -Uri $test.url -Method $test.method -TimeoutSec 5 -UseBasicParsing
            Write-StatusMessage "✓ $($test.description): $($response.StatusCode)" "Success"
        } catch {
            Write-StatusMessage "✗ $($test.description): Failed" "Warning"
        }
    }
}

function Start-Debug {
    Write-StatusMessage "🐛 Starting debug mode..." "Info"
    
    # Get backend pod for debugging
    $backendPod = kubectl get pods -n $NAMESPACE -l app=toeic-backend -o jsonpath='{.items[0].metadata.name}'
    
    if (-not $backendPod) {
        Write-StatusMessage "No backend pods found" "Error"
        return
    }
    
    Write-Host "`n🔍 Debug Information:" -ForegroundColor Yellow
    Write-Host "Pod: $backendPod" -ForegroundColor White
    
    # Show pod details
    Write-Host "`nPod Status:" -ForegroundColor Yellow
    kubectl describe pod $backendPod -n $NAMESPACE | Select-String -Pattern "Status:|Ready:|Restart Count:|Events:" -A 5
    
    # Show environment variables
    Write-Host "`nEnvironment Variables:" -ForegroundColor Yellow
    kubectl exec $backendPod -n $NAMESPACE -- env | Sort-Object
    
    # Show recent logs with timestamps
    Write-Host "`nRecent Logs:" -ForegroundColor Yellow
    kubectl logs $backendPod -n $NAMESPACE --tail=50 --timestamps
    
    Write-Host "`n💡 Debug Commands:" -ForegroundColor Green
    Write-Host "Shell into pod:     kubectl exec -it $backendPod -n $NAMESPACE -- /bin/sh" -ForegroundColor Cyan
    Write-Host "Follow logs:        kubectl logs -f $backendPod -n $NAMESPACE" -ForegroundColor Cyan
    Write-Host "Describe pod:       kubectl describe pod $backendPod -n $NAMESPACE" -ForegroundColor Cyan
}

function Start-PortForward {
    Write-StatusMessage "🔌 Setting up port forwards..." "Info"
    
    $services = @(
        @{ name = "toeic-backend-service"; local = 8000; remote = 8000; description = "Backend API" },
        @{ name = "postgres-service"; local = 5432; remote = 5432; description = "PostgreSQL" },
        @{ name = "redis-service"; local = 6379; remote = 6379; description = "Redis" },
        @{ name = "prometheus-service"; local = 9090; remote = 9090; description = "Prometheus" },
        @{ name = "grafana-service"; local = 3000; remote = 3000; description = "Grafana" }
    )
    
    foreach ($service in $services) {
        Write-StatusMessage "Starting port forward for $($service.description)..." "Info"
        Start-Process powershell -ArgumentList "-Command", "kubectl port-forward service/$($service.name) $($service.local):$($service.remote) -n $NAMESPACE" -WindowStyle Minimized
    }
    
    Start-Sleep -Seconds 3
    
    Write-Host "`n🌐 Port Forwards Active:" -ForegroundColor Green
    foreach ($service in $services) {
        Write-Host "$($service.description): localhost:$($service.local)" -ForegroundColor Cyan
    }
    
    Write-StatusMessage "Port forwards are running in background windows" "Success"
}

function Connect-Shell {
    Write-StatusMessage "🖥️ Opening shell to backend pod..." "Info"
    
    $backendPod = kubectl get pods -n $NAMESPACE -l app=toeic-backend -o jsonpath='{.items[0].metadata.name}'
    
    if ($backendPod) {
        Write-StatusMessage "Connecting to pod: $backendPod" "Info"
        kubectl exec -it $backendPod -n $NAMESPACE -- /bin/sh
    } else {
        Write-StatusMessage "No backend pods found" "Error"
    }
}

function Connect-Database {
    Write-StatusMessage "🗄️ Connecting to PostgreSQL..." "Info"
    
    $postgresPod = kubectl get pods -n $NAMESPACE -l app=postgres -o jsonpath='{.items[0].metadata.name}'
    
    if ($postgresPod) {
        Write-StatusMessage "Connecting to database pod: $postgresPod" "Info"
        kubectl exec -it $postgresPod -n $NAMESPACE -- psql -U toeicuser -d toeicdb
    } else {
        Write-StatusMessage "No PostgreSQL pods found" "Error"
    }
}

function Connect-Redis {
    Write-StatusMessage "📦 Connecting to Redis..." "Info"
    
    $redisPod = kubectl get pods -n $NAMESPACE -l app=redis -o jsonpath='{.items[0].metadata.name}'
    
    if ($redisPod) {
        Write-StatusMessage "Connecting to Redis pod: $redisPod" "Info"
        kubectl exec -it $redisPod -n $NAMESPACE -- redis-cli
    } else {
        Write-StatusMessage "No Redis pods found" "Error"
    }
}

function Reset-Database {
    Write-StatusMessage "⚠️  Database Reset" "Warning"
    Write-Host "This will reset the database to initial state. Continue? (y/N): " -NoNewline -ForegroundColor Red
    $confirmation = Read-Host
    
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        Write-StatusMessage "Resetting database..." "Info"
        
        # Run migration job
        kubectl delete job db-migration -n $NAMESPACE 2>$null
        kubectl apply -f k8s/migration.yaml
        
        Write-StatusMessage "Database reset initiated. Check job status:" "Info"
        Write-Host "kubectl logs job/db-migration -n $NAMESPACE" -ForegroundColor Cyan
    } else {
        Write-StatusMessage "Database reset cancelled" "Info"
    }
}

# Main execution
switch ($Action) {
    "dev" { Start-DevMode }
    "test" { Run-Tests }
    "debug" { Start-Debug }
    "port-forward" { Start-PortForward }
    "shell" { Connect-Shell }
    "db-connect" { Connect-Database }
    "redis-connect" { Connect-Redis }
    "reset-db" { Reset-Database }
    default {
        Write-Host @"
TOEIC Backend Development Helper

Usage: .\dev-helper.ps1 <action>

Actions:
  dev           - Start development mode with port forwards and monitoring
  test          - Run integration tests against the API
  debug         - Show debug information and logs
  port-forward  - Set up port forwards for all services
  shell         - Open shell in backend pod
  db-connect    - Connect to PostgreSQL database
  redis-connect - Connect to Redis
  reset-db      - Reset database to initial state

Examples:
  .\dev-helper.ps1 dev
  .\dev-helper.ps1 test
  .\dev-helper.ps1 shell

"@
    }
}
