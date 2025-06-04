#!/bin/bash
# Script to fix Docker configuration issues, particularly the Nginx configuration problem

set -e

echo "=== Docker Configuration Fix Tool ==="

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

# Update Nginx config in Dockerfile.frontend
echo "Updating Nginx configuration in Dockerfile.frontend..."
cat > docker/Dockerfile.frontend << 'EOF'
# Build stage
FROM node:18-alpine as build
WORKDIR /app

# Copy package files first for better layer caching
COPY frontend/package.json frontend/package-lock.json* ./

# Install dependencies with specific versions that are compatible with Node 18
RUN npm install && \
    # Install specific dependencies for maps and charts
    npm install --save react-router-dom@6.20.1 chart.js@4.4.1 react-chartjs-2@5.2.0 && \
    npm install --save ol@7.5.1 proj4@2.9.2

# Copy source code after dependencies are installed
COPY frontend/src ./src
COPY frontend/public ./public
COPY frontend/tsconfig.json ./tsconfig.json

# Create a styles directory if it doesn't exist
RUN mkdir -p src/styles

# Add OpenLayers CSS if it doesn't exist
RUN if [ ! -f src/styles/map-styles.css ]; then \
    echo '@import "ol/ol.css"; \
.map-container { \
  width: 100%; \
  height: 400px; \
  border: 1px solid #ddd; \
  border-radius: 4px; \
}' > src/styles/map-styles.css; \
fi

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine
# Copy built app
COPY --from=build /app/build /usr/share/nginx/html

# Add nginx configuration with proper service name
RUN echo 'server { \
    listen 80; \
    listen [::]:80; \
    server_name localhost; \
    \
    # Enable CORS \
    add_header Access-Control-Allow-Origin "*"; \
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE"; \
    add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization"; \
    \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
    \
    # Proxy API requests to backend using the service name from docker-compose.yml \
    location /api { \
        proxy_pass http://clr-webui-backend:8080/api; \
        proxy_http_version 1.1; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
    } \
    \
    # Health check endpoint \
    location /health { \
        access_log off; \
        return 200 "healthy\n"; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Create a basic health check script
RUN echo '#!/bin/sh\n\
curl -f http://localhost/health || exit 1' > /healthcheck.sh && \
    chmod +x /healthcheck.sh

EXPOSE 80
HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD ["/healthcheck.sh"]
CMD ["nginx", "-g", "daemon off;"]
EOF

echo "Updating Docker network configuration in docker-compose.yml..."
# Make sure both containers are on the same network
sed -i 's/container_name: clr-webui-backend/container_name: clr-webui-backend\n    networks:\n      - clr-network/' docker-compose.yml
sed -i 's/container_name: clr-webui-frontend/container_name: clr-webui-frontend\n    networks:\n      - clr-network/' docker-compose.yml

# Update networks section
sed -i '/networks:/,$d' docker-compose.yml
cat >> docker-compose.yml << 'EOF'
networks:
  default:
    driver: bridge
  clr-network:
    driver: bridge

volumes:
  postgres_data:
EOF

echo "Rebuilding and starting containers..."
$COMPOSE_CMD up -d --build

echo "Waiting for services to start..."
sleep 10

echo "Checking container status..."
$COMPOSE_CMD ps

echo "Checking frontend logs for errors..."
$COMPOSE_CMD logs frontend | grep -i error

echo "Checking backend logs for errors..."
$COMPOSE_CMD logs backend | grep -i error

echo "Testing frontend connectivity..."
curl -v http://localhost:3000/health 2>&1 | grep "200 OK" && echo "Frontend is accessible!" || echo "Frontend is not accessible!"

echo "Configuration fix complete. Try accessing the frontend at http://localhost:3000"
chmod +x /home/kevin/Projects/clr-webui/scripts/fix-docker-config.sh
