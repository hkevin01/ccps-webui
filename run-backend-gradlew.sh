#!/bin/bash
# Script to run the Gradle Wrapper from the backend directory

set -e

cd /home/kevin/Projects/clr-webui/backend

if [ ! -f gradlew ]; then
    echo "Gradle wrapper (gradlew) not found in backend/. Generating wrapper..."
    if command -v gradle &> /dev/null; then
        gradle wrapper
    else
        echo "Gradle is not installed. Please install Gradle or use Maven."
        exit 1
    fi
fi

echo "Running './gradlew $@' in backend/"
chmod +x gradlew
./gradlew "$@"
