# =============================================================================
# TOEIC BACKEND - ADVANCED DEPLOYMENT AUTOMATION SCRIPT (PowerShell)
# Week 3 Documentation & Deployment Automation Complete
# =============================================================================

param(
    [Parameter(Position=0)]
    [ValidateSet("deploy", "deploy-staging", "deploy-prod", "deploy-zero-downtime", "health-check", "rollback", "backup", "restore", "logs", "status", "update", "scale", "monitor", "cleanup")]
    [string]$Action = "deploy",
    
    [Parameter(Position=1)]
    [string]$Environment = "development",
    
    [switch]$Force,
    [switch]$SkipBackup,
    [switch]$SkipTests,
    [switch]$Verbose,
    [string]$BackupFile = "",
    [string]$Version = "latest",
    [int]$Replicas = 3
)

$ErrorActionPreference = "Stop"

# =============================================================================
# CONFIGURATION AND CONSTANTS
# =============================================================================

$CONFIG = @{
    AppName = "toeic-backend"
    Version = $Version
    Environments = @{
        development = @{
            ComposeFile = "docker-compose.yml"
            EnvFile = ".env"
            HealthUrl = "http://localhost:8000/health"
            BackupRetention = 7
        }
        staging = @{
            ComposeFile = "docker-compose.staging.yml"
            EnvFile = ".env.staging"
            HealthUrl = "https://staging-api.toeic-app.com/health"
            BackupRetention = 14
        }
        production = @{
            ComposeFile = "docker-compose.prod.yml"
            EnvFile = ".env.production"
            HealthUrl = "https://api.toeic-app.com/health"
            BackupRetention = 30
        }
    }
    HealthTimeout = 120
    BlueGreenTimeout = 300
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function Write-Step($message, $color = "Green") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] 🚀 $message" -ForegroundColor $color
}

function Write-Error-Step($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] ❌ $message" -ForegroundColor Red
}

function Write-Warning-Step($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] ⚠️ $message" -ForegroundColor Yellow
}

function Write-Info-Step($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] ℹ️ $message" -ForegroundColor Blue
}

function Wait-ForHealthCheck($url, $timeout = 120) {
    Write-Step "Waiting for application health check at $url..."
    $elapsed = 0
    $interval = 5
    
    while ($elapsed -lt $timeout) {
        try {
            $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 10
            if ($response.status -eq "healthy") {
                Write-Step "✅ Health check passed!"
                return $true
            }
        }
        catch {
            if ($Verbose) {
                Write-Warning-Step "Health check attempt failed: $($_.Exception.Message)"
            }
        }
        
        Start-Sleep $interval
        $elapsed += $interval
        Write-Host "." -NoNewline
    }
    
    Write-Error-Step "Health check failed after $timeout seconds"
    return $false
}

function Backup-Database($environment) {
    Write-Step "Creating database backup for $environment environment..."
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "backups/pre_deploy_backup_${environment}_${timestamp}.sql"
    
    # Ensure backups directory exists
    if (-not (Test-Path "backups")) {
        New-Item -ItemType Directory -Path "backups" | Out-Null
    }
    
    try {
        $envConfig = $CONFIG.Environments[$environment]
        $composeFile = $envConfig.ComposeFile
        
        # Create database backup
        docker-compose -f $composeFile exec -T postgres pg_dump -U root -d toeic_db > $backupFile
        
        if (Test-Path $backupFile) {
            $fileSize = (Get-Item $backupFile).Length / 1MB
            Write-Step "✅ Database backup created: $backupFile (${fileSize:F2} MB)"
            
            # Compress backup
            gzip $backupFile
            Write-Step "✅ Backup compressed: ${backupFile}.gz"
            
            return "${backupFile}.gz"
        }
        else {
            throw "Backup file was not created"
        }
    }
    catch {
        Write-Error-Step "Failed to create database backup: $($_.Exception.Message)"
        return $null
    }
}

function Run-Tests() {
    if ($SkipTests) {
        Write-Warning-Step "Skipping tests (--SkipTests flag provided)"
        return $true
    }
    
    Write-Step "Running automated tests..."
    
    try {
        # Run unit tests
        Write-Info-Step "Running unit tests..."
        $testResult = go test ./... -v
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Step "Unit tests failed"
            return $false
        }
        
        # Run integration tests if they exist
        if (Test-Path "tests/integration") {
            Write-Info-Step "Running integration tests..."
            go test ./tests/integration/... -v
            if ($LASTEXITCODE -ne 0) {
                Write-Error-Step "Integration tests failed"
                return $false
            }
        }
        
        Write-Step "✅ All tests passed"
        return $true
    }
    catch {
        Write-Error-Step "Test execution failed: $($_.Exception.Message)"
        return $false
    }
}

function Build-Application($environment) {
    Write-Step "Building application for $environment environment..."
    
    try {
        $envConfig = $CONFIG.Environments[$environment]
        $composeFile = $envConfig.ComposeFile
        
        # Build Docker images
        docker-compose -f $composeFile build --no-cache
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed"
        }
        
        Write-Step "✅ Application built successfully"
        return $true
    }
    catch {
        Write-Error-Step "Failed to build application: $($_.Exception.Message)"
        return $false
    }
}

function Deploy-Services($environment) {
    Write-Step "Deploying services for $environment environment..."
    
    try {
        $envConfig = $CONFIG.Environments[$environment]
        $composeFile = $envConfig.ComposeFile
        $envFile = $envConfig.EnvFile
        
        # Verify environment file exists
        if (-not (Test-Path $envFile)) {
            throw "Environment file not found: $envFile"
        }
        
        # Deploy services
        docker-compose -f $composeFile --env-file $envFile up -d --remove-orphans
        if ($LASTEXITCODE -ne 0) {
            throw "Docker deployment failed"
        }
        
        Write-Step "✅ Services deployed successfully"
        return $true
    }
    catch {
        Write-Error-Step "Failed to deploy services: $($_.Exception.Message)"
        return $false
    }
}

function Deploy-ZeroDowntime($environment) {
    Write-Step "Starting zero-downtime deployment for $environment..."
    
    try {
        $envConfig = $CONFIG.Environments[$environment]
        $composeFile = $envConfig.ComposeFile
        $healthUrl = $envConfig.HealthUrl
        
        # Scale up new instances
        Write-Info-Step "Scaling up new application instances..."
        docker-compose -f $composeFile up -d --scale app=$($Replicas + 1) --no-recreate
        
        # Wait for new instances to be healthy
        Start-Sleep 10
        if (-not (Wait-ForHealthCheck $healthUrl $CONFIG.HealthTimeout)) {
            throw "New instances failed health check"
        }
        
        # Scale down old instances gradually
        Write-Info-Step "Scaling down old instances..."
        docker-compose -f $composeFile up -d --scale app=$Replicas --no-recreate
        
        Write-Step "✅ Zero-downtime deployment completed"
        return $true
    }
    catch {
        Write-Error-Step "Zero-downtime deployment failed: $($_.Exception.Message)"
        # Rollback to original scale
        docker-compose -f $envConfig.ComposeFile up -d --scale app=$Replicas --no-recreate
        return $false
    }
}

function Cleanup-OldBackups($environment) {
    Write-Step "Cleaning up old backups for $environment..."
    
    try {
        $envConfig = $CONFIG.Environments[$environment]
        $retentionDays = $envConfig.BackupRetention
        $cutoffDate = (Get-Date).AddDays(-$retentionDays)
        
        $oldBackups = Get-ChildItem "backups/" -Filter "*${environment}*.sql.gz" | 
                     Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        if ($oldBackups.Count -gt 0) {
            Write-Info-Step "Removing $($oldBackups.Count) old backup(s)..."
            $oldBackups | Remove-Item -Force
            Write-Step "✅ Old backups cleaned up"
        }
        else {
            Write-Info-Step "No old backups to clean up"
        }
    }
    catch {
        Write-Warning-Step "Failed to cleanup old backups: $($_.Exception.Message)"
    }
}

function Get-DeploymentStatus($environment) {
    Write-Step "Getting deployment status for $environment..."
    
    try {
        $envConfig = $CONFIG.Environments[$environment]
        $composeFile = $envConfig.ComposeFile
        $healthUrl = $envConfig.HealthUrl
        
        # Check Docker containers
        Write-Info-Step "Container Status:"
        docker-compose -f $composeFile ps
        
        # Check application health
        Write-Info-Step "Application Health:"
        try {
            $healthResponse = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 10
            Write-Host ($healthResponse | ConvertTo-Json -Depth 3) -ForegroundColor Green
        }
        catch {
            Write-Warning-Step "Health endpoint not accessible: $($_.Exception.Message)"
        }
        
        # Check resource usage
        Write-Info-Step "Resource Usage:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
        
        return $true
    }
    catch {
        Write-Error-Step "Failed to get deployment status: $($_.Exception.Message)"
        return $false
    }
}

function Monitor-Deployment($environment) {
    Write-Step "Starting monitoring for $environment environment..."
    
    try {
        $envConfig = $CONFIG.Environments[$environment]
        $composeFile = $envConfig.ComposeFile
        $healthUrl = $envConfig.HealthUrl
        
        # Monitor in loop
        while ($true) {
            Clear-Host
            Write-Host "=== TOEIC Backend Monitoring Dashboard ===" -ForegroundColor Cyan
            Write-Host "Environment: $environment" -ForegroundColor Yellow
            Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
            Write-Host ""
            
            # Container status
            Write-Host "Container Status:" -ForegroundColor Green
            docker-compose -f $composeFile ps
            Write-Host ""
            
            # Resource usage
            Write-Host "Resource Usage:" -ForegroundColor Green
            docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
            Write-Host ""
            
            # Application metrics
            Write-Host "Application Metrics:" -ForegroundColor Green
            try {
                $metrics = Invoke-RestMethod -Uri ($healthUrl -replace "/health", "/metrics") -Method Get -TimeoutSec 5
                Write-Host ($metrics | ConvertTo-Json -Depth 2)
            }
            catch {
                Write-Host "Metrics not available" -ForegroundColor Red
            }
            
            Write-Host ""
            Write-Host "Press Ctrl+C to exit monitoring..." -ForegroundColor Gray
            Start-Sleep 30
        }
    }
    catch {
        Write-Error-Step "Monitoring failed: $($_.Exception.Message)"
    }
}

# =============================================================================
# MAIN DEPLOYMENT FUNCTIONS
# =============================================================================

function Deploy-Application($environment) {
    Write-Step "=== Starting Deployment Process ===" "Cyan"
    Write-Info-Step "Environment: $environment"
    Write-Info-Step "Version: $($CONFIG.Version)"
    Write-Info-Step "Timestamp: $(Get-Date)"
    
    $deploymentSuccess = $true
    $backupFile = $null
    
    try {
        # Step 1: Pre-deployment checks
        if (-not (Test-Path "main.go")) {
            throw "Not in backend directory. Please run from the backend folder."
        }
        
        # Step 2: Run tests
        if (-not (Run-Tests)) {
            throw "Tests failed. Deployment aborted."
        }
        
        # Step 3: Create backup
        if (-not $SkipBackup) {
            $backupFile = Backup-Database $environment
            if (-not $backupFile) {
                if (-not $Force) {
                    throw "Backup failed. Use -Force to proceed anyway."
                }
                Write-Warning-Step "Backup failed but continuing due to -Force flag"
            }
        }
        
        # Step 4: Build application
        if (-not (Build-Application $environment)) {
            throw "Build failed"
        }
        
        # Step 5: Deploy services
        if (-not (Deploy-Services $environment)) {
            throw "Service deployment failed"
        }
        
        # Step 6: Health check
        $envConfig = $CONFIG.Environments[$environment]
        if (-not (Wait-ForHealthCheck $envConfig.HealthUrl $CONFIG.HealthTimeout)) {
            throw "Health check failed after deployment"
        }
        
        # Step 7: Post-deployment tasks
        Cleanup-OldBackups $environment
        
        Write-Step "=== Deployment Completed Successfully ===" "Green"
        Write-Info-Step "Environment: $environment"
        Write-Info-Step "Version: $($CONFIG.Version)"
        Write-Info-Step "Health URL: $($envConfig.HealthUrl)"
        if ($backupFile) {
            Write-Info-Step "Backup created: $backupFile"
        }
        
    }
    catch {
        $deploymentSuccess = $false
        Write-Error-Step "Deployment failed: $($_.Exception.Message)"
        
        if ($backupFile -and (Test-Path $backupFile)) {
            Write-Warning-Step "Consider rolling back using: .\deploy-advanced.ps1 rollback -Environment $environment -BackupFile $backupFile"
        }
    }
    
    return $deploymentSuccess
}

function Rollback-Deployment($environment, $backupFile) {
    Write-Step "=== Starting Rollback Process ===" "Yellow"
    
    try {
        if (-not $backupFile) {
            # Find latest backup
            $latestBackup = Get-ChildItem "backups/" -Filter "*${environment}*.sql.gz" | 
                           Sort-Object LastWriteTime -Descending | 
                           Select-Object -First 1
            
            if ($latestBackup) {
                $backupFile = $latestBackup.FullName
                Write-Info-Step "Using latest backup: $($latestBackup.Name)"
            }
            else {
                throw "No backup file specified and no backups found"
            }
        }
        
        if (-not (Test-Path $backupFile)) {
            throw "Backup file not found: $backupFile"
        }
        
        # Stop current services
        $envConfig = $CONFIG.Environments[$environment]
        Write-Info-Step "Stopping current services..."
        docker-compose -f $envConfig.ComposeFile down
        
        # Restore database
        Write-Info-Step "Restoring database from backup..."
        if ($backupFile.EndsWith(".gz")) {
            gunzip -c $backupFile | docker-compose -f $envConfig.ComposeFile exec -T postgres psql -U root -d toeic_db
        }
        else {
            docker-compose -f $envConfig.ComposeFile exec -T postgres psql -U root -d toeic_db < $backupFile
        }
        
        # Restart services
        Write-Info-Step "Restarting services..."
        docker-compose -f $envConfig.ComposeFile up -d
        
        # Health check
        if (Wait-ForHealthCheck $envConfig.HealthUrl $CONFIG.HealthTimeout) {
            Write-Step "✅ Rollback completed successfully"
        }
        else {
            Write-Warning-Step "Rollback completed but health check failed"
        }
        
    }
    catch {
        Write-Error-Step "Rollback failed: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

# =============================================================================
# MAIN SCRIPT LOGIC
# =============================================================================

try {
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "🚀 TOEIC Backend Advanced Deployment Automation" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    
    switch ($Action) {
        "deploy" {
            Deploy-Application $Environment
        }
        
        "deploy-staging" {
            Deploy-Application "staging"
        }
        
        "deploy-prod" {
            if (-not $Force) {
                $confirm = Read-Host "You are about to deploy to PRODUCTION. Type 'YES' to confirm"
                if ($confirm -ne "YES") {
                    Write-Warning-Step "Production deployment cancelled"
                    exit 0
                }
            }
            Deploy-Application "production"
        }
        
        "deploy-zero-downtime" {
            Deploy-ZeroDowntime $Environment
        }
        
        "health-check" {
            $envConfig = $CONFIG.Environments[$Environment]
            $isHealthy = Wait-ForHealthCheck $envConfig.HealthUrl $CONFIG.HealthTimeout
            exit ($isHealthy ? 0 : 1)
        }
        
        "rollback" {
            Rollback-Deployment $Environment $BackupFile
        }
        
        "backup" {
            $backupFile = Backup-Database $Environment
            if ($backupFile) {
                Write-Step "Backup completed: $backupFile"
            }
        }
        
        "restore" {
            if (-not $BackupFile) {
                Write-Error-Step "Backup file required for restore operation"
                exit 1
            }
            Rollback-Deployment $Environment $BackupFile
        }
        
        "logs" {
            $envConfig = $CONFIG.Environments[$Environment]
            docker-compose -f $envConfig.ComposeFile logs -f --tail=100
        }
        
        "status" {
            Get-DeploymentStatus $Environment
        }
        
        "monitor" {
            Monitor-Deployment $Environment
        }
        
        "scale" {
            Write-Step "Scaling application to $Replicas replicas..."
            $envConfig = $CONFIG.Environments[$Environment]
            docker-compose -f $envConfig.ComposeFile up -d --scale app=$Replicas
        }
        
        "cleanup" {
            Write-Step "Cleaning up unused Docker resources..."
            docker system prune -f
            docker volume prune -f
            Cleanup-OldBackups $Environment
        }
        
        default {
            Write-Error-Step "Unknown action: $Action"
            Write-Host "Available actions: deploy, deploy-staging, deploy-prod, deploy-zero-downtime, health-check, rollback, backup, restore, logs, status, monitor, scale, cleanup"
            exit 1
        }
    }
    
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "✅ Operation completed successfully!" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Cyan
}
catch {
    Write-Error-Step "Script execution failed: $($_.Exception.Message)"
    exit 1
}
