#!/bin/bash
# Script to restart Docker services with clean state

set -e

echo "Restarting Docker services with clean state..."

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: docker-compose or 'docker compose' is not installed."
    exit 1
fi

# Stop and remove existing containers
echo "Stopping existing containers..."
$COMPOSE_CMD down

# Prune Docker resources
echo "Pruning Docker resources..."
docker system prune -f

# Rebuild and start containers
echo "Rebuilding and starting containers..."
$COMPOSE_CMD up -d --build

# Wait for containers to start
echo "Waiting for services to start..."
sleep 10

# Check container status
echo "Container status:"
$COMPOSE_CMD ps

# Show logs
echo "Backend logs:"
$COMPOSE_CMD logs backend | tail -n 20

echo "Frontend logs (if available):"
$COMPOSE_CMD logs frontend 2>/dev/null | tail -n 20 || echo "Frontend logs not available yet."

echo "Services restarted. You can access:"
echo "- Backend: http://localhost:8080"
echo "- Frontend: http://localhost:3000"

chmod +x /home/kevin/Projects/ccps-webui/scripts/restart-docker.sh
