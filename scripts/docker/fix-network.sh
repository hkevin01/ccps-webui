#!/bin/bash
# Script to fix Docker network issues

set -e

echo "Fixing Docker network issues..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running or you don't have permission to use it."
    echo "Please start Docker or run this script with sudo if needed."
    exit 1
fi

# Function to check if a container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^$1$"
}

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: docker-compose or 'docker compose' is not installed."
    exit 1
fi

# Get status of all containers
echo "Current container status:"
$COMPOSE_CMD ps

# Check if the frontend container is running
if container_running "ccps-webui-frontend-1"; then
    echo "Frontend container is running. Checking configuration..."
    
    # Check port mapping
    PORT_MAPPING=$(docker port ccps-webui-frontend-1 80)
    echo "Port mapping: $PORT_MAPPING"
    
    # Check if the container is healthy
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' ccps-webui-frontend-1 2>/dev/null || echo "No health check")
    echo "Health status: $HEALTH_STATUS"
    
    # Check if the nginx process is running in the container
    echo "Checking nginx process:"
    docker exec ccps-webui-frontend-1 ps aux | grep nginx || echo "Nginx not found"
    
    # Test the nginx configuration
    echo "Testing nginx configuration:"
    docker exec ccps-webui-frontend-1 nginx -t 2>&1 || echo "Nginx configuration test failed"
    
    # Check connectivity from inside the container
    echo "Testing internal connectivity:"
    docker exec ccps-webui-frontend-1 curl -s http://localhost/health || echo "Internal connectivity failed"
    
    # Restart the frontend container
    echo "Restarting frontend container..."
    $COMPOSE_CMD restart frontend
    
    # Wait for it to be ready
    echo "Waiting for frontend to be ready..."
    sleep 5
    
    # Check if accessible now
    echo "Testing external connectivity:"
    curl -v http://localhost:3000 2>&1 || echo "External connectivity failed"
else
    echo "Frontend container is not running. Starting all services..."
    $COMPOSE_CMD up -d
fi

echo "Network diagnostics completed. If you're still having issues:"
echo "1. Try running: docker network inspect ccps-webui_default"
echo "2. Check if port 3000 is already in use: lsof -i :3000"
echo "3. Try changing the frontend port in docker-compose.yml, e.g. to 3001:80"
echo "4. Restart Docker with: sudo systemctl restart docker"
echo "5. Run the full stack again: ./scripts/run-stack.sh"

chmod +x /home/kevin/Projects/ccps-webui/scripts/fix-network.sh
