#!/usr/bin/env bash
# =========================================================
# Pterodactyl Frontend Fix & Build Installer
# Automatically fixes Tailwind nesting issue & rebuilds
# =========================================================

set -euo pipefail

PTERO_PATH="/var/www/pterodactyl"
ASSETS_PATH="$PTERO_PATH/resources/scripts/assets"
POSTCSS_CONFIG="$PTERO_PATH/postcss.config.js"
TAILWIND_CSS="$ASSETS_PATH/tailwind.css"

echo "==> Navigating to Pterodactyl directory..."
cd "$PTERO_PATH"

echo "==> Removing old node_modules and lock files..."
rm -rf node_modules yarn.lock package-lock.json

echo "==> Fixing postcss.config.js..."
cat > "$POSTCSS_CONFIG" <<'EOF'
module.exports = {
    plugins: [
        require('postcss-import'),
        require('tailwindcss'),
        require('autoprefixer'),
    ],
};
EOF

echo "==> Ensuring tailwind.css exists..."
mkdir -p "$ASSETS_PATH"
cat > "$TAILWIND_CSS" <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

echo "==> Installing dependencies..."
yarn install

echo "==> Building frontend for production..."
yarn build:production

echo "==> Done! Frontend should now work without the white screen."
