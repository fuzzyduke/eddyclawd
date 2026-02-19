#!/bin/bash
# Hardened Scaffolding helper for new Eddy VPS apps
# Usage: ./scripts/new_app_scaffold.sh <APP_NAME> <SUBDOMAIN> <INTERNAL_PORT>

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <APP_NAME> <SUBDOMAIN> <INTERNAL_PORT>"
    exit 1
fi

APP_NAME=$1
SUBDOMAIN=$2
INTERNAL_PORT=$3
TEMPLATE_DIR="apps/template"
TARGET_DIR="apps/$APP_NAME"

if [ -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR already exists."
    exit 1
fi

echo "Scaffolding NEW app: $APP_NAME (Target: $SUBDOMAIN.valhallala.com)..."

# 1. Copy template
cp -r "$TEMPLATE_DIR" "$TARGET_DIR"

# 2. Replace placeholders systematically
# Using | as delimiter for sed to avoid escaping slashes in paths
function replace_placeholder() {
    local key=$1
    local val=$2
    local file=$3
    sed -i "s|{{$key}}|$val|g" "$file"
}

# Process docker-compose.yml
DOCKER_COMPOSE="$TARGET_DIR/docker-compose.yml"
replace_placeholder "APP_NAME" "$APP_NAME" "$DOCKER_COMPOSE"
replace_placeholder "SUBDOMAIN" "$SUBDOMAIN" "$DOCKER_COMPOSE"
replace_placeholder "INTERNAL_PORT" "$INTERNAL_PORT" "$DOCKER_COMPOSE"

# Process APP.md
APP_MD="$TARGET_DIR/APP.md"
replace_placeholder "APP_NAME" "$APP_NAME" "$APP_MD"
replace_placeholder "SUBDOMAIN" "$SUBDOMAIN" "$APP_MD"
replace_placeholder "INTERNAL_PORT" "$INTERNAL_PORT" "$APP_MD"
replace_placeholder "IMAGE" "PIN_ME_IN_DOCKER_COMPOSE" "$APP_MD"

# 3. Cleanup/Rename README from template
mv "$TARGET_DIR/README.md" "$TARGET_DIR/ARCH_NOTES.md"

echo "------------------------------------------------------------"
echo "✅ Scaffolding complete in $TARGET_DIR"
echo "------------------------------------------------------------"
echo "CRITICAL NEXT STEPS:"
echo "1. Edit $TARGET_DIR/docker-compose.yml and PIN your image tag."
echo "2. Add bible:vps/$APP_NAME.env to your private Bible repo."
echo "3. Follow the checklist in docs/PUBLISH_NEW_APP.md"
echo "------------------------------------------------------------"
