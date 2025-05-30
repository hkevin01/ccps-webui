# Scripts Directory

This folder contains utility scripts for building, running, and managing the clr-webui project.

## Available Scripts

### Core Scripts

- **run-stack.sh**  
  Builds the backend and frontend, sets up permissions, validates environment variables, and starts all services (backend, frontend, database) using Docker Compose.

- **stop-services.sh**  
  Stops all Docker services gracefully and provides status information.
  ```bash
  ./scripts/stop-services.sh
  ```

- **build-backend-jar.sh**  
  Builds the backend Spring Boot JAR (`app.jar`) in `backend/build/libs` using Gradle.  
  ```bash
  ./scripts/build-backend-jar.sh
  ```

### Environment Setup

- **setup-vscode.sh**  
  Sets up VS Code with optimal settings for Java and Gradle development, installs recommended extensions, and configures debugging.
  ```bash
  ./scripts/setup-vscode.sh
  ```

- **fix-frontend-deps.sh**  
  Installs and fixes frontend dependencies, especially for maps integration (OpenLayers, Google Maps).
  ```bash
  ./scripts/fix-frontend-deps.sh
  ```

- **install-lombok.sh**  
  Installs Lombok for local development.

- **fix-java-build-env.sh**  
  Fixes Java build environment issues (permissions, paths, etc).

### Diagnostic Scripts

- **log-vscode-problems.sh**  
  Logs and examines all problems reported by VS Code and Gradle.
  ```bash
  ./scripts/log-vscode-problems.sh
  ```

## Usage

Run any script from the project root, for example:
```bash
./scripts/run-stack.sh
```

## Workflow Examples

### Start Development Environment
```bash
# Set up VS Code first
./scripts/setup-vscode.sh

# Install dependencies and fix common issues
./scripts/fix-frontend-deps.sh

# Start the full stack
./scripts/run-stack.sh
```

### Stop and Clean Up
```bash
# Stop all services
./scripts/stop-services.sh

# Optionally run Docker cleanup
docker system prune -f
docker volume prune -f
```

## Notes

- All scripts assume you are running from the project root.
- The backend JAR is always expected at `backend/build/libs/app.jar` for Docker deployment.
- See the main project README for more details.
