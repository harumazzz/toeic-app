#!/bin/bash

# Production deployment script for TOEIC App Backend

set -e

echo "🚀 Starting production deployment..."

# Check if required environment variables are set
check_env_vars() {
    local required_vars=(
        "TOKEN_SYMMETRIC_KEY"
        "CLOUDINARY_URL"
        "DB_PASSWORD"
    )
    
    echo "📋 Checking required environment variables..."
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "❌ Error: $var is not set"
            echo "Please set $var in your .env file"
            exit 1
        fi
    done
    echo "✅ All required environment variables are set"
}

# Create .env file from template if it doesn't exist
setup_env() {
    if [ ! -f .env ]; then
        echo "📄 Creating .env file from template..."
        cp .env.example .env
        echo "⚠️  Please edit .env file with your production values before continuing"
        echo "❌ Exiting... Edit .env file and run this script again"
        exit 1
    fi
}

# Build and deploy with Docker
deploy_docker() {
    echo "🐳 Building and deploying with Docker..."
    
    # Pull latest changes
    echo "📥 Pulling latest changes..."
    # git pull origin main
    
    # Stop existing services
    echo "🛑 Stopping existing services..."
    docker-compose -f docker-compose.prod.yml down || true
    
    # Remove old images
    echo "🗑️  Cleaning up old images..."
    docker image prune -f || true
    
    # Build and start services
    echo "🔨 Building and starting services..."
    docker-compose -f docker-compose.prod.yml up --build -d
    
    # Wait for services to be healthy
    echo "🏥 Waiting for services to be healthy..."
    timeout 60 bash -c 'until docker-compose -f docker-compose.prod.yml ps | grep -q "healthy"; do sleep 2; done'
    
    echo "✅ Services are healthy!"
}

# Deploy with Redis cache
deploy_with_redis() {
    echo "🔴 Deploying with Redis cache..."
    docker-compose -f docker-compose.prod.yml --profile with-redis up --build -d
}

# Deploy with Nginx reverse proxy
deploy_with_nginx() {
    echo "🌐 Deploying with Nginx reverse proxy..."
    docker-compose -f docker-compose.prod.yml --profile with-nginx up --build -d
}

# Deploy everything (app + redis + nginx)
deploy_full() {
    echo "🎯 Deploying full stack (app + redis + nginx)..."
    docker-compose -f docker-compose.prod.yml --profile with-redis --profile with-nginx up --build -d
}

# Show logs
show_logs() {
    echo "📋 Showing application logs..."
    docker-compose -f docker-compose.prod.yml logs -f app
}

# Show status
show_status() {
    echo "📊 Service status:"
    docker-compose -f docker-compose.prod.yml ps
    
    echo ""
    echo "🏥 Health checks:"
    curl -f http://localhost:8000/health || echo "❌ Health check failed"
    
    echo ""
    echo "📈 Metrics:"
    curl -s http://localhost:8000/metrics | head -10 || echo "❌ Metrics not available"
}

# Backup database
backup_db() {
    echo "💾 Creating database backup..."
    timestamp=$(date +%Y%m%d_%H%M%S)
    docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U root -d toeic_db > "backups/prod_backup_${timestamp}.sql"
    echo "✅ Backup created: backups/prod_backup_${timestamp}.sql"
}

# Restore database
restore_db() {
    if [ -z "$1" ]; then
        echo "❌ Usage: $0 restore <backup_file>"
        exit 1
    fi
    
    echo "🔄 Restoring database from $1..."
    docker-compose -f docker-compose.prod.yml exec -T postgres psql -U root -d toeic_db < "$1"
    echo "✅ Database restored from $1"
}

# Main script logic
case "${1:-deploy}" in
    "check")
        setup_env
        check_env_vars
        ;;
    "deploy")
        setup_env
        check_env_vars
        deploy_docker
        show_status
        ;;
    "deploy-redis")
        setup_env
        check_env_vars
        deploy_with_redis
        show_status
        ;;
    "deploy-nginx")
        setup_env
        check_env_vars
        deploy_with_nginx
        show_status
        ;;
    "deploy-full")
        setup_env
        check_env_vars
        deploy_full
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "backup")
        backup_db
        ;;
    "restore")
        restore_db "$2"
        ;;
    "stop")
        echo "🛑 Stopping all services..."
        docker-compose -f docker-compose.prod.yml down
        ;;
    "restart")
        echo "🔄 Restarting services..."
        docker-compose -f docker-compose.prod.yml restart
        ;;
    *)
        echo "Usage: $0 {deploy|deploy-redis|deploy-nginx|deploy-full|logs|status|backup|restore|stop|restart|check}"
        echo ""
        echo "Commands:"
        echo "  check        - Check environment setup"
        echo "  deploy       - Deploy basic app + database"
        echo "  deploy-redis - Deploy with Redis cache"
        echo "  deploy-nginx - Deploy with Nginx proxy"
        echo "  deploy-full  - Deploy everything"
        echo "  logs         - Show application logs"
        echo "  status       - Show service status"
        echo "  backup       - Create database backup"
        echo "  restore      - Restore database from backup"
        echo "  stop         - Stop all services"
        echo "  restart      - Restart all services"
        exit 1
        ;;
esac
