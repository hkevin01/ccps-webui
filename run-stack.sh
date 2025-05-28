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
    (cd backend && mvn package)
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

# Remove duplicate Spring Boot application classes to avoid multiple @SpringBootConfiguration errors
if [ -f backend/src/main/java/com/clr/ClrBackendApplication.java ] && [ -f backend/src/main/java/com/clr/ClrWebuiApplication.java ]; then
    echo "Removing duplicate Spring Boot application class: backend/src/main/java/com/clr/ClrBackendApplication.java"
    rm backend/src/main/java/com/clr/ClrBackendApplication.java
fi

# Print more focused information about multiple @SpringBootConfiguration errors
if grep -q "@SpringBootConfiguration" backend/target/surefire-reports/*.txt 2>/dev/null; then
    echo ""
    echo "==== Spring Boot Multiple @SpringBootConfiguration Error Detected ===="
    grep "@SpringBootConfiguration" backend/target/surefire-reports/*.txt 2>/dev/null || true
    echo ""
    echo "This usually means you have more than one main application class (e.g., ClrBackendApplication and ClrWebuiApplication)."
    echo "Remove or rename one so only a single @SpringBootConfiguration exists in your backend."
    echo "====================================================================="
fi

echo "Building images and starting all services..."
$COMPOSE_CMD up --build | tee "$LOG_FILE"
