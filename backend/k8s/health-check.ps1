# TOEIC Backend Health Check and Monitoring Script

param(
    [Parameter(Position = 0)]
    [ValidateSet("health", "metrics", "monitor", "troubleshoot", "performance")]
    [string]$Action = "health"
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

function Test-Health {
    Write-StatusMessage "🏥 Performing health checks..." "Info"
    
    # Check namespace
    Write-Host "`n=== Namespace Health ===" -ForegroundColor Yellow
    try {
        kubectl get namespace $NAMESPACE | Out-Null
        Write-StatusMessage "✓ Namespace '$NAMESPACE' exists" "Success"
    } catch {
        Write-StatusMessage "✗ Namespace '$NAMESPACE' not found" "Error"
        return
    }
    
    # Check deployments
    Write-Host "`n=== Deployment Health ===" -ForegroundColor Yellow
    $deployments = @("toeic-backend", "postgres", "redis", "prometheus", "grafana")
    
    foreach ($deployment in $deployments) {
        try {
            $status = kubectl get deployment $deployment -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Available")].status}'
            if ($status -eq "True") {
                Write-StatusMessage "✓ $deployment is healthy" "Success"
            } else {
                Write-StatusMessage "✗ $deployment is not available" "Error"
            }
        } catch {
            Write-StatusMessage "✗ $deployment not found" "Error"
        }
    }
    
    # Check services
    Write-Host "`n=== Service Health ===" -ForegroundColor Yellow
    $services = kubectl get services -n $NAMESPACE --no-headers | ForEach-Object { ($_ -split '\s+')[0] }
    
    foreach ($service in $services) {
        $endpoints = kubectl get endpoints $service -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}'
        if ($endpoints) {
            Write-StatusMessage "✓ $service has endpoints" "Success"
        } else {
            Write-StatusMessage "✗ $service has no endpoints" "Error"
        }
    }
    
    # Check persistent volumes
    Write-Host "`n=== Storage Health ===" -ForegroundColor Yellow
    $pvcs = kubectl get pvc -n $NAMESPACE --no-headers | ForEach-Object { ($_ -split '\s+')[0] }
    
    foreach ($pvc in $pvcs) {
        $status = kubectl get pvc $pvc -n $NAMESPACE -o jsonpath='{.status.phase}'
        if ($status -eq "Bound") {
            Write-StatusMessage "✓ PVC $pvc is bound" "Success"
        } else {
            Write-StatusMessage "✗ PVC $pvc status: $status" "Error"
        }
    }
    
    # Test application endpoints
    Write-Host "`n=== Application Health ===" -ForegroundColor Yellow
    Test-ApplicationEndpoints
}

function Test-ApplicationEndpoints {
    try {
        $NodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
        
        # Test backend health endpoint
        try {
            $response = Invoke-WebRequest -Uri "http://$NodeIP:30080/health" -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-StatusMessage "✓ Backend health endpoint responding" "Success"
            } else {
                Write-StatusMessage "✗ Backend health endpoint returned: $($response.StatusCode)" "Error"
            }
        } catch {
            Write-StatusMessage "✗ Backend health endpoint not accessible" "Error"
        }
        
        # Test Prometheus
        try {
            $response = Invoke-WebRequest -Uri "http://$NodeIP:30090/-/healthy" -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-StatusMessage "✓ Prometheus is healthy" "Success"
            } else {
                Write-StatusMessage "✗ Prometheus health check failed" "Error"
            }
        } catch {
            Write-StatusMessage "✗ Prometheus not accessible" "Error"
        }
        
        # Test Grafana
        try {
            $response = Invoke-WebRequest -Uri "http://$NodeIP:30030/api/health" -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-StatusMessage "✓ Grafana is healthy" "Success"
            } else {
                Write-StatusMessage "✗ Grafana health check failed" "Error"
            }
        } catch {
            Write-StatusMessage "✗ Grafana not accessible" "Error"
        }
        
    } catch {
        Write-StatusMessage "Could not determine node IP for endpoint testing" "Warning"
    }
}

function Show-Metrics {
    Write-StatusMessage "📊 Collecting metrics..." "Info"
    
    Write-Host "`n=== Resource Usage ===" -ForegroundColor Yellow
    kubectl top pods -n $NAMESPACE 2>$null
    
    Write-Host "`n=== HPA Status ===" -ForegroundColor Yellow
    kubectl get hpa -n $NAMESPACE
    
    Write-Host "`n=== Events (Last 10) ===" -ForegroundColor Yellow
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | Select-Object -Last 10
    
    Write-Host "`n=== Pod Status Details ===" -ForegroundColor Yellow
    kubectl get pods -n $NAMESPACE -o wide
    
    Write-Host "`n=== Storage Usage ===" -ForegroundColor Yellow
    kubectl get pvc -n $NAMESPACE
}

function Start-Monitor {
    Write-StatusMessage "🔍 Starting continuous monitoring (Press Ctrl+C to stop)..." "Info"
    
    while ($true) {
        Clear-Host
        Write-Host "TOEIC Backend Monitoring Dashboard - $(Get-Date)" -ForegroundColor Green
        Write-Host "=" * 60 -ForegroundColor Green
        
        # Quick health summary
        Write-Host "`nQuick Health Check:" -ForegroundColor Yellow
        $backendPods = kubectl get pods -n $NAMESPACE -l app=toeic-backend --no-headers | Measure-Object | Select-Object -ExpandProperty Count
        $runningPods = kubectl get pods -n $NAMESPACE -l app=toeic-backend --field-selector=status.phase=Running --no-headers | Measure-Object | Select-Object -ExpandProperty Count
        
        Write-Host "Backend Pods: $runningPods/$backendPods running" -ForegroundColor $(if ($runningPods -eq $backendPods) { "Green" } else { "Red" })
        
        # Resource usage
        Write-Host "`nResource Usage:" -ForegroundColor Yellow
        kubectl top pods -n $NAMESPACE 2>$null | Select-Object -First 5
        
        # Recent events
        Write-Host "`nRecent Events:" -ForegroundColor Yellow
        kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | Select-Object -Last 3
        
        Start-Sleep -Seconds 30
    }
}

function Invoke-Troubleshoot {
    Write-StatusMessage "🔧 Running troubleshooting diagnostics..." "Info"
    
    Write-Host "`n=== Pod Diagnostics ===" -ForegroundColor Yellow
    $failedPods = kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --no-headers
    
    if ($failedPods) {
        Write-StatusMessage "Found non-running pods:" "Warning"
        $failedPods | ForEach-Object {
            $podName = ($_ -split '\s+')[0]
            Write-Host "`nPod: $podName" -ForegroundColor Red
            kubectl describe pod $podName -n $NAMESPACE | Select-String -Pattern "Events:" -A 10
        }
    } else {
        Write-StatusMessage "✓ All pods are running" "Success"
    }
    
    Write-Host "`n=== Service Connectivity ===" -ForegroundColor Yellow
    # Test database connectivity
    try {
        $backendPod = kubectl get pods -n $NAMESPACE -l app=toeic-backend -o jsonpath='{.items[0].metadata.name}'
        if ($backendPod) {
            Write-StatusMessage "Testing database connectivity from backend..." "Info"
            $dbTest = kubectl exec $backendPod -n $NAMESPACE -- nslookup postgres-service 2>&1
            if ($dbTest -match "Address") {
                Write-StatusMessage "✓ Database DNS resolution working" "Success"
            } else {
                Write-StatusMessage "✗ Database DNS resolution failed" "Error"
            }
        }
    } catch {
        Write-StatusMessage "Could not test database connectivity" "Warning"
    }
    
    Write-Host "`n=== Recent Error Logs ===" -ForegroundColor Yellow
    try {
        $backendPod = kubectl get pods -n $NAMESPACE -l app=toeic-backend -o jsonpath='{.items[0].metadata.name}'
        if ($backendPod) {
            kubectl logs $backendPod -n $NAMESPACE --tail=20 | Select-String -Pattern "error|Error|ERROR|fail|Fail|FAIL"
        }
    } catch {
        Write-StatusMessage "Could not retrieve error logs" "Warning"
    }
    
    Write-Host "`n=== Configuration Issues ===" -ForegroundColor Yellow
    # Check ConfigMaps and Secrets
    $configMaps = kubectl get configmaps -n $NAMESPACE --no-headers | ForEach-Object { ($_ -split '\s+')[0] }
    $secrets = kubectl get secrets -n $NAMESPACE --no-headers | ForEach-Object { ($_ -split '\s+')[0] }
    
    Write-StatusMessage "ConfigMaps: $($configMaps -join ', ')" "Info"
    Write-StatusMessage "Secrets: $($secrets -join ', ')" "Info"
}

function Show-Performance {
    Write-StatusMessage "⚡ Performance analysis..." "Info"
    
    Write-Host "`n=== CPU and Memory Usage ===" -ForegroundColor Yellow
    kubectl top pods -n $NAMESPACE 2>$null
    
    Write-Host "`n=== Auto-scaling Status ===" -ForegroundColor Yellow
    kubectl get hpa -n $NAMESPACE -o wide
    
    Write-Host "`n=== Response Time Test ===" -ForegroundColor Yellow
    try {
        $NodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
        
        Write-StatusMessage "Testing response time to health endpoint..." "Info"
        $startTime = Get-Date
        $response = Invoke-WebRequest -Uri "http://$NodeIP:30080/health" -TimeoutSec 10 -UseBasicParsing
        $endTime = Get-Date
        $responseTime = ($endTime - $startTime).TotalMilliseconds
        
        Write-StatusMessage "Response time: $([math]::Round($responseTime, 2))ms" "Info"
        
        if ($responseTime -lt 500) {
            Write-StatusMessage "✓ Good response time" "Success"
        } elseif ($responseTime -lt 1000) {
            Write-StatusMessage "⚠ Moderate response time" "Warning"
        } else {
            Write-StatusMessage "✗ Slow response time" "Error"
        }
        
    } catch {
        Write-StatusMessage "Could not test response time" "Warning"
    }
    
    Write-Host "`n=== Database Performance ===" -ForegroundColor Yellow
    try {
        $postgresPod = kubectl get pods -n $NAMESPACE -l app=postgres -o jsonpath='{.items[0].metadata.name}'
        if ($postgresPod) {
            Write-StatusMessage "Database connections:" "Info"
            kubectl exec $postgresPod -n $NAMESPACE -- psql -U toeicuser -d toeicdb -c "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';"
        }
    } catch {
        Write-StatusMessage "Could not check database performance" "Warning"
    }
}

# Main execution
switch ($Action) {
    "health" { Test-Health }
    "metrics" { Show-Metrics }
    "monitor" { Start-Monitor }
    "troubleshoot" { Invoke-Troubleshoot }
    "performance" { Show-Performance }
    default {
        Write-Host @"
TOEIC Backend Health Check and Monitoring

Usage: .\health-check.ps1 <action>

Actions:
  health       - Perform comprehensive health checks
  metrics      - Show resource usage and metrics
  monitor      - Start continuous monitoring dashboard
  troubleshoot - Run troubleshooting diagnostics
  performance  - Analyze performance metrics

Examples:
  .\health-check.ps1 health
  .\health-check.ps1 monitor
  .\health-check.ps1 troubleshoot

"@
    }
}
