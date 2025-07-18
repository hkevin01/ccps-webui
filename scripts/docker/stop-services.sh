#!/bin/bash
# Script to stop all Docker services and provide status information

set -e

echo "Stopping all Docker services for CCPS WebUI..."

# Check for docker compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: docker-compose or 'docker compose' is not installed."
    exit 1
fi

# Get current container status before stopping
echo "Current container status before stopping:"
$COMPOSE_CMD ps

# Stop all services
echo "Stopping all services..."
$COMPOSE_CMD down

# Verify all containers are stopped
echo "Verifying all containers are stopped..."
RUNNING_CONTAINERS=$($COMPOSE_CMD ps -q 2>/dev/null | wc -l)

if [ "$RUNNING_CONTAINERS" -eq "0" ]; then
    echo "Success: All Docker containers have been stopped."
else
    echo "Warning: Some containers may still be running. Current status:"
    $COMPOSE_CMD ps
fi

# Check for any dangling volumes that might need cleaning
echo "Checking for dangling Docker volumes..."
DANGLING_VOLUMES=$(docker volume ls -qf dangling=true 2>/dev/null | wc -l)

if [ "$DANGLING_VOLUMES" -gt "0" ]; then
    echo "Note: You have $DANGLING_VOLUMES dangling Docker volumes."
    echo "To clean them up, you can run: docker volume prune"
fi

echo "All services have been stopped."
echo "To restart services, run: ./scripts/run-stack.sh"
