# Eddy VPS Deployment Rules

## 1. Repository Contract
Every app located in `/apps/<app-name>` must follow these rules:

- **Isolation**: Each app MUST have its own `docker-compose.yml`.
- **Networking**: Each app MUST join the `proxy` network for Traefik routing.
- **Resources**: Each service MUST have `deploy.resources.limits` (memory and cpu).
- **Persistence**: Use named volumes or paths within the app directory.
- **Port Handling**: Do NOT expose ports to the host directly. Use Traefik routing.

## 2. Infrastructure Changes
- Traefik and global network configs live in `/infra`.
- Changes here are applied automatically by `deploy.sh`.
- Extreme caution: Validation is mandatory.

## 3. Automated Hardened Upgrades (`upgrade.sh`)
- If an app requires a manual step, provide an executable `upgrade.sh`.
- **Safety Scanner**: The engine scans for blacklisted commands (`docker system`, `rm -rf /`, etc.).
- **Execution**: Runs BEFORE `docker compose up`. Failure triggers an automatic rollback of the stack.

## 4. Git as Source of Truth
- The VPS state is strictly reset to `origin/main` on every push.
- **Drift Protection**: Deployment fails if uncommitted local changes exist on the VPS.

## 5. Resource Safety & Stability
- **Pre-checks**: Deployment aborts if RAM < 1GB or Disk Space < 10% free.
- **Rollback**: Failure in validation, upgrade, or health check triggers an automatic rollback to the last known good commit.
- **No Downtime**: Only changed stacks are redeployed.

