# TOEIC Backend Kubernetes Deployment Script (PowerShell)
# This script deploys the entire TOEIC backend application to Kubernetes

param(
    [Parameter(Position = 0)]
    [ValidateSet("deploy", "delete", "status", "logs")]
    [string]$Action = "deploy"
)

# Colors for output
$Colors = @{
    Red    = "Red"
    Green  = "Green"
    Yellow = "Yellow"
    Blue   = "Blue"
    White  = "White"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

Write-ColorOutput "🚀 Starting TOEIC Backend Kubernetes Deployment" "Blue"

# Check if kubectl is available
try {
    kubectl version --client --short | Out-Null
} catch {
    Write-ColorOutput "❌ kubectl is not installed or not in PATH" "Red"
    exit 1
}

# Check if Docker is available for building image
try {
    docker --version | Out-Null
} catch {
    Write-ColorOutput "❌ Docker is not installed or not in PATH" "Red"
    exit 1
}

# Function to check if namespace exists
function Test-Namespace {
    try {
        kubectl get namespace toeic-app 2>$null | Out-Null
        Write-ColorOutput "⚠️  Namespace 'toeic-app' already exists" "Yellow"
    } catch {
        Write-ColorOutput "✅ Creating namespace 'toeic-app'" "Green"
        kubectl apply -f k8s/namespace.yaml
    }
}

# Function to build Docker image
function Build-DockerImage {
    Write-ColorOutput "🔨 Building Docker image..." "Blue"
    docker build -t toeic-backend:latest .
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Docker image built successfully" "Green"
    } else {
        Write-ColorOutput "❌ Failed to build Docker image" "Red"
        exit 1
    }
}

# Function to deploy resources
function Deploy-Resources {
    Write-ColorOutput "📦 Deploying Kubernetes resources..." "Blue"
    
    # Deploy in order
    Write-ColorOutput "📝 Applying ConfigMaps and Secrets..." "Yellow"
    kubectl apply -f k8s/configmap.yaml
    
    Write-ColorOutput "🔐 Applying RBAC..." "Yellow"
    kubectl apply -f k8s/rbac.yaml
    
    Write-ColorOutput "🗄️  Deploying PostgreSQL..." "Yellow"
    kubectl apply -f k8s/postgres.yaml
    
    Write-ColorOutput "📦 Deploying Redis..." "Yellow"
    kubectl apply -f k8s/redis.yaml
    
    Write-ColorOutput "⏳ Waiting for database services to be ready..." "Yellow"
    kubectl wait --for=condition=available --timeout=300s deployment/postgres -n toeic-app
    kubectl wait --for=condition=available --timeout=300s deployment/redis -n toeic-app
    
    Write-ColorOutput "🏃 Deploying backend application..." "Yellow"
    kubectl apply -f k8s/backend.yaml
    
    Write-ColorOutput "📊 Deploying monitoring stack..." "Yellow"
    kubectl apply -f k8s/exporters.yaml
    kubectl apply -f k8s/monitoring.yaml
    kubectl apply -f k8s/grafana.yaml
    
    Write-ColorOutput "📈 Deploying HPA..." "Yellow"
    kubectl apply -f k8s/hpa.yaml
    
    Write-ColorOutput "🔌 Deploying NodePort services..." "Yellow"
    kubectl apply -f k8s/nodeports.yaml
    
    Write-ColorOutput "💾 Deploying backup CronJob..." "Yellow"
    kubectl apply -f k8s/backup.yaml
}

# Function to check deployment status
function Test-Deployment {
    Write-ColorOutput "🔍 Checking deployment status..." "Blue"
    
    Write-ColorOutput "Waiting for backend deployment to be ready..." "Yellow"
    kubectl wait --for=condition=available --timeout=300s deployment/toeic-backend -n toeic-app
    
    Write-ColorOutput "✅ All deployments are ready!" "Green"
    
    Write-ColorOutput "📋 Deployment Summary:" "Blue"
    kubectl get pods -n toeic-app
    Write-Host ""
    kubectl get services -n toeic-app
    Write-Host ""
    
    # Get NodePort information
    Write-ColorOutput "🌐 Access Information:" "Blue"
    $NodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
    Write-ColorOutput "Backend API: http://$NodeIP:30080" "Green"
    Write-ColorOutput "Prometheus: http://$NodeIP:30090" "Green"
    Write-ColorOutput "Grafana: http://$NodeIP:30030 (admin/admin123)" "Green"
}

# Main deployment flow
function Invoke-Deploy {
    Write-ColorOutput "Starting deployment process..." "Blue"
    
    # Change to the script directory
    Set-Location $PSScriptRoot
    
    Test-Namespace
    Build-DockerImage
    Deploy-Resources
    Test-Deployment
    
    Write-ColorOutput "🎉 TOEIC Backend deployment completed successfully!" "Green"
    Write-ColorOutput "💡 Tip: Use 'kubectl logs -f deployment/toeic-backend -n toeic-app' to view application logs" "Yellow"
}

# Handle script actions
switch ($Action) {
    "deploy" {
        Invoke-Deploy
    }
    "delete" {
        Write-ColorOutput "🗑️  Deleting TOEIC Backend deployment..." "Red"
        kubectl delete namespace toeic-app
        Write-ColorOutput "✅ Deployment deleted" "Green"
    }
    "status" {
        Write-ColorOutput "📊 Deployment Status:" "Blue"
        kubectl get all -n toeic-app
    }
    "logs" {
        Write-ColorOutput "📝 Backend Logs:" "Blue"
        kubectl logs -f deployment/toeic-backend -n toeic-app
    }
    default {
        Write-Host "Usage: .\deploy-k8s.ps1 [deploy|delete|status|logs]"
        Write-Host "  deploy: Deploy the application (default)"
        Write-Host "  delete: Delete the entire deployment"
        Write-Host "  status: Show deployment status"
        Write-Host "  logs: Show backend application logs"
        exit 1
    }
}
