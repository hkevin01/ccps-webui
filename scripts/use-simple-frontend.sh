#!/bin/bash
# Script to switch to a simpler frontend deployment without proxy requirements

set -e

echo "=== Switching to Simple Frontend Deployment ==="

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: docker-compose or 'docker compose' is not installed."
    exit 1
fi

# Copy the simple Dockerfile to the main one
echo "Creating simplified frontend Dockerfile..."
cat > docker/Dockerfile.frontend << 'EOF'
# Build stage
FROM node:18-alpine as build
WORKDIR /app

# Copy package files first for better layer caching
COPY frontend/package.json ./

# Install dependencies
RUN npm install && \
    npm install --save react-router-dom@6.20.1 chart.js@4.4.1 react-chartjs-2@5.2.0 && \
    npm install --save ol@7.5.1 ol-layerswitcher@4.1.1 proj4@2.9.2

# Configure API endpoint to explicitly use the host IP instead of container networking
RUN echo "REACT_APP_API_URL=http://localhost:8080/api" > .env

# Copy source code after dependencies are installed
COPY frontend/src ./src
COPY frontend/public ./public
COPY frontend/tsconfig.json ./tsconfig.json

# Create styles directory for OpenLayers CSS if it doesn't exist
RUN mkdir -p src/styles && \
    if [ ! -f src/styles/map-styles.css ]; then \
        echo '@import "ol/ol.css"; \
        @import "ol-layerswitcher/dist/ol-layerswitcher.css"; \
        .map-container { width: 100%; height: 400px; border: 1px solid #ddd; border-radius: 4px; }' > src/styles/map-styles.css; \
    fi

# Update API service to use environment variable
RUN if [ -f src/services/api.ts ]; then \
        sed -i "s|const API_BASE_URL = .*|const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';|g" src/services/api.ts; \
    fi

# Build the app
RUN npm run build

# Production stage - simple static file server
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html

# Simplified nginx config that doesn't need to proxy to backend
RUN echo 'server { \
    listen 80; \
    listen [::]:80; \
    server_name localhost; \
    \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
    \
    # Health check endpoint \
    location /health { \
        access_log off; \
        return 200 "healthy\n"; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Rebuild and restart the frontend container
echo "Rebuilding and restarting frontend container..."
$COMPOSE_CMD stop frontend
$COMPOSE_CMD rm -f frontend
$COMPOSE_CMD up -d --build frontend

echo "Frontend container has been rebuilt with a simplified configuration."
echo "It should now be accessible at http://localhost:3000"
echo ""
echo "IMPORTANT: The frontend now expects the backend to be accessible at http://localhost:8080/api"
echo "Make sure the backend is running and exposed at that address."

chmod +x /home/kevin/Projects/ccps-webui/scripts/use-simple-frontend.sh
