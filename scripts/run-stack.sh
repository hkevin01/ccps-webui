#!/bin/bash
# Script to build and run the full stack (backend, frontend, database) for the codebase

set -e

# Default environment variables for local development if not set
export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://localhost:3306/clrdb}"
export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-clruser}"
export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-clrpass}"

# Allow Ctrl-C to stop docker-compose and exit script gracefully
trap "echo 'Stopping services...'; exit 0" SIGINT

# Build all Gradle projects (including backend) from the root
if [ -f build.gradle ] || [ -f build.gradle.kts ]; then
    echo "Cleaning previous Gradle build (root)..."
    if [ ! -x ./gradlew ]; then
        echo "Making gradlew executable..."
        chmod +x ./gradlew
    fi
    ./gradlew clean
    echo "Building all Gradle projects (root)..."
    if ! ./gradlew build; then
        echo "Gradle build failed. Please check the logs for errors."
        exit 1
    fi
fi

# Ensure backend JAR exists for Docker build, or skip check if not needed
BACKEND_JAR_PATH="backend/build/libs"
JAR_NEEDED=true

# Check if Dockerfile.backend expects a JAR
if grep -q 'COPY backend/build/libs/.*\.jar' docker/Dockerfile.backend 2>/dev/null; then
    JAR_NEEDED=true
else
    JAR_NEEDED=false
fi

if [ "$JAR_NEEDED" = true ]; then
    if ! ls "$BACKEND_JAR_PATH"/*.jar 1> /dev/null 2>&1; then
        echo "Warning: No backend JAR found in $BACKEND_JAR_PATH. The Docker build may fail if it expects a JAR."
        echo "Check your backend/build.gradle for the 'bootJar' or 'jar' task."
        # Continue anyway, do not exit
    fi
fi

# Build frontend if package.json exists
if [ -f frontend/package.json ]; then
    echo "Installing frontend dependencies..."
    (cd frontend && npm install)
    echo "Checking for frontend/public/index.html..."
    if [ ! -f frontend/public/index.html ]; then
        echo "Error: 'frontend/public/index.html' is missing. Create this file to allow the React build to succeed."
        exit 1
    fi
    # Check for required React dependencies
    if ! grep -q '"react-router-dom"' frontend/package.json; then
        echo "Adding 'react-router-dom@6' to frontend dependencies (compatible with Node 18)..."
        (cd frontend && npm install react-router-dom@6)
    fi
    # Check for react-hook-form if referenced in code
    if grep -rq "react-hook-form" frontend/src; then
        if ! grep -q '"react-hook-form"' frontend/package.json; then
            echo "Adding 'react-hook-form' to frontend dependencies..."
            (cd frontend && npm install react-hook-form)
        fi
    fi
    echo "Building frontend..."
    if ! (cd frontend && npm run build); then
        echo "Frontend build failed. Check that 'frontend/public/index.html' exists and your React app is set up correctly."
        echo "If you see 'Module not found: Error: Can't resolve ...', ensure all required dependencies are listed in package.json and installed."
        exit 1
    fi
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
    echo "If running with Docker Compose, these are set in docker-compose.yml for the backend service."
    echo "If running locally, export them before running this script, e.g.:"
    echo "  export SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/clrdb"
    echo "  export SPRING_DATASOURCE_USERNAME=clruser"
    echo "  export SPRING_DATASOURCE_PASSWORD=clrpass"
    echo ""
    echo "To run with default local values, you can use:"
    echo "  SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/clrdb \\"
    echo "  SPRING_DATASOURCE_USERNAME=clruser \\"
    echo "  SPRING_DATASOURCE_PASSWORD=clrpass \\"
    echo "  ./scripts/run-stack.sh"
    exit 1
fi
echo "Database environment variables validation passed."

# Start Docker Compose services (backend, frontend, and database)
echo "Starting all services (backend, frontend, database) using Docker Compose..."
if ! $COMPOSE_CMD up --build -d; then
    echo "Docker Compose failed to start services. Check the logs or run 'docker-compose logs' for more details."
    exit 1
fi

# Wait for backend to be healthy
echo "Waiting for backend to be healthy..."
for i in {1..30}; do
    if curl -s http://localhost:8080/actuator/health | grep -q '"status":"UP"'; then
        echo "Backend is healthy."
        break
    fi
    sleep 2
    echo -n "."
done

# Wait for frontend to be available
echo "Waiting for frontend to be available..."
for i in {1..30}; do
    if curl -s http://localhost:3000 > /dev/null; then
        echo "Frontend is healthy."
        break
    fi
    sleep 2
    echo -n "."
done

echo ""
echo "------------------------------------------------------------"
echo "All services are running in Docker Compose."
echo "Backend:   http://localhost:8080"
echo "Frontend:  http://localhost:3000"
echo "Database:  MySQL on localhost:3306 (user: clruser, pass: clrpass, db: clrdb)"
echo "------------------------------------------------------------"
echo ""

# Open frontend in Firefox (if available)
if command -v firefox &> /dev/null; then
    echo "Opening frontend in Firefox..."
    firefox http://localhost:3000 &
fi

echo "To stop all services, run: $COMPOSE_CMD down"
wait
