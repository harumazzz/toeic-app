# TOEIC Backend Kubernetes Quick Start Guide
# This script provides a quick setup for common Kubernetes operations

param(
    [Parameter(Position = 0)]
    [ValidateSet("setup", "build", "deploy", "status", "logs", "restart", "scale", "cleanup", "backup", "restore")]
    [string]$Action = "setup",
    
    [Parameter(Position = 1)]
    [int]$Replicas = 3,
    
    [Parameter(Position = 2)]
    [string]$BackupName = ""
)

# Configuration
$NAMESPACE = "toeic-app"
$IMAGE_NAME = "toeic-backend:latest"

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

function Test-Prerequisites {
    Write-StatusMessage "Checking prerequisites..." "Info"
    
    # Check kubectl
    try {
        kubectl version --client --short | Out-Null
        Write-StatusMessage "✓ kubectl is available" "Success"
    } catch {
        Write-StatusMessage "✗ kubectl is not installed or not available" "Error"
        return $false
    }
    
    # Check Docker
    try {
        docker --version | Out-Null
        Write-StatusMessage "✓ Docker is available" "Success"
    } catch {
        Write-StatusMessage "✗ Docker is not installed or not available" "Error"
        return $false
    }
    
    # Check cluster connection
    try {
        kubectl cluster-info | Out-Null
        Write-StatusMessage "✓ Kubernetes cluster is accessible" "Success"
    } catch {
        Write-StatusMessage "✗ Cannot connect to Kubernetes cluster" "Error"
        return $false
    }
    
    return $true
}

function Invoke-Setup {
    Write-StatusMessage "Setting up TOEIC Backend environment..." "Info"
    
    if (-not (Test-Prerequisites)) {
        Write-StatusMessage "Prerequisites check failed. Please install missing tools." "Error"
        exit 1
    }
    
    Write-StatusMessage "Environment setup completed!" "Success"
    Write-StatusMessage "Next steps:" "Info"
    Write-StatusMessage "1. Run: .\quick-start.ps1 build" "Info"
    Write-StatusMessage "2. Run: .\quick-start.ps1 deploy" "Info"
}

function Invoke-Build {
    Write-StatusMessage "Building Docker image..." "Info"
    
    Set-Location $PSScriptRoot\..
    
    docker build -t $IMAGE_NAME .
    if ($LASTEXITCODE -eq 0) {
        Write-StatusMessage "✓ Docker image built successfully" "Success"
        
        # If using kind, load the image
        if (kubectl config current-context | Select-String "kind") {
            Write-StatusMessage "Loading image into kind cluster..." "Info"
            kind load docker-image $IMAGE_NAME
        }
        
        # If using minikube, set docker env
        if (kubectl config current-context | Select-String "minikube") {
            Write-StatusMessage "Note: Make sure to run 'minikube docker-env' before building" "Warning"
        }
    } else {
        Write-StatusMessage "✗ Failed to build Docker image" "Error"
        exit 1
    }
}

function Invoke-Deploy {
    Write-StatusMessage "Deploying TOEIC Backend to Kubernetes..." "Info"
    
    Set-Location $PSScriptRoot
    
    # Run the main deployment script
    ..\deploy-k8s.ps1 deploy
    
    if ($LASTEXITCODE -eq 0) {
        Write-StatusMessage "✓ Deployment completed successfully!" "Success"
        Show-AccessInfo
    } else {
        Write-StatusMessage "✗ Deployment failed" "Error"
        exit 1
    }
}

function Show-Status {
    Write-StatusMessage "Current deployment status:" "Info"
    
    Write-Host "`n=== Namespace ===" -ForegroundColor Yellow
    kubectl get namespace $NAMESPACE
    
    Write-Host "`n=== Pods ===" -ForegroundColor Yellow
    kubectl get pods -n $NAMESPACE
    
    Write-Host "`n=== Services ===" -ForegroundColor Yellow
    kubectl get services -n $NAMESPACE
    
    Write-Host "`n=== Deployments ===" -ForegroundColor Yellow
    kubectl get deployments -n $NAMESPACE
    
    Write-Host "`n=== HPA ===" -ForegroundColor Yellow
    kubectl get hpa -n $NAMESPACE
    
    Write-Host "`n=== PVCs ===" -ForegroundColor Yellow
    kubectl get pvc -n $NAMESPACE
}

function Show-Logs {
    Write-StatusMessage "Showing backend application logs..." "Info"
    kubectl logs -f deployment/toeic-backend -n $NAMESPACE
}

function Invoke-Restart {
    Write-StatusMessage "Restarting backend deployment..." "Info"
    kubectl rollout restart deployment/toeic-backend -n $NAMESPACE
    kubectl rollout status deployment/toeic-backend -n $NAMESPACE
    Write-StatusMessage "✓ Restart completed" "Success"
}

function Invoke-Scale {
    Write-StatusMessage "Scaling backend to $Replicas replicas..." "Info"
    kubectl scale deployment toeic-backend --replicas=$Replicas -n $NAMESPACE
    kubectl rollout status deployment/toeic-backend -n $NAMESPACE
    Write-StatusMessage "✓ Scaling completed" "Success"
}

function Show-AccessInfo {
    Write-StatusMessage "Getting access information..." "Info"
    
    try {
        $NodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
        
        Write-Host "`n=== Access URLs ===" -ForegroundColor Green
        Write-Host "Backend API: http://$NodeIP:30080" -ForegroundColor Cyan
        Write-Host "API Health: http://$NodeIP:30080/health" -ForegroundColor Cyan
        Write-Host "Prometheus: http://$NodeIP:30090" -ForegroundColor Cyan
        Write-Host "Grafana: http://$NodeIP:30030 (admin/admin123)" -ForegroundColor Cyan
        
        Write-Host "`n=== Useful Commands ===" -ForegroundColor Yellow
        Write-Host "Port forward backend: kubectl port-forward service/toeic-backend-service 8000:8000 -n $NAMESPACE" -ForegroundColor White
        Write-Host "View logs: kubectl logs -f deployment/toeic-backend -n $NAMESPACE" -ForegroundColor White
        Write-Host "Shell into pod: kubectl exec -it deployment/toeic-backend -n $NAMESPACE -- /bin/sh" -ForegroundColor White
        
    } catch {
        Write-StatusMessage "Could not retrieve node IP. Check cluster status." "Warning"
    }
}

function Invoke-Cleanup {
    Write-StatusMessage "Cleaning up deployment..." "Warning"
    Write-Host "This will delete the entire TOEIC Backend deployment. Continue? (y/N): " -NoNewline -ForegroundColor Red
    $confirmation = Read-Host
    
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        kubectl delete namespace $NAMESPACE
        Write-StatusMessage "✓ Cleanup completed" "Success"
    } else {
        Write-StatusMessage "Cleanup cancelled" "Info"
    }
}

function Invoke-Backup {
    Write-StatusMessage "Creating database backup..." "Info"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $jobName = "manual-backup-$timestamp"
    
    kubectl create job --from=cronjob/postgres-backup $jobName -n $NAMESPACE
    Write-StatusMessage "✓ Backup job '$jobName' created" "Success"
    Write-StatusMessage "Monitor with: kubectl logs job/$jobName -n $NAMESPACE" "Info"
}

function Invoke-Restore {
    if (-not $BackupName) {
        Write-StatusMessage "Please specify backup name: .\quick-start.ps1 restore backup_20241215_120000.sql" "Error"
        return
    }
    
    Write-StatusMessage "Restoring from backup: $BackupName" "Warning"
    Write-Host "This will restore the database. Continue? (y/N): " -NoNewline -ForegroundColor Red
    $confirmation = Read-Host
    
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        $podName = kubectl get pods -n $NAMESPACE -l app=postgres -o jsonpath='{.items[0].metadata.name}'
        kubectl exec -it $podName -n $NAMESPACE -- psql -U toeicuser -d toeicdb -c "\i /backups/$BackupName"
        Write-StatusMessage "✓ Restore completed" "Success"
    } else {
        Write-StatusMessage "Restore cancelled" "Info"
    }
}

# Main execution
Set-Location $PSScriptRoot

switch ($Action) {
    "setup" { Invoke-Setup }
    "build" { Invoke-Build }
    "deploy" { Invoke-Deploy }
    "status" { Show-Status }
    "logs" { Show-Logs }
    "restart" { Invoke-Restart }
    "scale" { Invoke-Scale }
    "cleanup" { Invoke-Cleanup }
    "backup" { Invoke-Backup }
    "restore" { Invoke-Restore }
    default {
        Write-Host @"
TOEIC Backend Kubernetes Quick Start

Usage: .\quick-start.ps1 <action> [options]

Actions:
  setup     - Check prerequisites and setup environment
  build     - Build Docker image
  deploy    - Deploy to Kubernetes
  status    - Show deployment status
  logs      - Show backend application logs
  restart   - Restart backend deployment
  scale     - Scale backend deployment (specify replicas)
  cleanup   - Delete entire deployment
  backup    - Create manual database backup
  restore   - Restore from backup (specify backup file name)

Examples:
  .\quick-start.ps1 setup
  .\quick-start.ps1 build
  .\quick-start.ps1 deploy
  .\quick-start.ps1 scale 5
  .\quick-start.ps1 restore backup_20241215_120000.sql

"@
    }
}
