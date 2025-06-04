#!/bin/bash
# Script to fix connection issues between Docker containers and host

set -e

echo "=== Docker Connection Fix Tool ==="

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: docker-compose or 'docker compose' is not installed."
    exit 1
fi

# Stop all running containers
echo "Stopping all services..."
$COMPOSE_CMD down

# Clean up Docker network and cache
echo "Cleaning up Docker networks and cache..."
docker network prune -f
docker system prune -f --volumes

# Check if port 3000 is already in use
echo "Checking if port 3000 is already in use..."
if command -v lsof &> /dev/null; then
    if lsof -i :3000 -t &> /dev/null; then
        echo "Warning: Port 3000 is already in use by another process."
        echo "Process using port 3000:"
        lsof -i :3000
        echo "Consider stopping this process or changing the frontend port in docker-compose.yml"
    else
        echo "Port 3000 is available."
    fi
else
    echo "lsof not found, skipping port check."
fi

# Check Docker engine status
echo "Checking Docker engine status..."
docker info > /dev/null || { echo "Error: Docker engine is not running or you don't have permissions."; exit 1; }

# Restart Docker daemon (requires sudo)
echo "Would you like to restart the Docker daemon? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Restarting Docker daemon..."
    sudo systemctl restart docker
    echo "Waiting for Docker to start..."
    sleep 5
fi

# Rebuild all containers
echo "Rebuilding and starting all containers..."
$COMPOSE_CMD up -d --build --force-recreate

# Wait for containers to start
echo "Waiting for containers to start..."
sleep 10

# Check container status
echo "Container status:"
$COMPOSE_CMD ps

# Check logs
echo "Frontend container logs:"
$COMPOSE_CMD logs frontend | tail -n 30

# Test connectivity from host to frontend
echo "Testing connectivity to frontend..."
curl -v http://localhost:3000 2>&1 | grep -E "HTTP|connection|Connected" || echo "Cannot connect to frontend container"

echo "Testing connectivity to backend..."
curl -v http://localhost:8080/actuator/health 2>&1 | grep -E "HTTP|connection|Connected" || echo "Cannot connect to backend container"

# Networking diagnostics
echo "=== Network Diagnostics ==="
echo "Docker networks:"
docker network ls

echo "Network inspection for clr-network:"
docker network inspect clr-network

echo "If you still can't connect to the frontend, try:"
echo "1. Make sure no other service is using port 3000"
echo "2. Check your firewall settings: sudo ufw status"
echo "3. Try changing the frontend port mapping in docker-compose.yml (e.g., 3001:80)"
echo "4. Access the frontend directly from the container: docker exec -it frontend curl http://localhost"
echo "5. Try a different browser or incognito window"

# Make script executable
chmod +x /home/kevin/Projects/clr-webui/scripts/docker/fix-connection-issue.sh
