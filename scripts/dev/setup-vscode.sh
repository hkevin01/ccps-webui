#!/bin/bash
# Script to set up VS Code for Java and Gradle development

set -e

cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)
echo "Setting up VS Code for project at: $PROJECT_ROOT"

# Create .vscode directory if it doesn't exist
mkdir -p .vscode

# Create settings.json with optimal Java/Gradle settings
echo "Creating VS Code settings..."
cat > .vscode/settings.json << 'EOF'
{
  "java.import.gradle.enabled": true,
  "java.import.gradle.wrapper.enabled": true,
  "java.import.gradle.version": "wrapper",
  "java.configuration.updateBuildConfiguration": "automatic",
  "java.compile.nullAnalysis.mode": "automatic",
  "java.server.launchMode": "Standard",
  "java.jdt.ls.java.home": "",
  "java.configuration.runtimes": [
    {
      "name": "JavaSE-17",
      "path": "/usr/lib/jvm/java-17-openjdk-amd64",
      "default": true
    }
  ],
  "java.project.importOnFirstTimeStartup": "automatic",
  "java.completion.importOrder": [
    "java",
    "javax",
    "jakarta",
    "org",
    "com",
    ""
  ],
  "java.format.enabled": true,
  "java.format.settings.url": "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
  "editor.formatOnSave": true,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "gradle.nestedProjects": true,
  "gradle.autoDetect": "on",
  "gradle.debug": true,
  "gradle.javaDebug": {
    "tasks": [
      "bootRun"
    ],
    "clean": true
  },
  "terminal.integrated.env.linux": {
    "JAVA_HOME": "/usr/lib/jvm/java-17-openjdk-amd64"
  }
}
EOF

# Create launch.json for debugging
echo "Creating launch configuration..."
mkdir -p .vscode
cat > .vscode/launch.json << 'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "java",
      "name": "Spring Boot-ClrBackendApplication",
      "request": "launch",
      "cwd": "${workspaceFolder}",
      "mainClass": "com.clr.ClrBackendApplication",
      "projectName": "backend",
      "args": "",
      "envFile": "${workspaceFolder}/.env",
      "vmArgs": "-Dspring.profiles.active=dev"
    }
  ]
}
EOF

# Check if VS Code CLI is available and install extensions
echo "Checking for VS Code CLI..."
if command -v code &> /dev/null; then
    echo "Installing recommended extensions..."
    code --install-extension vscjava.vscode-java-pack
    code --install-extension vmware.vscode-spring-boot
    code --install-extension vscjava.vscode-gradle
    code --install-extension vscjava.vscode-lombok # Correct extension ID for Lombok
    code --install-extension redhat.vscode-yaml
    echo "VS Code extensions installed successfully."
else
    echo "VS Code CLI not found. Please install the following extensions manually:"
    echo "- Language Support for Java by Red Hat"
    echo "- Spring Boot Extension Pack by VMware"
    echo "- Gradle for Java by Microsoft"
    echo "- Lombok by Microsoft Java Team (vscjava.vscode-lombok)"
    echo "- YAML by Red Hat"
fi

# Create minimal settings.gradle if it doesn't exist
if [ ! -f "settings.gradle" ]; then
    echo "Creating settings.gradle..."
    cat > settings.gradle << 'EOF'
rootProject.name = 'clr-webui'
include 'backend'
EOF
    echo "Created settings.gradle"
fi

# Create VSCode tasks.json for common Gradle tasks
echo "Creating tasks configuration..."
cat > .vscode/tasks.json << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build Backend",
      "type": "shell",
      "command": "./gradlew :backend:bootJar",
      "group": {
        "kind": "build",
        "isDefault": true
      }
    },
    {
      "label": "Run Backend",
      "type": "shell",
      "command": "./gradlew :backend:bootRun",
      "group": "none"
    },
    {
      "label": "Clean Project",
      "type": "shell",
      "command": "./gradlew clean",
      "group": "none"
    },
    {
      "label": "Start All Docker Services",
      "type": "shell", 
      "command": "./scripts/run-stack.sh",
      "group": "none"
    }
  ]
}
EOF

# Create extensions.json to recommend extensions to other developers
echo "Creating extensions recommendations..."
cat > .vscode/extensions.json << 'EOF'
{
  "recommendations": [
    "vscjava.vscode-java-pack",
    "vmware.vscode-spring-boot",
    "vscjava.vscode-gradle",
    "vscjava.vscode-lombok",
    "redhat.vscode-yaml"
  ]
}
EOF

# Validate Java installation
echo "Validating Java installation..."
if ! command -v java &> /dev/null; then
    echo "Java not found. Please install JDK 17."
else
    JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
    echo "Found Java version: $JAVA_VERSION"
    
    # Update the Java path in settings.json if we can detect it
    JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    if [ -n "$JAVA_HOME" ]; then
        # Replace the Java path in settings.json
        sed -i "s|/usr/lib/jvm/java-17-openjdk-amd64|$JAVA_HOME|g" .vscode/settings.json
        echo "Updated Java path to $JAVA_HOME in settings.json"
    fi
fi

# Validate Gradle installation
echo "Validating Gradle wrapper..."
if [ ! -f "gradlew" ]; then
    echo "Gradle wrapper not found. Attempting to create it..."
    if command -v gradle &> /dev/null; then
        gradle wrapper
        chmod +x gradlew
        echo "Gradle wrapper created."
    else
        echo "Neither Gradle nor Gradle wrapper found. Please install Gradle."
    fi
else
    echo "Gradle wrapper found."
    chmod +x gradlew
fi

echo ""
echo "VS Code setup complete!"
echo ""
echo "To finish setup, please do the following in VS Code:"
echo "1. Open the Command Palette (Ctrl+Shift+P)"
echo "2. Run 'Java: Clean Java Language Server Workspace'"
echo "3. Select 'Reload and delete' when prompted"
echo "4. After reloading, run 'Java: Import Java projects in workspace'"
echo "5. Run 'Gradle: Refresh Gradle Project'"
echo ""
echo "You should now have a fully configured Java/Gradle development environment in VS Code."
