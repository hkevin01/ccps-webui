#!/bin/bash
# Script to fix Docker DNS resolution issues by creating a fixed Nginx config

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

# Get backend container IP address
echo "Getting backend container IP address..."
BACKEND_IP=$($COMPOSE_CMD exec backend hostname -i 2>/dev/null || echo "172.18.0.3")
echo "Backend IP: $BACKEND_IP"

# Create a custom Nginx config with the IP address directly
echo "Creating custom Nginx configuration..."
mkdir -p docker/nginx
cat > docker/nginx/default.conf << EOF
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    
    # Enable CORS
    add_header Access-Control-Allow-Origin "*";
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE";
    add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
    
    # Use IP address directly instead of hostname
    location /api {
        proxy_pass http://${BACKEND_IP}:8080/api;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
    }
}
EOF

# Update docker-compose.yml to use custom Nginx config
echo "Updating docker-compose.yml to use custom Nginx config..."
sed -i '/container_name: frontend/a \    volumes:\n      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro' docker-compose.yml

# Restart frontend container
echo "Restarting frontend container..."
$COMPOSE_CMD stop frontend
$COMPOSE_CMD up -d frontend

# Check if frontend is working now
echo "Checking if frontend is accessible now..."
sleep 5
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000; then
    echo "Frontend is now accessible at http://localhost:3000!"
else
    echo "Frontend is still not accessible. Try the alternative approach..."
    
    # Alternative approach: Update the hosts file inside the container
    echo "Adding backend entry to hosts file inside frontend container..."
    $COMPOSE_CMD exec frontend sh -c "echo '$BACKEND_IP backend' >> /etc/hosts"
    
    # Restart Nginx inside the container
    echo "Restarting Nginx inside frontend container..."
    $COMPOSE_CMD exec frontend nginx -s reload
    
    # Wait and check again
    sleep 5
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000; then
        echo "Frontend is now accessible at http://localhost:3000!"
    else
        echo "Frontend is still not accessible. Try the following manual steps:"
        echo "1. Run: docker compose stop frontend"
        echo "2. Run: docker compose up -d frontend"
        echo "3. Run: docker compose exec frontend sh -c 'echo \"$BACKEND_IP backend\" >> /etc/hosts'"
        echo "4. Run: docker compose exec frontend nginx -s reload"
    fi
fi

chmod +x /home/kevin/Projects/ccps-webui/scripts/docker/fix-dns-issue.sh
