# Production deployment script for TOEIC App Backend (Windows PowerShell)

param(
    [Parameter(Position=0)]
    [ValidateSet("check", "deploy", "deploy-redis", "deploy-nginx", "deploy-full", "logs", "status", "backup", "restore", "stop", "restart")]
    [string]$Command = "deploy",
    
    [Parameter(Position=1)]
    [string]$BackupFile = ""
)

$ErrorActionPreference = "Stop"

function Write-Step($message) {
    Write-Host "🚀 $message" -ForegroundColor Green
}

function Write-Error-Step($message) {
    Write-Host "❌ $message" -ForegroundColor Red
}

function Write-Warning-Step($message) {
    Write-Host "⚠️ $message" -ForegroundColor Yellow
}

function Check-EnvVars {
    Write-Step "Checking required environment variables..."
    
    $requiredVars = @(
        "TOKEN_SYMMETRIC_KEY",
        "CLOUDINARY_URL", 
        "DB_PASSWORD"
    )
    
    foreach ($var in $requiredVars) {
        $value = [Environment]::GetEnvironmentVariable($var)
        if ([string]::IsNullOrEmpty($value)) {
            # Check if it's in .env file
            if (Test-Path ".env") {
                $envContent = Get-Content ".env"
                $found = $envContent | Where-Object { $_ -match "^$var=" }
                if (-not $found) {
                    Write-Error-Step "Environment variable $var is not set"
                    Write-Host "Please set $var in your .env file"
                    exit 1
                }
            } else {
                Write-Error-Step "Environment variable $var is not set and no .env file found"
                exit 1
            }
        }
    }
    Write-Host "✅ All required environment variables are set" -ForegroundColor Green
}

function Setup-Env {
    if (-not (Test-Path ".env")) {
        Write-Step "Creating .env file from template..."
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Warning-Step "Please edit .env file with your production values before continuing"
            Write-Error-Step "Exiting... Edit .env file and run this script again"
            exit 1
        } else {
            Write-Error-Step ".env.example file not found. Please create it first."
            exit 1
        }
    }
}

function Deploy-Docker {
    Write-Step "Building and deploying with Docker..."
    
    # Stop existing services
    Write-Step "Stopping existing services..."
    try {
        docker-compose -f docker-compose.prod.yml down
    } catch {
        Write-Warning-Step "No existing services to stop"
    }
    
    # Remove old images
    Write-Step "Cleaning up old images..."
    try {
        docker image prune -f
    } catch {
        Write-Warning-Step "Failed to clean up old images"
    }
    
    # Build and start services
    Write-Step "Building and starting services..."
    docker-compose -f docker-compose.prod.yml up --build -d
    
    # Wait for services to be healthy
    Write-Step "Waiting for services to be healthy..."
    $timeout = 60
    $elapsed = 0
    do {
        Start-Sleep 2
        $elapsed += 2
        $status = docker-compose -f docker-compose.prod.yml ps --format json | ConvertFrom-Json
        $healthy = $status | Where-Object { $_.Health -eq "healthy" }
    } while ($elapsed -lt $timeout -and -not $healthy)
    
    if ($healthy) {
        Write-Host "✅ Services are healthy!" -ForegroundColor Green
    } else {
        Write-Warning-Step "Services may not be fully healthy yet"
    }
}

function Deploy-WithRedis {
    Write-Step "Deploying with Redis cache..."
    docker-compose -f docker-compose.prod.yml --profile with-redis up --build -d
}

function Deploy-WithNginx {
    Write-Step "Deploying with Nginx reverse proxy..."
    docker-compose -f docker-compose.prod.yml --profile with-nginx up --build -d
}

function Deploy-Full {
    Write-Step "Deploying full stack (app + redis + nginx)..."
    docker-compose -f docker-compose.prod.yml --profile with-redis --profile with-nginx up --build -d
}

function Show-Logs {
    Write-Step "Showing application logs..."
    docker-compose -f docker-compose.prod.yml logs -f app
}

function Show-Status {
    Write-Step "Service status:"
    docker-compose -f docker-compose.prod.yml ps
    
    Write-Host ""
    Write-Step "Health checks:"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing
        Write-Host "✅ Health check passed" -ForegroundColor Green
    } catch {
        Write-Error-Step "Health check failed"
    }
    
    Write-Host ""
    Write-Step "Metrics:"
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/metrics" -UseBasicParsing
        $response.Content.Split("`n")[0..9] | ForEach-Object { Write-Host $_ }
    } catch {
        Write-Error-Step "Metrics not available"
    }
}

function Backup-Database {
    Write-Step "Creating database backup..."
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "backups/prod_backup_${timestamp}.sql"
    
    # Ensure backups directory exists
    if (-not (Test-Path "backups")) {
        New-Item -ItemType Directory -Path "backups"
    }
    
    docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U root -d toeic_db > $backupFile
    Write-Host "✅ Backup created: $backupFile" -ForegroundColor Green
}

function Restore-Database($backupFile) {
    if ([string]::IsNullOrEmpty($backupFile)) {
        Write-Error-Step "Usage: .\deploy.ps1 restore <backup_file>"
        exit 1
    }
    
    if (-not (Test-Path $backupFile)) {
        Write-Error-Step "Backup file not found: $backupFile"
        exit 1
    }
    
    Write-Step "Restoring database from $backupFile..."
    Get-Content $backupFile | docker-compose -f docker-compose.prod.yml exec -T postgres psql -U root -d toeic_db
    Write-Host "✅ Database restored from $backupFile" -ForegroundColor Green
}

function Stop-Services {
    Write-Step "Stopping all services..."
    docker-compose -f docker-compose.prod.yml down
}

function Restart-Services {
    Write-Step "Restarting services..."
    docker-compose -f docker-compose.prod.yml restart
}

# Main script logic
switch ($Command) {
    "check" {
        Setup-Env
        Check-EnvVars
    }
    "deploy" {
        Setup-Env
        Check-EnvVars
        Deploy-Docker
        Show-Status
    }
    "deploy-redis" {
        Setup-Env
        Check-EnvVars
        Deploy-WithRedis
        Show-Status
    }
    "deploy-nginx" {
        Setup-Env
        Check-EnvVars
        Deploy-WithNginx
        Show-Status
    }
    "deploy-full" {
        Setup-Env
        Check-EnvVars
        Deploy-Full
        Show-Status
    }
    "logs" {
        Show-Logs
    }
    "status" {
        Show-Status
    }
    "backup" {
        Backup-Database
    }
    "restore" {
        Restore-Database $BackupFile
    }
    "stop" {
        Stop-Services
    }
    "restart" {
        Restart-Services
    }
    default {
        Write-Host @"
Usage: .\deploy.ps1 {check|deploy|deploy-redis|deploy-nginx|deploy-full|logs|status|backup|restore|stop|restart}

Commands:
  check        - Check environment setup
  deploy       - Deploy basic app + database
  deploy-redis - Deploy with Redis cache
  deploy-nginx - Deploy with Nginx proxy
  deploy-full  - Deploy everything
  logs         - Show application logs
  status       - Show service status
  backup       - Create database backup
  restore      - Restore database from backup
  stop         - Stop all services
  restart      - Restart all services
"@
        exit 1
    }
}
