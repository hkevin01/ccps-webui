#!/bin/bash
# Script to install and fix frontend dependencies including OpenLayers

set -e

cd "$(dirname "$0")/.."
echo "Installing frontend dependencies for OpenLayers integration..."

# Navigate to frontend directory
cd frontend

# Install OpenLayers and related packages
echo "Installing OpenLayers and related packages..."
npm install --save ol proj4
npm install --save ol-layerswitcher

# Update package.json to include these dependencies if not already there
if ! grep -q '"ol"' package.json; then
    echo "Updating package.json with OpenLayers dependencies..."
    # Use temporary file for substitution
    sed -i 's/"dependencies": {/"dependencies": {\n    "ol": "^7.5.1",\n    "ol-layerswitcher": "^4.1.1",\n    "proj4": "^2.9.2",/g' package.json
fi

# Create OpenLayers CSS import file to simplify imports
echo "Creating OpenLayers CSS imports file..."
mkdir -p src/styles
cat > src/styles/map-styles.css << 'EOF'
@import 'ol/ol.css';
@import 'ol-layerswitcher/dist/ol-layerswitcher.css';

.map-container {
  width: 100%;
  height: 400px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.layer-switcher {
  top: 0.5em;
  right: 0.5em;
}
EOF

echo "Frontend dependencies installed and fixed."
echo "You can now rebuild your project with: ./scripts/run-stack.sh"

cd ..
chmod +x scripts/fix-frontend-deps.sh
