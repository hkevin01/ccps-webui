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
