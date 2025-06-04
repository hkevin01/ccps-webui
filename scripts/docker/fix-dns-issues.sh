#!/bin/bash
# Script to fix Docker DNS resolution issues between containers

set -e

echo "=== Docker DNS Resolution Fix Tool ==="

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

# Clear DNS cache in Docker
echo "Clearing Docker DNS cache..."
docker system prune -f --volumes

# Verify docker-compose.yml network configuration
echo "Verifying docker-compose.yml network configuration..."

# Create a hosts file to help with DNS resolution
echo "Creating hosts file for containers..."
mkdir -p docker/config
cat > docker/config/hosts << EOF
127.0.0.1 localhost
::1 localhost
# Add container hostnames
127.0.0.1 backend
127.0.0.1 frontend
127.0.0.1 postgres
EOF

# Rebuild and restart with explicit network configuration
echo "Rebuilding and restarting containers..."
$COMPOSE_CMD up -d --build --force-recreate

# Check connections between containers
echo "Testing connections between containers..."
echo "Testing frontend to backend connection..."
$COMPOSE_CMD exec frontend curl -v http://backend:8080/actuator/health || echo "Connection failed"

echo "=== Docker DNS Fix completed ==="
echo "If issues persist, try the following manual steps:"
echo "1. Check logs with: docker compose logs frontend"
echo "2. Update /etc/hosts on your host machine to include: 127.0.0.1 backend"
echo "3. Try pinging between containers: docker compose exec frontend ping backend"
echo "4. Restart Docker service: sudo systemctl restart docker"
