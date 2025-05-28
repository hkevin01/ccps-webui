#!/bin/bash
# Script to download Lombok JAR and provide IDE configuration instructions

set -e

LOMBOK_VERSION="1.18.32"
LOMBOK_JAR="lombok-${LOMBOK_VERSION}.jar"
DOWNLOAD_URL="https://projectlombok.org/downloads/${LOMBOK_JAR}"
TARGET_DIR="libs"

mkdir -p "$TARGET_DIR"

if [ ! -f "$TARGET_DIR/$LOMBOK_JAR" ]; then
    echo "Downloading Lombok $LOMBOK_VERSION..."
    curl -L -o "$TARGET_DIR/$LOMBOK_JAR" "$DOWNLOAD_URL"
    echo "Lombok JAR downloaded to $TARGET_DIR/$LOMBOK_JAR"
else
    echo "Lombok JAR already exists at $TARGET_DIR/$LOMBOK_JAR"
fi

echo ""
echo "To configure Lombok in your IDE:"
echo "1. For IntelliJ IDEA: Go to 'Settings > Build, Execution, Deployment > Compiler > Annotation Processors' and enable annotation processing."
echo "2. For Eclipse: Run 'java -jar $TARGET_DIR/$LOMBOK_JAR' and follow the installer instructions."
echo "3. For VS Code: Ensure your Java extension pack is up to date, annotation processing is enabled, and Lombok is included as a dependency in your project (e.g., in pom.xml or build.gradle)."
echo ""
echo "For more details, see: https://projectlombok.org/setup/"

# To run this script, make sure it is executable:
# chmod +x /home/kevin/Projects/clr-webui/scripts/install-lombok.sh
