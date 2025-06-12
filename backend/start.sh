#!/bin/bash

# Smart startup script for TOEIC Backend
# Automatically detects environment and configures accordingly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 TOEIC Backend Smart Startup${NC}"
echo "=================================="

# Detect environment
detect_environment() {
    if [ ! -z "$PORT" ]; then
        echo -e "${GREEN}✅ Cloud platform detected (PORT=$PORT)${NC}"
        export SERVER_ADDRESS="0.0.0.0:$PORT"
        export GIN_MODE="release"
        return 0
    fi
    
    if [ ! -z "$HEROKU_APP_NAME" ]; then
        echo -e "${GREEN}✅ Heroku detected${NC}"
        export GIN_MODE="release"
        return 0
    fi
    
    if [ ! -z "$RAILWAY_ENVIRONMENT" ]; then
        echo -e "${GREEN}✅ Railway detected${NC}"
        export GIN_MODE="release"
        return 0
    fi
    
    if [ ! -z "$DIGITALOCEAN_APP_ID" ]; then
        echo -e "${GREEN}✅ DigitalOcean App Platform detected${NC}"
        export GIN_MODE="release"
        return 0
    fi
    
    if [ -f "/.dockerenv" ]; then
        echo -e "${GREEN}✅ Docker environment detected${NC}"
        export GIN_MODE="release"
        return 0
    fi
    
    echo -e "${YELLOW}⚠️  Local development environment detected${NC}"
    export GIN_MODE="debug"
    return 1
}

# Check required environment variables
check_required_vars() {
    echo -e "${BLUE}📋 Checking required environment variables...${NC}"
    
    local required_vars=(
        "TOKEN_SYMMETRIC_KEY"
        "DB_HOST"
        "DB_USER"
        "DB_PASSWORD"
        "DB_NAME"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing required environment variables:${NC}"
        for var in "${missing_vars[@]}"; do
            echo -e "${RED}   - $var${NC}"
        done
        echo ""
        echo -e "${YELLOW}💡 Set these in your .env file or environment variables${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All required environment variables are set${NC}"
}

# Wait for database
wait_for_database() {
    echo -e "${BLUE}🔌 Waiting for database connection...${NC}"
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if pg_isready -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Database is ready${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}⏳ Attempt $attempt/$max_attempts - waiting for database...${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ Database connection timeout${NC}"
    exit 1
}

# Run database migrations
run_migrations() {
    echo -e "${BLUE}🔄 Running database migrations...${NC}"
    
    # Check if migrate tool exists
    if command -v migrate > /dev/null 2>&1; then
        migrate -path db/migrations -database "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:${DB_PORT:-5432}/$DB_NAME?sslmode=disable" up
        echo -e "${GREEN}✅ Migrations completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Migrate tool not found, skipping migrations${NC}"
    fi
}

# Display configuration
show_config() {
    echo -e "${BLUE}📊 Current Configuration:${NC}"
    echo "  Environment: ${GIN_MODE}"
    echo "  Server Address: ${SERVER_ADDRESS:-auto}"
    echo "  Database Host: ${DB_HOST}"
    echo "  Database Name: ${DB_NAME}"
    echo "  Cache Enabled: ${CACHE_ENABLED:-true}"
    echo "  Rate Limiting: ${RATE_LIMIT_ENABLED:-true}"
    echo ""
}

# Main execution
main() {
    # Load .env file if it exists and we're not in a cloud environment
    if [ -f ".env" ] && [ -z "$PORT" ]; then
        echo -e "${BLUE}📄 Loading .env file...${NC}"
        export $(cat .env | grep -v '^#' | xargs)
    fi
    
    # Detect environment
    detect_environment
    is_production=$?
    
    # Check required variables
    check_required_vars
    
    # Show configuration
    show_config
    
    # Wait for database (in production/container environments)
    if [ $is_production -eq 0 ]; then
        wait_for_database
        run_migrations
    fi
    
    # Start the application
    echo -e "${GREEN}🚀 Starting TOEIC Backend...${NC}"
    echo "=================================="
    
    exec ./main "$@"
}

# Run main function
main "$@"
