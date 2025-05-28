#!/bin/bash
# Script to run fullstack: backend, frontend, and database using docker-compose

set -e

# Allow Ctrl-C to stop docker-compose and exit script gracefully
trap "echo 'Stopping services...'; exit 0" SIGINT

# Check if Maven is installed, install if missing
if ! command -v mvn &> /dev/null; then
    echo "Maven (mvn) could not be found. Attempting to install Maven..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y maven
    elif command -v yum &> /dev/null; then
        sudo yum install -y maven
    else
        echo "Automatic Maven installation is not supported on this OS. Please install Maven manually and try again."
        exit 1
    fi
fi

# Build backend JAR before starting Docker Compose
if [ ! -f backend/pom.xml ]; then
    echo "backend/pom.xml not found! Creating a new Spring Boot project in the 'backend' directory using Spring Initializr..."
    curl https://start.spring.io/starter.zip \
        -d dependencies=web,data-jpa,postgresql,security \
        -d javaVersion=17 \
        -d groupId=com.clr \
        -d artifactId=backend \
        -d name=clr-backend \
        -d packageName=com.clr \
        -o backend.zip
    rm -rf backend
    unzip -oq backend.zip -d backend
    rm backend.zip
    echo "A Spring Boot project has been created in 'backend'."
    # If parent pom.xml does not exist, create it
    if [ ! -f pom.xml ]; then
        cat > pom.xml <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.clr</groupId>
    <artifactId>clr-webui</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>
    <name>clr-webui</name>
    <description>Parent project for Coastal Change Prediction System</description>
    <modules>
        <module>backend</module>
    </modules>
    <properties>
        <java.version>17</java.version>
    </properties>
    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-maven-plugin</artifactId>
                    <version>2.7.18</version>
                </plugin>
            </plugins>
        </pluginManagement>
    </build>
</project>
EOF
        echo "Created parent pom.xml in project root."
    fi
fi

echo "Cleaning previous Maven build..."
(cd backend && mvn clean)
echo "Building backend JAR with Maven..."
if ! (cd backend && mvn package); then
    echo "Maven build or tests failed. Please check the logs above and see backend/target/surefire-reports for details."
    if [ -d backend/target/surefire-reports ]; then
        echo "---- Recent test failures ----"
        tail -n 40 backend/target/surefire-reports/*.txt 2>/dev/null || true
        echo "-----------------------------"
    fi
    exit 1
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
LOG_FILE="$LOG_DIR/run-fullstack-output.log"

echo "Building images and starting all services..."
$COMPOSE_CMD up --build | tee "$LOG_FILE"
