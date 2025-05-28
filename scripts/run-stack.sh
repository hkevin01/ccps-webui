#!/bin/bash
# Script to build and run the full stack (backend, frontend, database) for the codebase

set -e

# Allow Ctrl-C to stop docker-compose and exit script gracefully
trap "echo 'Stopping services...'; exit 0" SIGINT

# Build backend JAR if Maven project exists
if [ -f backend/pom.xml ]; then
    echo "Cleaning previous Maven build..."
    (cd backend && mvn clean)
    echo "Building backend JAR with Maven..."
    if ! (cd backend && mvn package); then
        echo "Maven build failed. Please check the logs for errors."
        exit 1
    fi
fi

# Build frontend if package.json exists
if [ -f frontend/package.json ]; then
    echo "Installing frontend dependencies..."
    (cd frontend && npm install)
    echo "Building frontend..."
    (cd frontend && npm run build)
fi

# Check if docker-compose or docker compose is installed
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "docker-compose or 'docker compose' could not be found. Please install Docker Compose and try again."
    exit 1
fi

# Store output log in a dedicated logs directory
LOG_DIR="logs"
if [ ! -d "$LOG_DIR" ]; then
    mkdir "$LOG_DIR"
fi
LOG_FILE="$LOG_DIR/run-stack-output.log"

# Ensure docker-compose.yml exists, create a basic one if missing
if [ ! -f docker-compose.yml ]; then
    echo "docker-compose.yml not found. Creating a basic docker-compose.yml with MySQL, backend, and frontend services..."
    cat > docker-compose.yml <<EOF
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: clrdb
      MYSQL_USER: clruser
      MYSQL_PASSWORD: clrpass
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: .
      dockerfile: docker/Dockerfile.backend
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/clrdb
      SPRING_DATASOURCE_USERNAME: clruser
      SPRING_DATASOURCE_PASSWORD: clrpass
    ports:
      - "8080:8080"

  frontend:
    build:
      context: .
      dockerfile: docker/Dockerfile.frontend
    ports:
      - "3000:80"
    depends_on:
      - backend

volumes:
  db_data:
EOF
    echo "docker-compose.yml created."
fi

# Warn about multiple Spring Boot application classes
if [ -f backend/src/main/java/com/clr/ClrBackendApplication.java ] && [ -f backend/src/main/java/com/clr/ClrWebuiApplication.java ]; then
    echo ""
    echo "Warning: Multiple Spring Boot application classes detected."
    echo "Please ensure only one @SpringBootApplication class exists in the backend."
    echo "Example: Keep ClrBackendApplication.java and remove or refactor ClrWebuiApplication.java."
    echo ""
fi

# Validate environment variables
echo "Validating environment variables for database connection..."
if [ -z "$SPRING_DATASOURCE_URL" ] || [ -z "$SPRING_DATASOURCE_USERNAME" ] || [ -z "$SPRING_DATASOURCE_PASSWORD" ]; then
    echo "Error: Missing database connection environment variables."
    echo "Ensure SPRING_DATASOURCE_URL, SPRING_DATASOURCE_USERNAME, and SPRING_DATASOURCE_PASSWORD are set."
    exit 1
fi
echo "Database environment variables validation passed."

# Start Docker Compose services
echo "Starting Docker Compose services..."
if ! $COMPOSE_CMD up --build | tee "$LOG_FILE"; then
    echo "Docker Compose failed to start services. Check the logs at $LOG_FILE or run 'docker-compose logs' for more details."
    exit 1
fi

# Health checks
echo "Checking backend health..."
if ! curl -s http://localhost:8080/actuator/health | grep '"status":"UP"' > /dev/null; then
    echo "Backend health check failed. Ensure the backend service is running correctly."
    exit 1
fi
echo "Backend is healthy."

echo "Checking frontend health..."
if ! curl -s http://localhost:3000 > /dev/null; then
    echo "Frontend health check failed. Ensure the frontend service is running correctly."
    exit 1
fi
echo "Frontend is healthy."

echo ""
echo "If you encounter issues, check the following:"
echo "1. Backend build logs: backend/target/surefire-reports/"
echo "2. Docker logs: $LOG_FILE"
echo "3. Database connection: Ensure MySQL is running and accessible."
