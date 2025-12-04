#!/bin/bash

# Agrios Services Initialization Script
# This script initializes all services after docker-compose up

set -e  # Exit on error

echo "========================================="
echo "Agrios Services Initialization"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if container is running
check_container() {
    if docker ps --format '{{.Names}}' | grep -q "^$1$"; then
        echo -e "${GREEN}✓ $1 is running${NC}"
        return 0
    else
        echo -e "${RED}✗ $1 is not running${NC}"
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local container=$1
    local max_attempts=30
    local attempt=1
    
    echo -n "Waiting for $container to be ready"
    while [ $attempt -le $max_attempts ]; do
        if docker exec $container echo "ready" >/dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done
    echo -e " ${RED}✗ Timeout${NC}"
    return 1
}

echo "Step 1: Checking if services are running..."
echo "-------------------------------------------"

check_container "agrios-postgres" || { echo -e "${RED}Error: PostgreSQL is not running${NC}"; exit 1; }
check_container "agrios-redis" || { echo -e "${RED}Error: Redis is not running${NC}"; exit 1; }
check_container "agrios-user-service" || { echo -e "${RED}Error: User Service is not running${NC}"; exit 1; }
check_container "agrios-article-service" || { echo -e "${RED}Error: Article Service is not running${NC}"; exit 1; }
check_container "agrios-gateway" || { echo -e "${RED}Error: Gateway is not running${NC}"; exit 1; }

echo ""
echo "Step 2: Waiting for services to be ready..."
echo "-------------------------------------------"

wait_for_service "agrios-postgres"
wait_for_service "agrios-redis"
wait_for_service "agrios-user-service"
wait_for_service "agrios-article-service"

echo ""
echo "Step 3: Running database migrations..."
echo "-------------------------------------------"

# Check if migrations have already been applied
echo -n "Checking User Service migrations... "
if docker exec agrios-postgres psql -U postgres -d agrios_user -c "SELECT 1 FROM users LIMIT 1;" >/dev/null 2>&1; then
    echo -e "${YELLOW}Already applied${NC}"
else
    echo -e "${GREEN}Running migrations${NC}"
    docker exec agrios-user-service sh -c "cd /app && psql postgresql://\$DB_USER:\$DB_PASSWORD@\$DB_HOST:\$DB_PORT/\$DB_NAME < migrations/001_create_users_table.sql" || {
        echo -e "${RED}✗ User Service migration failed${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ User Service migrations completed${NC}"
fi

echo -n "Checking Article Service migrations... "
if docker exec agrios-postgres psql -U postgres -d agrios_article -c "SELECT 1 FROM articles LIMIT 1;" >/dev/null 2>&1; then
    echo -e "${YELLOW}Already applied${NC}"
else
    echo -e "${GREEN}Running migrations${NC}"
    docker exec agrios-article-service sh -c "cd /app && psql postgresql://\$DB_USER:\$DB_PASSWORD@\$DB_HOST:\$DB_PORT/\$DB_NAME < migrations/001_create_articles_table.sql" || {
        echo -e "${RED}✗ Article Service migration failed${NC}"
        exit 1
    }
    echo -e "${GREEN}✓ Article Service migrations completed${NC}"
fi

echo ""
echo "Step 4: Verifying services..."
echo "-------------------------------------------"

# Test gateway health
echo -n "Testing Gateway health endpoint... "
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Gateway is healthy${NC}"
else
    echo -e "${RED}✗ Gateway health check failed${NC}"
    echo -e "${YELLOW}Note: Gateway might still be starting up. Try again in a few seconds.${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}Initialization Complete!${NC}"
echo "========================================="
echo ""
echo "Services are ready to use:"
echo "  - Gateway:         http://localhost:8080"
echo "  - User Service:    gRPC on localhost:50051"
echo "  - Article Service: gRPC on localhost:50052"
echo "  - PgAdmin:         http://localhost:5050 (optional)"
echo ""
echo "Next steps:"
echo "  1. Test API: curl http://localhost:8080/health"
echo "  2. See docs/DEPLOYMENT.md for API examples"
echo "  3. Use docs/GRPC_COMMANDS.md for gRPC testing"
echo ""
