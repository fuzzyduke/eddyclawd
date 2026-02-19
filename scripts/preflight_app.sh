#!/bin/bash
# Preflight script to validate app configuration before pushing
# Usage: ./scripts/preflight_app.sh <APP_NAME>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <APP_NAME>"
    exit 1
fi

APP_NAME=$1
COMPOSE_FILE="apps/$APP_NAME/docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Error: $COMPOSE_FILE not found."
    exit 1
fi

echo "🔍 Running preflight for $APP_NAME..."
FAILED=0

# 1. Check for host port exposure
if grep -q "ports:" "$COMPOSE_FILE"; then
    # Check if any port mapping is actually defined and not commented out
    if grep -E "^ +ports:" "$COMPOSE_FILE"; then
        echo "❌ Error: Host port exposure ('ports:') detected. This is forbidden."
        FAILED=1
    fi
fi

# 2. Check for latest image tag
if grep -q "image:.*latest" "$COMPOSE_FILE"; then
    echo "❌ Error: 'latest' tag detected in image. Please use a pinned version."
    FAILED=1
fi

# 3. Check for resource limits
if ! grep -q "mem_limit:" "$COMPOSE_FILE"; then
    echo "❌ Error: 'mem_limit' is missing."
    FAILED=1
fi
if ! grep -q "cpus:" "$COMPOSE_FILE"; then
    echo "❌ Error: 'cpus' limit is missing."
    FAILED=1
fi

# 4. Check for healthcheck
if ! grep -q "healthcheck:" "$COMPOSE_FILE"; then
    echo "❌ Error: 'healthcheck' section is missing."
    FAILED=1
fi

# 5. Check for correct env_file path
EXPECTED_ENV="/srv/secrets/$APP_NAME.env"
if ! grep -q "env_file: $EXPECTED_ENV" "$COMPOSE_FILE"; then
    echo "❌ Error: 'env_file' must be exactly $EXPECTED_ENV"
    FAILED=1
fi

# 6. Check for Traefik backtick rule
if ! grep -q "traefik.http.routers.$APP_NAME.rule=Host(\`.*\`)" "$COMPOSE_FILE"; then
    echo "❌ Error: Traefik rule for $APP_NAME must use backticks in Host rule."
    FAILED=1
fi

# 7. Check for proxy network attachment
if ! grep -q "\- proxy" "$COMPOSE_FILE"; then
    echo "❌ Error: App must be attached to the 'proxy' network."
    FAILED=1
fi

# 8. docker compose config check
echo "⏳ Validating YAML syntax..."
docker compose -f "$COMPOSE_FILE" config > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Error: 'docker compose config' failed."
    FAILED=1
fi

if [ $FAILED -eq 0 ]; then
    echo "✅ Preflight PASSED for $APP_NAME."
    exit 0
else
    echo "❌ Preflight FAILED for $APP_NAME. Please fix errors before pushing."
    exit 1
fi
