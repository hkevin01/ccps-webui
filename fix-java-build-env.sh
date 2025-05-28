#!/bin/bash
# Script to automatically fix common Java build, toolchain, and test issues for this project.

set -e

echo "=== 1. Ensuring JDK 17 is installed and JAVA_HOME is set ==="
if ! java -version 2>&1 | grep '17.'; then
    echo "JDK 17 not found. Installing OpenJDK 17..."
    sudo apt update
    sudo apt install -y openjdk-17-jdk
fi

JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64"
if [ -d "$JAVA_HOME_PATH" ]; then
    export JAVA_HOME="$JAVA_HOME_PATH"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "JAVA_HOME set to $JAVA_HOME"
else
    echo "Could not find OpenJDK 17 at $JAVA_HOME_PATH. Please set JAVA_HOME manually."
    exit 1
fi

echo "=== 2. Cleaning and rebuilding Gradle and Maven projects ==="
if [ -f backend/build.gradle ]; then
    (cd backend && ./gradlew --stop || true)
    (cd backend && ./gradlew clean build --refresh-dependencies)
fi

if [ -f backend/pom.xml ]; then
    (cd backend && mvn clean install)
fi

echo "=== 3. Checking for duplicate @SpringBootApplication classes ==="
APP_CLASSES=$(find backend/src/main/java -name "*.java" | xargs grep -l "@SpringBootApplication" || true)
if [ "$(echo "$APP_CLASSES" | wc -l)" -gt 1 ]; then
    echo "WARNING: Multiple @SpringBootApplication classes found:"
    echo "$APP_CLASSES"
    echo "Please ensure only one main class is annotated with @SpringBootApplication."
fi

echo "=== 4. Checking for missing Lombok dependency and plugin ==="
if ! grep -q "lombok" backend/pom.xml 2>/dev/null; then
    echo "Lombok not found in pom.xml. Add the following to your <dependencies> in backend/pom.xml:"
    echo '<dependency>'
    echo '    <groupId>org.projectlombok</groupId>'
    echo '    <artifactId>lombok</artifactId>'
    echo '    <version>1.18.32</version>'
    echo '    <scope>provided</scope>'
    echo '</dependency>'
fi

echo "=== 5. Checking for test failures ==="
if [ -d backend/target/surefire-reports ]; then
    echo "Recent test failures (if any):"
    tail -n 40 backend/target/surefire-reports/*.txt 2>/dev/null || true
fi

echo "=== 6. Done. If you still see errors, check the logs above and the documentation links in the script comments. ==="
