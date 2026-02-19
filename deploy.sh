#!/bin/bash
# /srv/deploy.sh - Hardened Deterministic Deployment Engine for Eddy VPS
# Git is the absolute source of truth.

set -euo pipefail
IFS=$'\n\t'

# Configuration
REPO_DIR="/srv"
APPS_DIR="${REPO_DIR}/apps"
INFRA_DIR="${REPO_DIR}/infra"
LOG_DIR="/var/log/deployments"
DEPLOYING_FLAG="${REPO_DIR}/.deploying"
LAST_SUCCESS_FILE="${LOG_DIR}/.last_deployed_commit"
MAX_HEALTH_WAIT=60 # seconds

# Ensure log directory exists
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_DIR}/global.log"
}

error() {
    log "ERROR: $1"
    # Note: We don't remove the .deploying flag on error to signal failure
    exit 1
}

# 1. Concurrency Locking
LOCKFILE="/tmp/eddy-deploy.lock"
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    log "Deployment already in progress. Aborting."
    exit 0
fi

# 2. Drift & Interruption Protection
log "Starting deployment sequence..."
cd "$REPO_DIR"

# Check for uncommitted local changes
if [[ -n $(git status --porcelain) ]]; then
    log "Uncommitted local changes detected on VPS."
    git status --porcelain
    error "Refusing deployment due to infrastructure drift."
fi

# Check for previous crashed deployment
if [ -f "$DEPLOYING_FLAG" ]; then
    log "WARNING: Previous deployment flag exists. Interrupted deploy detected."
    # We proceed but this signals that the system might be in a partial state
fi

# Create deployment flag
touch "$DEPLOYING_FLAG"

# Capture current and target state
TARGET_COMMIT=$(git rev-parse --short HEAD)
if [ -f "$LAST_SUCCESS_FILE" ]; then
    LAST_SUCCESS_COMMIT=$(cat "$LAST_SUCCESS_FILE")
else
    # First run fallback
    LAST_SUCCESS_COMMIT="HEAD^"
    log "No previous success commit found. Using $LAST_SUCCESS_COMMIT as baseline."
fi

log "Target Commit: $TARGET_COMMIT"
log "Last Success: $LAST_SUCCESS_COMMIT"

# 3. Resource Pre-checks
check_resources() {
    log "Validating system resources..."
    
    # RAM Check (Free + Cached)
    FREE_MEM=$(awk '/MemAvailable/ {print $2}' /proc/meminfo) # in kB
    if [ "$FREE_MEM" -lt 1048576 ]; then # < 1GB
        error "Insufficient RAM: $((FREE_MEM / 1024))MB available. Need > 1024MB."
    fi

    # Disk Check (%)
    DISK_USAGE=$(df / --output=pcent | tail -1 | tr -dc '0-9')
    if [ "$DISK_USAGE" -gt 90 ]; then
        error "Insufficient Disk Space: ${DISK_USAGE}% used. Need > 10% free."
    fi

    # Swap Check (%)
    SWAP_TOTAL=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
    if [ "$SWAP_TOTAL" -gt 0 ]; then
        SWAP_FREE=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
        SWAP_USED_PCT=$(( (SWAP_TOTAL - SWAP_FREE) * 100 / SWAP_TOTAL ))
        if [ "$SWAP_USED_PCT" -gt 70 ]; then
            error "High Swap Usage: ${SWAP_USED_PCT}%. Potential OOM risk."
        fi
    fi
    log "Resource check passed."
}

check_resources

# 4. upgrade.sh Safety Scanner
scan_upgrade_script() {
    local SCRIPT=$1
    log "Scanning $SCRIPT for safety violations..."
    
    # Blacklist patterns
    local BLACKLIST=(
        "docker system prune"
        "docker volume rm"
        "docker network rm"
        "rm -rf /"
    )

    for pattern in "${BLACKLIST[@]}"; do
        if grep -Fq "$pattern" "$SCRIPT"; then
            error "Safety Violation: Unsafe command '$pattern' detected in $SCRIPT"
        fi
    done
}

# 5. Deployment & Rollback Logic
rollback_stack() {
    local STACK_DIR=$1
    local STACK_NAME=$(basename "$STACK_DIR")
    log "CRITICAL: Deployment failed for $STACK_NAME. Initiating rollback..."
    
    cd "$REPO_DIR"
    git checkout "$LAST_SUCCESS_COMMIT" -- "$STACK_DIR"
    
    cd "$STACK_DIR"
    docker compose up -d --remove-orphans
    
    log "Rollback completed for $STACK_NAME. Restored to $LAST_SUCCESS_COMMIT."
    error "Deployment aborted due to failure and subsequent rollback of $STACK_NAME."
}

deploy_stack() {
    local STACK_DIR=$1
    local STACK_NAME=$(basename "$STACK_DIR")
    local APP_LOG="${LOG_DIR}/${STACK_NAME}.log"

    log "Deploying stack: $STACK_NAME..."
    cd "$STACK_DIR"

    # Validation
    if ! docker compose config > /dev/null 2>&1; then
        log "Validation failed: Invalid docker-compose.yml"
        rollback_stack "$STACK_DIR"
    fi

    # Hardened Upgrade
    if [ -x "upgrade.sh" ]; then
        scan_upgrade_script "upgrade.sh"
        log "Executing upgrade.sh..."
        if ! ./upgrade.sh >> "$APP_LOG" 2>&1; then
            log "Execution failed: upgrade.sh returned non-zero"
            rollback_stack "$STACK_DIR"
        fi
    fi

    # Pull & Up
    docker compose pull >> "$APP_LOG" 2>&1 || rollback_stack "$STACK_DIR"
    docker compose up -d --remove-orphans >> "$APP_LOG" 2>&1 || rollback_stack "$STACK_DIR"

    # Health Verification
    log "Verifying health for $STACK_NAME..."
    START_TIME=$(date +%s)
    while [ $(($(date +%s) - START_TIME)) -lt $MAX_HEALTH_WAIT ]; do
        # Use ps format to detect health
        local STATUS=$(docker compose ps --format json)
        local UNHEALTHY=$(echo "$STATUS" | grep -c '"Health":"unhealthy"' || true)
        local STARTING=$(echo "$STATUS" | grep -c '"Health":"starting"' || true)
        local EXITED=$(echo "$STATUS" | grep -c '"State":"exited"' || true)

        if [ "$UNHEALTHY" -eq 0 ] && [ "$STARTING" -eq 0 ] && [ "$EXITED" -eq 0 ]; then
            log "Success: $STACK_NAME is healthy."
            return 0
        fi
        sleep 5
    done

    log "Health check timeout for $STACK_NAME."
    rollback_stack "$STACK_DIR"
}

# 6. Execute Selective Deploys
CHANGED_DIRS=$(git diff --name-only "$LAST_SUCCESS_COMMIT" HEAD | cut -d/ -f1,2 | sort -u || true)

for DIR in $CHANGED_DIRS; do
    if [ -d "${REPO_DIR}/${DIR}" ]; then
        if [[ "$DIR" == apps/* ]] || [[ "$DIR" == infra/* ]]; then
            deploy_stack "${REPO_DIR}/${DIR}"
        fi
    fi
done

# 7. Post-Deploy Success
rm -f "$DEPLOYING_FLAG"
echo "$TARGET_COMMIT" > "$LAST_SUCCESS_FILE"

# Safe image prune (only older than 24h)
docker image prune -f --filter "until=24h"

log "Deployment sequence completed successfully for commit $TARGET_COMMIT."
