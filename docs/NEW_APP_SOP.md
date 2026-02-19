# SOP: New App Creation & Publishing

This document defines the deterministic pipeline for onboarding a new application to the Eddy VPS.

## 1. Required Inputs

Before starting, define these variables:
- **APP_NAME**: Unique lowercase identifier (e.g., `hello-world`).
- **SUBDOMAIN**: Subdomain for the app (e.g., `hello`).
- **DOMAIN**: Primary domain (usually `valhallala.com`).
- **INTERNAL_PORT**: The port the application listens on within the container (e.g., `80`).
- **IMAGE**: Pinned Docker image tag (e.g., `nginx:1.27-alpine`). **DO NOT USE `latest`**.
- **RESOURCES**: Memory limit (e.g., `256m`) and CPU limit (e.g., `0.5`).
- **HEALTHCHECK**: Command to verify app health (e.g., `wget -qO- http://localhost:80`).
- **VPS_IP**: `167.86.84.248`

## 2. Step-by-Step Instructions

### Step A: Scaffolding
1. Run the scaffolding helper:
   ```bash
   ./scripts/new_app_scaffold.sh <APP_NAME> <SUBDOMAIN> <INTERNAL_PORT>
   ```

### Step B: DNS Configuration (Cloudflare)
**CRITICAL**: Cloudflare DNS must exist BEFORE deployment to ensure ACME (SSL) issuance succeeds.
1. Create a **Cloudflare A record**:
   - **Name**: `<SUBDOMAIN>`
   - **Content**: `167.86.84.248`
   - **Proxy status**: `ON` (Proxied)
   - **TTL**: `Auto`

### Step C: Secrets Management (Private Bible)
1. Add `<APP_NAME>.env` to the `vps/` directory in the private **bible** repository.
2. Push changes to the bible repository.

### Step D: Local Preflight
Before pushing, verify the following in `apps/<APP_NAME>/docker-compose.yml`:
- [ ] Run `docker compose -f apps/<APP_NAME>/docker-compose.yml config` to check syntax.
- [ ] Ensure **no** `ports:` key is present (host port exposure is forbidden).
- [ ] Ensure `image:` is pinned (e.g., `nginx:1.27-alpine`) and not `latest`.
- [ ] Ensure `env_file:` is exactly `/srv/secrets/<APP_NAME>.env`.
- [ ] Ensure `mem_limit:` and `cpus:` are present and reasonable.
- [ ] Ensure `healthcheck:` section is present and correct.
- [ ] Ensure Traefik labels use canonical **backticks** for the Host rule.

### Step E: Publishing
1. Commit and push the public `eddycontabovps` repository:
   ```bash
   git add .
   git commit -m "feat: onboard <APP_NAME>"
   git push origin master
   ```

## 3. Verification Commands

Run these on the VPS (or via SSH) to confirm success:
- **Service Registration**: `docker exec traefik wget -qO- http://localhost:8080/api/rawdata | grep <APP_NAME>`
- **Live Response (Cloudflare)**: `curl -f -I https://<SUBDOMAIN>.<DOMAIN>`
- **Cloudflare Bypass (Direct VPS Audit)**:
  ```bash
  curl -sI -k --resolve <SUBDOMAIN>.<DOMAIN>:443:167.86.84.248 https://<SUBDOMAIN>.<DOMAIN> | head -n 1
  ```
  *(Should return HTTP 200)*
- **Traefik Logs**: `docker logs traefik 2>&1 | grep <SUBDOMAIN> | tail -n 20`
