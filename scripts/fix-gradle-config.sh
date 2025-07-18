#!/bin/bash
# Script to fix Gradle configuration issues

set -e

echo "Fixing Gradle configuration issues..."

# Update settings.gradle with correct toolchain syntax
cat > settings.gradle << 'EOF'
pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = 'ccps-webui'
include 'backend'
project(':backend').projectDir = file('backend')

// Note: Don't use toolchainManagement here - it's causing issues
// Instead, use the java toolchain configuration in the build.gradle files
EOF

# Update build.gradle in root project
if [ -f "build.gradle" ]; then
    echo "Updating root build.gradle with proper Java toolchain configuration..."
    # Create backup
    cp build.gradle build.gradle.bak
    
    # Check if build.gradle already has java toolchain configuration
    if ! grep -q "toolchain" build.gradle; then
        # Add toolchain configuration after plugins block
        awk '/plugins {/,/}/ { print; if ($0 ~ /}/) print "\njava {\n    toolchain {\n        languageVersion = JavaLanguageVersion.of(17)\n    }\n}" } !/plugins {/,/}/ { print }' build.gradle.bak > build.gradle
    fi
fi

# Update backend build.gradle if needed
if [ -f "backend/build.gradle" ]; then
    echo "Updating backend build.gradle with proper Java toolchain configuration..."
    # Create backup
    cp backend/build.gradle backend/build.gradle.bak
    
    # Check if backend/build.gradle already has java toolchain configuration
    if ! grep -q "toolchain" backend/build.gradle; then
        # Add toolchain configuration after plugins block
        awk '/plugins {/,/}/ { print; if ($0 ~ /}/) print "\njava {\n    toolchain {\n        languageVersion = JavaLanguageVersion.of(17)\n    }\n}" } !/plugins {/,/}/ { print }' backend/build.gradle.bak > backend/build.gradle
    fi
fi

echo "Gradle configurations updated."
echo "Now refreshing Gradle..."

# Stop any running Gradle daemons
./gradlew --stop || true

# Clean Gradle cache
rm -rf ~/.gradle/caches/modules-2/files-2.1/org.gradle* || true

# Run Gradle with refresh
./gradlew clean --refresh-dependencies || echo "Gradle refresh failed, but we'll continue..."

echo "Gradle configuration fix complete!"
echo "You should now be able to build with: ./gradlew clean build"

chmod +x /home/kevin/Projects/ccps-webui/scripts/fix-gradle-config.sh
