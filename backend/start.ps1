# Smart startup script for TOEIC Backend (PowerShell)
# Automatically detects environment and configures accordingly

param(
    [string[]]$Arguments = @()
)

function Write-Info($message) {
    Write-Host "🚀 $message" -ForegroundColor Blue
}

function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "⚠️ $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor Red
}

function Detect-Environment {
    Write-Info "Detecting environment..."
    
    # Check for cloud platform environment variables
    if ($env:PORT) {
        Write-Success "Cloud platform detected (PORT=$($env:PORT))"
        $env:SERVER_ADDRESS = "0.0.0.0:$($env:PORT)"
        $env:GIN_MODE = "release"
        return $true
    }
    
    if ($env:HEROKU_APP_NAME) {
        Write-Success "Heroku detected"
        $env:GIN_MODE = "release"
        return $true
    }
    
    if ($env:RAILWAY_ENVIRONMENT) {
        Write-Success "Railway detected"
        $env:GIN_MODE = "release"
        return $true
    }
    
    if ($env:DIGITALOCEAN_APP_ID) {
        Write-Success "DigitalOcean App Platform detected"
        $env:GIN_MODE = "release"
        return $true
    }
    
    # Check if running in Docker
    if (Test-Path "/.dockerenv") {
        Write-Success "Docker environment detected"
        $env:GIN_MODE = "release"
        return $true
    }
    
    Write-Warning "Local development environment detected"
    $env:GIN_MODE = "debug"
    return $false
}

function Check-RequiredVars {
    Write-Info "Checking required environment variables..."
    
    $requiredVars = @(
        "TOKEN_SYMMETRIC_KEY",
        "DB_HOST",
        "DB_USER", 
        "DB_PASSWORD",
        "DB_NAME"
    )
    
    $missingVars = @()
    
    foreach ($var in $requiredVars) {
        $value = [Environment]::GetEnvironmentVariable($var)
        if ([string]::IsNullOrEmpty($value)) {
            $missingVars += $var
        }
    }
    
    if ($missingVars.Count -gt 0) {
        Write-Error "Missing required environment variables:"
        foreach ($var in $missingVars) {
            Write-Host "   - $var" -ForegroundColor Red
        }
        Write-Host ""
        Write-Warning "Set these in your .env file or environment variables"
        exit 1
    }
    
    Write-Success "All required environment variables are set"
}

function Wait-ForDatabase {
    Write-Info "Waiting for database connection..."
    
    $maxAttempts = 30
    $attempt = 1
    $dbPort = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
    
    while ($attempt -le $maxAttempts) {
        try {
            # Try to connect to the database
            $connectionString = "Host=$($env:DB_HOST);Port=$dbPort;Username=$($env:DB_USER);Password=$($env:DB_PASSWORD);Database=$($env:DB_NAME)"
            
            # Simple test using pg_isready if available, otherwise skip
            if (Get-Command pg_isready -ErrorAction SilentlyContinue) {
                $result = & pg_isready -h $env:DB_HOST -p $dbPort -U $env:DB_USER -d $env:DB_NAME 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Database is ready"
                    return
                }
            } else {
                Write-Warning "pg_isready not available, skipping database wait"
                return
            }
        } catch {
            # Continue trying
        }
        
        Write-Warning "Attempt $attempt/$maxAttempts - waiting for database..."
        Start-Sleep 2
        $attempt++
    }
    
    Write-Error "Database connection timeout"
    exit 1
}

function Run-Migrations {
    Write-Info "Running database migrations..."
    
    # Check if migrate tool exists
    if (Get-Command migrate -ErrorAction SilentlyContinue) {
        $dbPort = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
        $connectionString = "postgresql://$($env:DB_USER):$($env:DB_PASSWORD)@$($env:DB_HOST):$dbPort/$($env:DB_NAME)?sslmode=disable"
        
        & migrate -path db/migrations -database $connectionString up
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Migrations completed"
        } else {
            Write-Warning "Migration failed, continuing anyway"
        }
    } else {
        Write-Warning "Migrate tool not found, skipping migrations"
    }
}

function Show-Config {
    Write-Info "Current Configuration:"
    $serverAddr = if ($env:SERVER_ADDRESS) { $env:SERVER_ADDRESS } else { "auto" }
    $cacheEnabled = if ($env:CACHE_ENABLED) { $env:CACHE_ENABLED } else { "true" }
    $rateLimitEnabled = if ($env:RATE_LIMIT_ENABLED) { $env:RATE_LIMIT_ENABLED } else { "true" }
    
    Write-Host "  Environment: $($env:GIN_MODE)"
    Write-Host "  Server Address: $serverAddr"
    Write-Host "  Database Host: $($env:DB_HOST)"
    Write-Host "  Database Name: $($env:DB_NAME)"
    Write-Host "  Cache Enabled: $cacheEnabled"
    Write-Host "  Rate Limiting: $rateLimitEnabled"
    Write-Host ""
}

function Load-EnvFile {
    if (Test-Path ".env" -and -not $env:PORT) {
        Write-Info "Loading .env file..."
        
        Get-Content ".env" | Where-Object { $_ -notmatch "^#" -and $_ -match "=" } | ForEach-Object {
            $parts = $_ -split "=", 2
            if ($parts.Length -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()
                
                # Remove quotes if present
                $value = $value -replace '^"(.*)"$', '$1'
                $value = $value -replace "^'(.*)'$", '$1'
                
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }
    }
}

# Main execution
function Main {
    Write-Host "🚀 TOEIC Backend Smart Startup" -ForegroundColor Blue
    Write-Host "==================================" -ForegroundColor Blue
    
    # Load .env file if it exists and we're not in a cloud environment
    Load-EnvFile
    
    # Detect environment
    $isProduction = Detect-Environment
    
    # Check required variables
    Check-RequiredVars
    
    # Show configuration
    Show-Config
    
    # Wait for database and run migrations (in production/container environments)
    if ($isProduction) {
        Wait-ForDatabase
        Run-Migrations
    }
    
    # Start the application
    Write-Success "Starting TOEIC Backend..."
    Write-Host "==================================" -ForegroundColor Blue
    
    # Check if main.exe or main exists
    $executable = ""
    if (Test-Path "main.exe") {
        $executable = ".\main.exe"
    } elseif (Test-Path "main") {
        $executable = ".\main"
    } else {
        Write-Error "Executable not found. Please build the application first with 'go build -o main.exe'"
        exit 1
    }
    
    # Start the application with any additional arguments
    if ($Arguments.Count -gt 0) {
        & $executable @Arguments
    } else {
        & $executable
    }
}

# Run main function
Main
