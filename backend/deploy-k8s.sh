#!/bin/bash

# TOEIC Backend Kubernetes Deployment Script
# This script deploys the entire TOEIC backend application to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting TOEIC Backend Kubernetes Deployment${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if Docker is available for building image
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Function to check if namespace exists
check_namespace() {
    if kubectl get namespace toeic-app &> /dev/null; then
        echo -e "${YELLOW}⚠️  Namespace 'toeic-app' already exists${NC}"
    else
        echo -e "${GREEN}✅ Creating namespace 'toeic-app'${NC}"
        kubectl apply -f k8s/namespace.yaml
    fi
}

# Function to build Docker image
build_docker_image() {
    echo -e "${BLUE}🔨 Building Docker image...${NC}"
    docker build -t toeic-backend:latest .
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
}

# Function to deploy resources
deploy_resources() {
    echo -e "${BLUE}📦 Deploying Kubernetes resources...${NC}"
    
    # Deploy in order
    echo -e "${YELLOW}📝 Applying ConfigMaps and Secrets...${NC}"
    kubectl apply -f k8s/configmap.yaml
    
    echo -e "${YELLOW}🔐 Applying RBAC...${NC}"
    kubectl apply -f k8s/rbac.yaml
    
    echo -e "${YELLOW}🗄️  Deploying PostgreSQL...${NC}"
    kubectl apply -f k8s/postgres.yaml
    
    echo -e "${YELLOW}📦 Deploying Redis...${NC}"
    kubectl apply -f k8s/redis.yaml
    
    echo -e "${YELLOW}⏳ Waiting for database services to be ready...${NC}"
    kubectl wait --for=condition=available --timeout=300s deployment/postgres -n toeic-app
    kubectl wait --for=condition=available --timeout=300s deployment/redis -n toeic-app
    
    echo -e "${YELLOW}🏃 Deploying backend application...${NC}"
    kubectl apply -f k8s/backend.yaml
    
    echo -e "${YELLOW}📊 Deploying monitoring stack...${NC}"
    kubectl apply -f k8s/exporters.yaml
    kubectl apply -f k8s/monitoring.yaml
    kubectl apply -f k8s/grafana.yaml
    
    echo -e "${YELLOW}📈 Deploying HPA...${NC}"
    kubectl apply -f k8s/hpa.yaml
    
    echo -e "${YELLOW}🔌 Deploying NodePort services...${NC}"
    kubectl apply -f k8s/nodeports.yaml
    
    echo -e "${YELLOW}💾 Deploying backup CronJob...${NC}"
    kubectl apply -f k8s/backup.yaml
}

# Function to check deployment status
check_deployment() {
    echo -e "${BLUE}🔍 Checking deployment status...${NC}"
    
    echo -e "${YELLOW}Waiting for backend deployment to be ready...${NC}"
    kubectl wait --for=condition=available --timeout=300s deployment/toeic-backend -n toeic-app
    
    echo -e "${GREEN}✅ All deployments are ready!${NC}"
    
    echo -e "${BLUE}📋 Deployment Summary:${NC}"
    kubectl get pods -n toeic-app
    echo ""
    kubectl get services -n toeic-app
    echo ""
    
    # Get NodePort information
    echo -e "${BLUE}🌐 Access Information:${NC}"
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    echo -e "${GREEN}Backend API: http://$NODE_IP:30080${NC}"
    echo -e "${GREEN}Prometheus: http://$NODE_IP:30090${NC}"
    echo -e "${GREEN}Grafana: http://$NODE_IP:30030 (admin/admin123)${NC}"
}

# Main deployment flow
main() {
    echo -e "${BLUE}Starting deployment process...${NC}"
    
    # Change to the backend directory
    cd "$(dirname "$0")"
    
    check_namespace
    build_docker_image
    deploy_resources
    check_deployment
    
    echo -e "${GREEN}🎉 TOEIC Backend deployment completed successfully!${NC}"
    echo -e "${YELLOW}💡 Tip: Use 'kubectl logs -f deployment/toeic-backend -n toeic-app' to view application logs${NC}"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "delete")
        echo -e "${RED}🗑️  Deleting TOEIC Backend deployment...${NC}"
        kubectl delete namespace toeic-app
        echo -e "${GREEN}✅ Deployment deleted${NC}"
        ;;
    "status")
        echo -e "${BLUE}📊 Deployment Status:${NC}"
        kubectl get all -n toeic-app
        ;;
    "logs")
        echo -e "${BLUE}📝 Backend Logs:${NC}"
        kubectl logs -f deployment/toeic-backend -n toeic-app
        ;;
    *)
        echo "Usage: $0 [deploy|delete|status|logs]"
        echo "  deploy: Deploy the application (default)"
        echo "  delete: Delete the entire deployment"
        echo "  status: Show deployment status"
        echo "  logs: Show backend application logs"
        exit 1
        ;;
esac
