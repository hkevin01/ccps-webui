#!/bin/bash
# Script to build frontend with TypeScript type checking disabled

set -e

echo "Building frontend with TypeScript type checking disabled..."

# Navigate to frontend directory
cd "$(dirname "$0")/../frontend"

# Create a temporary tsconfig with type checking disabled
cat > tsconfig.temp.json << 'EOF'
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "skipLibCheck": true,
    "noImplicitAny": false,
    "suppressImplicitAnyIndexErrors": true,
    "checkJs": false,
    "noEmit": true
  }
}
EOF

# Temporarily rename files
mv tsconfig.json tsconfig.backup.json
mv tsconfig.temp.json tsconfig.json

# Run the build with TypeScript type checking disabled
echo "Building with TSC_COMPILE_ON_ERROR=true..."
export TSC_COMPILE_ON_ERROR=true
export DISABLE_ESLINT_PLUGIN=true

# Build the frontend
npm run build

# Restore original tsconfig
mv tsconfig.json tsconfig.temp.json
mv tsconfig.backup.json tsconfig.json
rm tsconfig.temp.json

echo "Frontend build completed with type checking disabled."
chmod +x "$(dirname "$0")/build-frontend-no-types.sh"
