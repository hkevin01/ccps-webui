#!/bin/bash
# Script to fix both backend and frontend dependencies

set -e

cd "$(dirname "$0")/.."
PROJ_ROOT=$(pwd)

echo "Fixing dependencies for the project at $PROJ_ROOT"

# Fix backend Gradle dependencies
echo "Updating backend Gradle configuration..."

# Create backend directory if it doesn't exist
mkdir -p backend/src/main/java/com/clr

# Make sure no Maven files are causing confusion
echo "Removing any Maven artifacts..."
rm -rf backend/target backend/pom.xml backend/.mvn backend/mvnw backend/mvnw.cmd 2>/dev/null || true

# Ensure backend/build.gradle exists with proper Spring dependencies
cat > backend/build.gradle << 'EOF'
plugins {
    id 'java'
    id 'org.springframework.boot'
    id 'io.spring.dependency-management'
}

group = 'com.clr'
version = '0.0.1-SNAPSHOT'

repositories {
    mavenCentral()
}

dependencies {
    // Spring Boot starters
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    
    // Database
    implementation 'org.postgresql:postgresql'
    
    // Lombok
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    
    // Test dependencies
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.springframework.security:spring-security-test'
    testImplementation 'com.h2database:h2'
}

bootJar {
    archiveFileName = 'app.jar'
}

test {
    useJUnitPlatform()
}
EOF

echo "Backend Gradle dependencies updated."

# Fix frontend dependencies
echo "Fixing frontend React dependencies..."

if [ -d frontend ]; then
    # Backup original package.json
    if [ -f frontend/package.json ]; then
        cp frontend/package.json frontend/package.json.bak
    fi
    
    # Create or update package.json to include required dependencies
    cat > frontend/package.json << 'EOF'
{
  "name": "clr-webui-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@react-google-maps/api": "^2.19.2",
    "axios": "^1.6.2",
    "bootstrap": "^5.3.2",
    "chart.js": "^4.4.1",
    "react": "^18.2.0",
    "react-chartjs-2": "^5.2.0",
    "react-dom": "^18.2.0",
    "react-hook-form": "^7.48.2",
    "react-router-dom": "^6.20.1",
    "react-scripts": "5.0.1",
    "typescript": "^4.9.5",
    "web-vitals": "^3.5.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "devDependencies": {
    "@types/node": "^20.9.0",
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15"
  }
}
EOF
    
    echo "Frontend package.json updated with compatible dependencies."
    
    # Ensure public/index.html exists
    mkdir -p frontend/public
    if [ ! -f frontend/public/index.html ]; then
        echo "Creating minimal index.html..."
        cat > frontend/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="Coastal Change Prediction System" />
    <title>CLR WebUI</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF
    fi
fi

echo "Creating the backend application main class if it doesn't exist..."
mkdir -p backend/src/main/java/com/clr
if [ ! -f backend/src/main/java/com/clr/ClrBackendApplication.java ]; then
    cat > backend/src/main/java/com/clr/ClrBackendApplication.java << 'EOF'
package com.clr;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ClrBackendApplication {
    public static void main(String[] args) {
        SpringApplication.run(ClrBackendApplication.class, args);
    }
}
EOF
fi

echo "Creating minimal application.properties if it doesn't exist..."
mkdir -p backend/src/main/resources
if [ ! -f backend/src/main/resources/application.properties ]; then
    cat > backend/src/main/resources/application.properties << 'EOF'
# Database Configuration
spring.datasource.url=${SPRING_DATASOURCE_URL:jdbc:postgresql://localhost:5432/clrdb}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME:clruser}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD:clrpass}
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

# Spring Security (temporary basic configuration)
spring.security.user.name=admin
spring.security.user.password=admin

# Actuator endpoints for health checks
management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=always
EOF
fi

echo "Updating Docker configurations..."
mkdir -p docker

# Create Dockerfile.backend if it doesn't exist
if [ ! -f docker/Dockerfile.backend ]; then
    cat > docker/Dockerfile.backend << 'EOF'
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY backend/build/libs/app.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
EOF
fi

echo "Restarting Gradle daemon..."
./gradlew --stop

echo "Building backend with Gradle..."
./gradlew clean :backend:bootJar --refresh-dependencies

echo "All dependencies have been fixed. Try running your application with: ./scripts/run-stack.sh"
