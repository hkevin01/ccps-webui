#!/bin/bash
# Improved script to build and run the full stack (backend, frontend, database)
# This script adjusts permissions on key Gradle files and directories,
# and if app.jar is missing after the build, it attempts an additional bootJar build.
# It then helps diagnose issues with missing JARs.

set -e

##################################
# 1. Check Operating System      #
##################################
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        echo "Warning: This script is designed for Ubuntu Linux. Detected OS: $NAME."
    else
        echo "Ubuntu Linux detected: $PRETTY_NAME."
    fi
else
    echo "Warning: Unable to determine your operating system (missing /etc/os-release). Proceeding with caution."
fi

#####################################
# 2. Check for Required Dependencies #
#####################################
# Check for Java
if ! command -v java &> /dev/null; then
    echo "Error: Java is not installed. Please install a JDK (version 11 or higher) and try again."
    exit 1
fi

# Check for curl
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install curl and try again."
    exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check for docker-compose or docker compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "Error: docker-compose or 'docker compose' is not installed. Please install Docker Compose."
    exit 1
fi

# Check for unzip. If missing, attempt to install it (requires sudo on Ubuntu)
if ! command -v unzip &> /dev/null; then
    echo "Unzip command not found. Installing unzip..."
    sudo apt-get update -y && sudo apt-get install unzip -y
fi

#########################################
# 3. Adjust Permissions for Key Files   #
#########################################

# Ensure the Gradle wrapper (gradlew) is executable
if [ -f "./gradlew" ]; then
    if [ ! -x "./gradlew" ]; then
        echo "Making gradlew executable..."
        chmod +x ./gradlew
    else
        echo "gradlew is already executable."
    fi
else
    echo "Warning: gradlew not found in the project root."
fi

# Ensure main Gradle build files are readable
if [ -f "build.gradle" ]; then
    echo "Setting read permissions for build.gradle..."
    chmod a+r build.gradle
elif [ -f "build.gradle.kts" ]; then
    echo "Setting read permissions for build.gradle.kts..."
    chmod a+r build.gradle.kts
fi

# Ensure settings.gradle (if exists) has correct permissions
if [ -f "settings.gradle" ]; then
    echo "Setting read permissions for settings.gradle..."
    chmod a+r settings.gradle
fi

# Find common Gradle-related files and adjust their permissions
echo "Fixing permissions for common Gradle files..."
find . -maxdepth 2 -type f \( -name "build.gradle" -o -name "build.gradle.kts" -o -name "settings.gradle" -o -name "gradlew" \) -exec chmod a+rx {} \;

# Ensure Gradle wrapper directory permissions are proper
if [ -d "gradle" ]; then
    echo "Setting recursive permissions in gradle directory..."
    chmod -R a+rwX gradle
fi

# Adjust permissions recursively for the entire backend directory
echo "Setting recursive permissions in the backend directory..."
chmod -R a+rwX backend

# Ensure the backend build/libs directory is accessible
BACKEND_LIBS_DIR="backend/build/libs"
if [ -d "$BACKEND_LIBS_DIR" ]; then
    echo "Setting recursive read/write/execute permissions in $BACKEND_LIBS_DIR..."
    chmod -R a+rwX "$BACKEND_LIBS_DIR"
else
    echo "Directory $BACKEND_LIBS_DIR does not exist yet; it will be created if needed."
fi

#######################################
# 4. Validate and Export Environment Variables #
#######################################
export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://localhost:3306/ccpsdb}"
export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-ccpsuser}"
export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-ccpspass}"

if [ -z "$SPRING_DATASOURCE_URL" ] || [ -z "$SPRING_DATASOURCE_USERNAME" ] || [ -z "$SPRING_DATASOURCE_PASSWORD" ]; then
    echo "Error: Missing required environment variables for database connection."
    exit 1
fi

echo "Database connection environment variables:"
echo "  SPRING_DATASOURCE_URL: $SPRING_DATASOURCE_URL"
echo "  SPRING_DATASOURCE_USERNAME: $SPRING_DATASOURCE_USERNAME"
# (Password is not printed for security)

#############################################################
# 5. Check for Multiple Spring Boot Application Classes    #
#############################################################
echo "Scanning backend for Spring Boot application classes (@SpringBootApplication)..."
SPRING_CLASSES=$(grep -R "@SpringBootApplication" backend/src/main/java 2>/dev/null || echo "")
APP_COUNT=$(echo "$SPRING_CLASSES" | grep -c "@SpringBootApplication")  # Fixed extra parenthesis here

if [ "$APP_COUNT" -gt 1 ]; then
    echo "Warning: Multiple Spring Boot application classes detected:"
    echo "$SPRING_CLASSES"
    echo "Please ensure only one @SpringBootApplication class exists in the backend."
    echo "Example: Keep CcpsBackendApplication.java and remove or refactor CcpsWebuiApplication.java."
else
    echo "Single Spring Boot application class detected. Proceeding..."
fi

####################################
# 6. Build Gradle Projects         #
####################################

if [ -f build.gradle ] || [ -f build.gradle.kts ]; then
    echo "Cleaning previous Gradle build at root..."
    ./gradlew clean
    echo "Building all Gradle projects..."
    if ! ./gradlew build; then
        echo "Gradle build failed. Please review the log output."
        exit 1
    fi
fi

###########################################################
# 7. Check & Validate Backend JAR for Docker Build        #
###########################################################
BACKEND_JAR_PATH="backend/build/libs"
JAR_NEEDED=false

# Determine if Dockerfile.backend expects a JAR file
if grep -q 'COPY backend/build/libs/.*\.jar' docker/Dockerfile.backend 2>/dev/null; then
    JAR_NEEDED=true
fi

if [ "$JAR_NEEDED" = true ]; then
    if [ ! -d "$BACKEND_JAR_PATH" ]; then
        echo "Directory $BACKEND_JAR_PATH does not exist. Creating it..."
        mkdir -p "$BACKEND_JAR_PATH"
        chmod -R a+rwX "$BACKEND_JAR_PATH"
    fi

    JAR_FILE="$BACKEND_JAR_PATH/app.jar"
    if [ ! -f "$JAR_FILE" ]; then
        echo "ERROR: backend/build/libs/app.jar not found."
        echo "Possible causes:"
        echo "  - Gradle build failed or did not output app.jar."
        echo "  - Permissions issues or misconfiguration in build.gradle."
        echo "Current directory: $(pwd)"
        echo "Listing contents of $BACKEND_JAR_PATH:"
        ls -l "$BACKEND_JAR_PATH" 2>&1 || echo "(Directory not found)"
        echo "Searching for any JAR files in the project:"
        find . -type f -name "*.jar"
        echo ""
        echo "Attempting to explicitly build the bootJar task for the backend..."
        ./gradlew clean :backend:bootJar --refresh-dependencies --info --stacktrace
        echo "Dumping entire backend build directory structure for review:"
        find backend/build
        echo "Searching again for any JAR files in the project after bootJar:"
        find . -type f -name "*.jar"
        if [ -f "$JAR_FILE" ]; then
            echo "app.jar successfully built after invoking bootJar."
            ls -lh "$JAR_FILE"
            echo "Performing integrity test on the backend JAR..."
            if unzip -t "$JAR_FILE"; then
                echo "JAR integrity test passed."
            else
                echo "WARNING: The backend JAR integrity test failed. Please rebuild or verify the JAR."
            fi
        else
            echo "ERROR: Even after running bootJar, backend/build/libs/app.jar is missing."
            exit 1
        fi
    else
        echo "Found backend JAR: $JAR_FILE"
        ls -lh "$JAR_FILE"
        echo "Performing integrity test on the backend JAR..."
        if unzip -t "$JAR_FILE"; then
            echo "JAR integrity test passed."
        else
            echo "WARNING: The backend JAR integrity test failed. Please rebuild or verify the JAR."
        fi
    fi
fi

##############################################
# 8. Build Frontend (if Applicable)          #
##############################################
if [ -f frontend/package.json ]; then
    echo "Installing frontend dependencies..."
    (cd frontend && npm install)
    
    if [ ! -f frontend/public/index.html ]; then
        echo "Error: 'frontend/public/index.html' is missing. Create this file for the React build to succeed."
        exit 1
    fi

    # Verify required React dependencies and install if missing
    if ! grep -q '"react-router-dom"' frontend/package.json; then
        echo "Adding 'react-router-dom@6' (compatible with Node 18)..."
        (cd frontend && npm install react-router-dom@6)
    fi
    if grep -rq "react-hook-form" frontend/src; then
        if ! grep -q '"react-hook-form"' frontend/package.json; then
            echo "Adding 'react-hook-form' to frontend dependencies..."
            (cd frontend && npm install react-hook-form)
        fi
    fi
    
    echo "Building frontend..."
    if ! (cd frontend && npm run build); then
        echo "Frontend build failed. Check that 'frontend/public/index.html' exists and your configuration is correct."
        exit 1
    fi
fi

#########################################
# 9. Prepare Logs Directory & Compose File #
#########################################
LOG_DIR="logs"
if [ ! -d "$LOG_DIR" ]; then
    mkdir "$LOG_DIR"
fi
LOG_FILE="$LOG_DIR/run-stack-output.log"

if [ ! -f docker-compose.yml ]; then
    echo "docker-compose.yml not found. Creating a basic docker-compose.yml for MySQL, backend, and frontend..."
    cat > docker-compose.yml <<EOF
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: ccpsdb
      MYSQL_USER: ccpsuser
      MYSQL_PASSWORD: ccpspass
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
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/ccpsdb
      SPRING_DATASOURCE_USERNAME: ccpsuser
      SPRING_DATASOURCE_PASSWORD: ccpspass
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

#############################################
# 10. Additional Spring Boot Application Check #
#############################################
if [ -f backend/src/main/java/com/ccps/CcpsBackendApplication.java ] && [ -f backend/src/main/java/com/ccps/CcpsWebuiApplication.java ]; then
    echo "Warning: Multiple Spring Boot application classes detected in backend:"
    echo " - backend/src/main/java/com/ccps/CcpsBackendApplication.java"
    echo " - backend/src/main/java/com/ccps/CcpsWebuiApplication.java"
    echo "Ensure only one @SpringBootApplication class exists."
fi

# Ensure Jakarta Persistence API is available for Java (helpful for IDEs and runtime)
export CLASSPATH="$CLASSPATH:$(find \$HOME/.gradle/caches/modules-2/files-2.1/jakarta.persistence/jakarta.persistence-api/3.1.0 -name 'jakarta.persistence-api-3.1.0.jar' 2>/dev/null | head -n 1)"

###############################################
# 11. Start Docker Compose Services & Checking #
###############################################
echo "Starting all services (backend, frontend, database) using Docker Compose..."
if ! $COMPOSE_CMD up --build -d; then
    echo "Docker Compose failed to start services. Check logs with '$COMPOSE_CMD logs'."
    exit 1
fi

echo "Waiting for backend to become healthy..."
for i in {1..30}; do
    if curl -s http://localhost:8080/actuator/health | grep -q '"status":"UP"'; then
        echo "Backend is healthy."
        break
    fi
    sleep 2
    echo -n "."
done

echo "Waiting for frontend to become available..."
FRONTEND_AVAILABLE=false
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        echo "Frontend is healthy."
        FRONTEND_AVAILABLE=true
        break
    fi
    
    # Check Docker logs if we're halfway through waiting and still not connected
    if [ $i -eq 15 ]; then
        echo "Frontend still not available. Checking Docker logs..."
        $COMPOSE_CMD logs frontend | tail -n 20
    fi
    
    sleep 2
    echo -n "."
done

if [ "$FRONTEND_AVAILABLE" != "true" ]; then
    echo "Warning: Frontend may not be available. Checking Docker container status..."
    $COMPOSE_CMD ps frontend
    echo "Checking frontend container logs:"
    $COMPOSE_CMD logs frontend | tail -n 50
    echo "You may need to wait a bit longer or check for configuration issues."
fi

echo ""
echo "------------------------------------------------------------"
echo "All services are running in Docker Compose."
echo "Backend:   http://localhost:8080"
echo "Frontend:  http://localhost:3000"
echo "Database:  MySQL on localhost:3306 (user: ccpsuser, pass: ccpspass, db: ccpsdb)"
echo "------------------------------------------------------------"

# Automatically open the frontend in Firefox, if available.
if command -v firefox &> /dev/null; then
    echo "Opening frontend in Firefox..."
    firefox http://localhost:3000 &
fi

echo "To stop all services, run: $COMPOSE_CMD down"
wait