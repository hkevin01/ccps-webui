#!/bin/bash
# Script to view Docker logs for debugging

set -e

# Check for docker compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: docker-compose or 'docker compose' is not installed."
    exit 1
fi

# Display status of all containers
echo "=== Container Status ==="
$COMPOSE_CMD ps

# Display logs for a specific service or all services
if [ -z "$1" ]; then
    # No argument provided, show all logs
    echo "=== All Logs ==="
    $COMPOSE_CMD logs
else
    # Show logs for the specified service
    echo "=== Logs for $1 ==="
    $COMPOSE_CMD logs "$1"
fi

# Display possible startup issues
echo "=== Checking for common startup issues ==="

# Check if backend container is running
BACKEND_RUNNING=$($COMPOSE_CMD ps backend | grep -c "Up" || echo "0")
if [ "$BACKEND_RUNNING" -eq "0" ]; then
    echo "Backend container is not running. Checking for errors:"
    $COMPOSE_CMD logs backend | grep -i "error\|exception\|failed"
    
    echo "Checking PostgreSQL connection..."
    $COMPOSE_CMD exec postgres pg_isready -U clruser || echo "PostgreSQL is not ready or accessible"
fi

echo "To restart the stack, run: docker compose down && docker compose up -d"
