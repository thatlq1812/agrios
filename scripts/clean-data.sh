#!/bin/bash

# Agrios Clean Data Script
# Use this when you need to start fresh or fix PostgreSQL version conflicts

set -e

echo "========================================="
echo "Agrios - Clean Data Script"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will delete all data!"
echo "   - All databases will be wiped"
echo "   - All Redis data will be cleared"
echo "   - All containers will be stopped"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Step 1: Stopping all services..."
docker-compose down

echo ""
echo "Step 2: Removing all volumes..."
docker-compose down -v

echo ""
echo "Step 3: Removing specific volumes (if they exist)..."
docker volume rm agrios_postgres_data 2>/dev/null && echo "✓ Removed postgres_data" || echo "• postgres_data not found"
docker volume rm agrios_redis_data 2>/dev/null && echo "✓ Removed redis_data" || echo "• redis_data not found"

echo ""
echo "Step 4: Pruning unused Docker resources..."
docker volume prune -f

echo ""
echo "========================================="
echo "✓ Clean complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. docker-compose up -d"
echo "  2. sleep 15"
echo "  3. bash scripts/init-services.sh"
echo ""
