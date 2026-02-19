# Publish New App: Checklist

Use this checklist for every new application deployment. Reference [NEW_APP_SOP.md](NEW_APP_SOP.md) for detailed commands.

## 📋 App Definition
```text
APP_NAME=
SUBDOMAIN=
DOMAIN=valhallala.com
INTERNAL_PORT=
VPS_IP=167.86.84.248
CLOUDFLARE_PROXY=ON
PUBLIC_URL=https://<SUBDOMAIN>.<DOMAIN>
SECRET_SOURCE=bible:vps/<APP_NAME>.env
```

## 🟩 Phase 1: Local Development & Preflight
- [ ] `scripts/new_app_scaffold.sh` executed
- [ ] Image tag is pinned (PRACTICE: `image: <name>:<version>`)
- [ ] Resource limits verified (`mem_limit`, `cpus`)
- [ ] Healthcheck verified
- [ ] `env_file` set to `/srv/secrets/<APP_NAME>.env`
- [ ] Traefik Host rule uses **backticks**: `Host(\`<SUBDOMAIN>.<DOMAIN>\`)`
- [ ] `docker compose config` passed locally

## 🟦 Phase 2: Secrets & DNS (External)
- [ ] Secret file added to private **bible** repo: `vps/<APP_NAME>.env`
- [ ] Bible repo pushed
- [ ] Cloudflare A Record created and Proxied

## 🚀 Phase 3: Deployment
- [ ] `git push origin master` (eddycontabovps)
- [ ] GitHub Action summary shows success

## ✅ Definition of Done (DoD)
- [ ] `docker ps` status: `Up (healthy)`
- [ ] `docker inspect <container> | grep Host` shows correct backticked rule
- [ ] Traefik logs show NO "Unable to obtain ACME certificate" errors for the host
- [ ] `curl -I https://<SUBDOMAIN>.<DOMAIN>` returns `200`
- [ ] `curl --resolve` (bypass CF) returns `200`
