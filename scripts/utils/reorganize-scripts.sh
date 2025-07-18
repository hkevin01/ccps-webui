#!/bin/bash
# Script to reorganize scripts directory into logical subfolders

set -e

echo "Reorganizing scripts directory..."

# Navigate to scripts directory
cd "$(dirname "$0")"

# Create subdirectories
mkdir -p docker build dev utils

# Move Docker-related scripts
echo "Moving Docker-related scripts to docker/ subfolder..."
git mv -f fix-network.sh docker/ 2>/dev/null || mv -f fix-network.sh docker/ 2>/dev/null || echo "fix-network.sh not found"
git mv -f fix-docker-issues.sh docker/ 2>/dev/null || mv -f fix-docker-issues.sh docker/ 2>/dev/null || echo "fix-docker-issues.sh not found"
git mv -f fix-docker-config.sh docker/ 2>/dev/null || mv -f fix-docker-config.sh docker/ 2>/dev/null || echo "fix-docker-config.sh not found"
git mv -f stop-services.sh docker/ 2>/dev/null || mv -f stop-services.sh docker/ 2>/dev/null || echo "stop-services.sh not found"
git mv -f restart-docker.sh docker/ 2>/dev/null || mv -f restart-docker.sh docker/ 2>/dev/null || echo "restart-docker.sh not found"

# Move build-related scripts
echo "Moving build-related scripts to build/ subfolder..."
git mv -f build-backend-jar.sh build/ 2>/dev/null || mv -f build-backend-jar.sh build/ 2>/dev/null || echo "build-backend-jar.sh not found"
git mv -f fix-frontend-deps.sh build/ 2>/dev/null || mv -f fix-frontend-deps.sh build/ 2>/dev/null || echo "fix-frontend-deps.sh not found"

# Move development environment scripts
echo "Moving development environment scripts to dev/ subfolder..."
git mv -f setup-vscode.sh dev/ 2>/dev/null || mv -f setup-vscode.sh dev/ 2>/dev/null || echo "setup-vscode.sh not found"
git mv -f log-vscode-problems.sh dev/ 2>/dev/null || mv -f log-vscode-problems.sh dev/ 2>/dev/null || echo "log-vscode-problems.sh not found"
git mv -f fix-java-build-env.sh dev/ 2>/dev/null || mv -f fix-java-build-env.sh dev/ 2>/dev/null || echo "fix-java-build-env.sh not found"

# Keep run-stack.sh at the top level since it's the main entry point
echo "Keeping run-stack.sh at the top level..."

# Create symlinks for frequently used scripts to maintain backward compatibility
echo "Creating symlinks for backward compatibility..."
ln -sf docker/stop-services.sh stop-services.sh
ln -sf docker/restart-docker.sh restart-docker.sh
ln -sf build/build-backend-jar.sh build-backend-jar.sh

# Create a new README.md with updated information
echo "Creating updated README.md..."
cat > README.md << 'EOF'
# Scripts Directory

This folder contains utility scripts for building, running, and managing the ccps-webui project.
The scripts are organized into logical subfolders for better maintainability.

## Directory Structure

- **Top Level**: Main entry point scripts
  - `run-stack.sh`: Main script to build and run the full stack
  - Symlinks to frequently used scripts for backward compatibility

- **docker/**: Docker-related scripts
  - `fix-network.sh`: Fixes Docker network issues
  - `fix-docker-issues.sh`: Diagnoses and fixes Docker-related issues
  - `fix-docker-config.sh`: Fixes Docker configuration issues
  - `stop-services.sh`: Stops all Docker services
  - `restart-docker.sh`: Restarts Docker services with clean state

- **build/**: Build-related scripts
  - `build-backend-jar.sh`: Builds the backend Spring Boot JAR
  - `fix-frontend-deps.sh`: Fixes frontend dependencies

- **dev/**: Development environment scripts
  - `setup-vscode.sh`: Sets up VS Code with optimal settings
  - `log-vscode-problems.sh`: Logs and examines VS Code/Gradle problems
  - `fix-java-build-env.sh`: Fixes Java build environment issues

- **utils/**: Utility scripts
  - Various utility scripts for common tasks

## Usage

Run any script from the project root, for example:
```bash
./scripts/run-stack.sh
# or
./scripts/docker/restart-docker.sh
```

## Workflow Examples

### Start Development Environment
```bash
# Set up VS Code first
./scripts/dev/setup-vscode.sh

# Install dependencies and fix common issues
./scripts/build/fix-frontend-deps.sh

# Start the full stack
./scripts/run-stack.sh
```

### Stop and Clean Up
```bash
# Stop all services
./scripts/docker/stop-services.sh

# Optionally run Docker cleanup
docker system prune -f
```

## Notes

- All scripts should be run from the project root directory.
- The backend JAR is always expected at `backend/build/libs/app.jar` for Docker deployment.
- See the main project README for more details.
EOF

echo "Script reorganization complete!"
echo "The scripts have been organized into the following subfolders:"
echo "  - docker/: Docker-related scripts"
echo "  - build/: Build-related scripts"
echo "  - dev/: Development environment scripts"
echo "  - utils/: Utility scripts"
echo ""
echo "Main entry point 'run-stack.sh' remains at the top level."
echo "Symlinks have been created for backward compatibility."
