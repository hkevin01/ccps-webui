#!/bin/bash
# Script to fix port conflicts in Docker configuration

set -e

echo "=== Docker Port Conflict Fix Tool ==="

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: docker-compose or 'docker compose' is not installed."
    exit 1
fi

# Stop running containers
echo "Stopping existing containers..."
$COMPOSE_CMD down

# Check for processes using port 80
echo "Checking for processes using port 80..."
if command -v lsof &> /dev/null; then
    PORT_80_PROCESSES=$(lsof -i :80 -t 2>/dev/null)
    if [ -n "$PORT_80_PROCESSES" ]; then
        echo "The following processes are using port 80:"
        lsof -i :80
        
        echo "Would you like to stop these processes? (y/n)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "Stopping processes using port 80..."
            for pid in $PORT_80_PROCESSES; do
                echo "Stopping process $pid..."
                kill -15 "$pid" 2>/dev/null || echo "Failed to stop process $pid, you may need sudo."
            done
        else
            echo "Skipping process termination."
        fi
    else
        echo "No processes found using port 80."
    fi
else
    echo "lsof not found, skipping port check."
    echo "To check for processes using port 80, install lsof and run: lsof -i :80"
fi

# Check for processes using port 3000
echo "Checking for processes using port 3000..."
if command -v lsof &> /dev/null; then
    PORT_3000_PROCESSES=$(lsof -i :3000 -t 2>/dev/null)
    if [ -n "$PORT_3000_PROCESSES" ]; then
        echo "The following processes are using port 3000:"
        lsof -i :3000
        
        echo "Would you like to stop these processes? (y/n)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "Stopping processes using port 3000..."
            for pid in $PORT_3000_PROCESSES; do
                echo "Stopping process $pid..."
                kill -15 "$pid" 2>/dev/null || echo "Failed to stop process $pid, you may need sudo."
            done
        else
            echo "Skipping process termination."
        fi
    else
        echo "No processes found using port 3000."
    fi
fi

# Update docker-compose.yml to remove the port 80 mapping
echo "Updating docker-compose.yml to fix port conflict..."
sed -i 's/- "80:80"  # Also expose on default HTTP port/# Removed port 80 mapping due to conflict/' docker-compose.yml

# Clean up Docker network
echo "Cleaning up Docker networks..."
docker network prune -f

# Restart Docker services
echo "Restarting services with updated configuration..."
$COMPOSE_CMD up -d --build

echo "Port conflict fix complete!"
echo "The frontend should now be accessible at http://localhost:3000"

chmod +x /home/kevin/Projects/ccps-webui/scripts/docker/fix-port-conflict.sh
