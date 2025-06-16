# TOEIC Backend - Advanced Monitoring (Week 4) Deployment Script

param(
    [string]$Action = "deploy",
    [string]$Environment = "monitoring",
    [switch]$Force,
    [switch]$SkipBuild,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Configuration
$CONFIG = @{
    ProjectName = "toeic-backend"
    Version = "week4-advanced-monitoring"
    ComposeFile = "docker-compose.monitoring.yml"
    AdvancedFeaturesEnabled = $true
    Services = @{
        App = "toeic_app"
        Database = "toeic_postgres"
        Redis = "toeic_redis"
        Prometheus = "toeic_prometheus"
        Grafana = "toeic_grafana"
        Alertmanager = "toeic_alertmanager"
        Loki = "toeic_loki"
        NodeExporter = "toeic_node_exporter"
        PostgresExporter = "toeic_postgres_exporter"
        RedisExporter = "toeic_redis_exporter"
    }
    HealthEndpoints = @{
        App = "http://localhost:8081/health"
        AdvancedHealth = "http://localhost:8081/monitoring/health/advanced"
        Prometheus = "http://localhost:9090/-/healthy"
        Grafana = "http://localhost:3001/api/health"
        Alertmanager = "http://localhost:9093/-/healthy"
    }
    MonitoringPorts = @{
        App = 8081
        Prometheus = 9090
        Grafana = 3001
        Alertmanager = 9093
        Loki = 3100
        NodeExporter = 9100
        PostgresExporter = 9187
        RedisExporter = 9121
    }
}

function Write-Header {
    param([string]$Title)
    
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error-Step {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-DockerCompose {
    try {
        $version = docker-compose version
        if ($LASTEXITCODE -ne 0) {
            throw "Docker Compose not available"
        }
        return $true
    }
    catch {
        Write-Error-Step "Docker Compose is not available. Please install Docker Desktop."
        return $false
    }
}

function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    $checks = @()
    
    # Check Docker
    try {
        docker version | Out-Null
        $checks += @{ Name = "Docker"; Status = "✅" }
    }
    catch {
        $checks += @{ Name = "Docker"; Status = "❌" }
    }
    
    # Check Docker Compose
    if (Test-DockerCompose) {
        $checks += @{ Name = "Docker Compose"; Status = "✅" }
    }
    else {
        $checks += @{ Name = "Docker Compose"; Status = "❌" }
    }
    
    # Check .env file
    if (Test-Path ".env") {
        $checks += @{ Name = ".env file"; Status = "✅" }
    }
    else {
        $checks += @{ Name = ".env file"; Status = "⚠️" }
        Write-Warning ".env file not found. Using defaults."
    }
    
    # Check monitoring configuration files
    $monitoringFiles = @(
        "monitoring/prometheus.yml",
        "monitoring/alerts.yml",
        "monitoring/alerts-advanced.yml",
        "monitoring/recording-rules.yml",
        "monitoring/grafana/provisioning/dashboards/toeic-advanced-overview.json"
    )
    
    $allFilesExist = $true
    foreach ($file in $monitoringFiles) {
        if (Test-Path $file) {
            $checks += @{ Name = $file; Status = "✅" }
        }
        else {
            $checks += @{ Name = $file; Status = "❌" }
            $allFilesExist = $false
        }
    }
    
    # Display results
    Write-Host ""
    Write-Host "Prerequisites Check:" -ForegroundColor Cyan
    foreach ($check in $checks) {
        Write-Host "  $($check.Status) $($check.Name)"
    }
    Write-Host ""
    
    return $allFilesExist
}

function Deploy-AdvancedMonitoring {
    Write-Header "TOEIC Backend - Advanced Monitoring Deployment (Week 4)"
    
    if (-not (Test-Prerequisites)) {
        Write-Error-Step "Prerequisites check failed. Please ensure all required files are present."
        exit 1
    }
    
    Write-Step "Starting advanced monitoring deployment..."
    
    # Stop existing services if Force is specified
    if ($Force) {
        Write-Step "Stopping existing services..."
        docker-compose -f $CONFIG.ComposeFile down 2>$null
    }
    
    # Pull latest images
    Write-Step "Pulling latest Docker images..."
    docker-compose -f $CONFIG.ComposeFile pull
    
    # Build application if not skipped
    if (-not $SkipBuild) {
        Write-Step "Building application..."
        docker-compose -f $CONFIG.ComposeFile build app
    }
    
    # Start services
    Write-Step "Starting monitoring stack..."
    docker-compose -f $CONFIG.ComposeFile up -d
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Step "Failed to start monitoring stack"
        exit 1
    }
    
    Write-Success "Monitoring stack started successfully"
    
    # Wait for services to be ready
    Wait-ForServices
    
    # Verify deployment
    Test-Deployment
    
    # Show monitoring URLs
    Show-MonitoringDashboard
}

function Wait-ForServices {
    Write-Step "Waiting for services to be ready..."
    
    $maxAttempts = 60
    $attempt = 0
    
    foreach ($endpoint in $CONFIG.HealthEndpoints.GetEnumerator()) {
        Write-Step "Checking $($endpoint.Key) health..."
        $attempt = 0
        
        do {
            $attempt++
            try {
                $response = Invoke-WebRequest -Uri $endpoint.Value -TimeoutSec 5 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    Write-Success "$($endpoint.Key) is healthy"
                    break
                }
            }
            catch {
                # Continue trying
            }
            
            if ($attempt -lt $maxAttempts) {
                Write-Host "⏳ Waiting for $($endpoint.Key)... ($attempt/$maxAttempts)" -ForegroundColor Blue
                Start-Sleep -Seconds 2
            }
        } while ($attempt -lt $maxAttempts)
        
        if ($attempt -ge $maxAttempts) {
            Write-Warning "$($endpoint.Key) health check timeout"
        }
    }
}

function Test-Deployment {
    Write-Step "Verifying advanced monitoring deployment..."
    
    $deploymentStatus = @{}
    
    # Check container status
    Write-Step "Checking container status..."
    foreach ($service in $CONFIG.Services.GetEnumerator()) {
        try {
            $containerStatus = docker ps --filter "name=$($service.Value)" --format "{{.Status}}"
            if ($containerStatus -match "Up") {
                $deploymentStatus[$service.Key] = "✅ Running"
            }
            else {
                $deploymentStatus[$service.Key] = "❌ Not running"
            }
        }
        catch {
            $deploymentStatus[$service.Key] = "❌ Error checking status"
        }
    }
    
    # Check advanced monitoring endpoints
    Write-Step "Testing advanced monitoring endpoints..."
    
    $advancedEndpoints = @{
        "SLA Status" = "http://localhost:8081/monitoring/sla/status"
        "Anomaly Detection" = "http://localhost:8081/monitoring/anomalies"
        "Business Metrics" = "http://localhost:8081/monitoring/business/metrics"
        "Security Events" = "http://localhost:8081/monitoring/security/events"
        "Performance Optimization" = "http://localhost:8081/monitoring/performance/suggestions"
    }
    
    foreach ($endpoint in $advancedEndpoints.GetEnumerator()) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Value -TimeoutSec 10 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $deploymentStatus[$endpoint.Key] = "✅ Available"
            }
            elseif ($response.StatusCode -eq 503) {
                $deploymentStatus[$endpoint.Key] = "⚠️ Service Unavailable (feature disabled)"
            }
            else {
                $deploymentStatus[$endpoint.Key] = "❌ HTTP $($response.StatusCode)"
            }
        }
        catch {
            $deploymentStatus[$endpoint.Key] = "❌ Connection failed"
        }
    }
    
    # Display results
    Write-Host ""
    Write-Host "Deployment Status:" -ForegroundColor Cyan
    foreach ($status in $deploymentStatus.GetEnumerator()) {
        Write-Host "  $($status.Value) $($status.Key)"
    }
    Write-Host ""
    
    # Check Prometheus targets
    Write-Step "Checking Prometheus targets..."
    try {
        $targetsResponse = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/targets" -TimeoutSec 10
        $healthyTargets = ($targetsResponse.data.activeTargets | Where-Object { $_.health -eq "up" }).Count
        $totalTargets = $targetsResponse.data.activeTargets.Count
        
        Write-Host "  📊 Prometheus Targets: $healthyTargets/$totalTargets healthy" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not check Prometheus targets"
    }
    
    # Check Grafana datasources
    Write-Step "Checking Grafana datasources..."
    try {
        # Note: This would require authentication in a real scenario
        Write-Host "  📈 Grafana datasources should be checked manually" -ForegroundColor Yellow
    }
    catch {
        Write-Warning "Could not check Grafana datasources"
    }
}

function Show-MonitoringDashboard {
    Write-Header "TOEIC Advanced Monitoring Dashboard"
    
    Write-Host "🚀 Advanced Monitoring (Week 4) is now running!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Monitoring Interfaces:" -ForegroundColor Cyan
    Write-Host "   • Application:           http://localhost:8081" -ForegroundColor White
    Write-Host "   • Advanced Health:       http://localhost:8081/monitoring/health/advanced" -ForegroundColor White
    Write-Host "   • Prometheus:            http://localhost:9090" -ForegroundColor White
    Write-Host "   • Grafana:               http://localhost:3001 (admin/admin123)" -ForegroundColor White
    Write-Host "   • Alertmanager:          http://localhost:9093" -ForegroundColor White
    Write-Host "   • Loki (Logs):          http://localhost:3100" -ForegroundColor White
    Write-Host ""
    Write-Host "🔍 Advanced Monitoring Endpoints:" -ForegroundColor Cyan
    Write-Host "   • SLA Status:            http://localhost:8081/monitoring/sla/status" -ForegroundColor White
    Write-Host "   • Anomaly Detection:     http://localhost:8081/monitoring/anomalies" -ForegroundColor White
    Write-Host "   • Capacity Planning:     http://localhost:8081/monitoring/capacity/predictions" -ForegroundColor White
    Write-Host "   • Business Analytics:    http://localhost:8081/monitoring/business/metrics" -ForegroundColor White
    Write-Host "   • Security Monitoring:   http://localhost:8081/monitoring/security/events" -ForegroundColor White
    Write-Host "   • Performance Optimization: http://localhost:8081/monitoring/performance/suggestions" -ForegroundColor White
    Write-Host ""
    Write-Host "📈 Key Features:" -ForegroundColor Cyan
    Write-Host "   • SLA Monitoring & Compliance Tracking" -ForegroundColor White
    Write-Host "   • Real-time Anomaly Detection" -ForegroundColor White
    Write-Host "   • Predictive Capacity Planning" -ForegroundColor White
    Write-Host "   • Business Intelligence Dashboards" -ForegroundColor White
    Write-Host "   • Advanced Security Monitoring" -ForegroundColor White
    Write-Host "   • Automated Performance Optimization" -ForegroundColor White
    Write-Host "   • Distributed Tracing Support" -ForegroundColor White
    Write-Host "   • Machine Learning-based Predictions" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Useful Commands:" -ForegroundColor Cyan
    Write-Host "   • View logs:             docker-compose -f $($CONFIG.ComposeFile) logs -f" -ForegroundColor White
    Write-Host "   • Stop services:         docker-compose -f $($CONFIG.ComposeFile) down" -ForegroundColor White
    Write-Host "   • Restart services:      docker-compose -f $($CONFIG.ComposeFile) restart" -ForegroundColor White
    Write-Host "   • View metrics:          curl http://localhost:8081/prometheus" -ForegroundColor White
    Write-Host "   • Advanced health:       curl http://localhost:8081/monitoring/health/advanced" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 Grafana Dashboards:" -ForegroundColor Cyan
    Write-Host "   • TOEIC Advanced Application Overview" -ForegroundColor White
    Write-Host "   • TOEIC Performance Analytics" -ForegroundColor White
    Write-Host "   • TOEIC Business Intelligence" -ForegroundColor White
    Write-Host "   • Infrastructure Monitoring" -ForegroundColor White
    Write-Host "   • Security Monitoring" -ForegroundColor White
    Write-Host ""
    Write-Host "🎯 Week 4 Achievements:" -ForegroundColor Cyan
    Write-Host "   ✅ Advanced SLA monitoring with compliance tracking" -ForegroundColor Green
    Write-Host "   ✅ Machine learning-based anomaly detection" -ForegroundColor Green
    Write-Host "   ✅ Predictive capacity planning" -ForegroundColor Green
    Write-Host "   ✅ Business intelligence dashboards" -ForegroundColor Green
    Write-Host "   ✅ Enhanced security monitoring" -ForegroundColor Green
    Write-Host "   ✅ Performance optimization recommendations" -ForegroundColor Green
    Write-Host "   ✅ Advanced Grafana dashboards" -ForegroundColor Green
    Write-Host "   ✅ Distributed tracing infrastructure" -ForegroundColor Green
    Write-Host ""
}

function Stop-AdvancedMonitoring {
    Write-Header "Stopping Advanced Monitoring"
    
    Write-Step "Stopping monitoring services..."
    docker-compose -f $CONFIG.ComposeFile down
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Advanced monitoring stopped successfully"
    }
    else {
        Write-Error-Step "Failed to stop some services"
    }
}

function Show-Status {
    Write-Header "Advanced Monitoring Status"
    
    Write-Step "Checking service status..."
    docker-compose -f $CONFIG.ComposeFile ps
    
    Write-Host ""
    Write-Step "Checking resource usage..."
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    
    Write-Host ""
    Write-Step "Checking health endpoints..."
    foreach ($endpoint in $CONFIG.HealthEndpoints.GetEnumerator()) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Value -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Success "$($endpoint.Key): Healthy"
            }
            else {
                Write-Warning "$($endpoint.Key): HTTP $($response.StatusCode)"
            }
        }
        catch {
            Write-Error-Step "$($endpoint.Key): Connection failed"
        }
    }
}

function Show-Logs {
    Write-Header "Advanced Monitoring Logs"
    
    if ($args.Count -gt 0) {
        $service = $args[0]
        Write-Step "Showing logs for $service..."
        docker-compose -f $CONFIG.ComposeFile logs -f $service
    }
    else {
        Write-Step "Showing all logs..."
        docker-compose -f $CONFIG.ComposeFile logs -f
    }
}

# Main execution
switch ($Action.ToLower()) {
    "deploy" {
        Deploy-AdvancedMonitoring
    }
    "stop" {
        Stop-AdvancedMonitoring
    }
    "status" {
        Show-Status
    }
    "logs" {
        Show-Logs @args
    }
    "dashboard" {
        Show-MonitoringDashboard
    }
    "test" {
        Test-Deployment
    }
    default {
        Write-Host "Usage: .\deploy-advanced-monitoring.ps1 [deploy|stop|status|logs|dashboard|test]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  deploy    - Deploy advanced monitoring stack" -ForegroundColor White
        Write-Host "  stop      - Stop monitoring services" -ForegroundColor White
        Write-Host "  status    - Show service status" -ForegroundColor White
        Write-Host "  logs      - View service logs" -ForegroundColor White
        Write-Host "  dashboard - Show monitoring dashboard info" -ForegroundColor White
        Write-Host "  test      - Test deployment" -ForegroundColor White
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  -Force        - Force restart of services" -ForegroundColor White
        Write-Host "  -SkipBuild    - Skip application build" -ForegroundColor White
        Write-Host "  -Verbose      - Verbose output" -ForegroundColor White
    }
}
