# Eddy VPS Platform

This repository is the **Source of Truth** for the Eddy Contabo VPS. It uses a fully deterministic, GitHub-driven deployment workflow.

## 🏗️ Architecture
- **Infrastructure**: Traefik-based reverse proxy with automated SSL.
- **Orchestration**: Docker Compose (no Swarm, no Dokploy).
- **Automation**: Root level `deploy.sh` manages all stacks.
- **Trigger**: GitHub Actions on push to `main`.

## 📁 Repository Structure
- `/.github/workflows/`: CI/CD pipelines.
- `/apps/`: Individual application stacks (e.g., `eddyclawd`).
- `/infra/`: Shared infrastructure (Traefik, networks).
- `/docs/`: Standard Operating Procedures and Rules.

## 🚀 Deployment Workflow
1. Commit changes to `/apps` or `/infra`.
2. Push to `main`.
3. GitHub Actions SSHs into the VPS and executes `/srv/deploy.sh`.
4. The system detects changed folders, validates configuration, and redeploys safely.

## 🛡️ Safety & Reliability
- **Drift Protection**: Deployment fails if uncommitted local changes exist on the VPS.
- **Validation**: Every stack is validated via `docker compose config` before restart.
- **Health Checks**: Deployment waits for containers to be healthy.
- **Upgrades**: Versioned upgrades are handled via `UPGRADE.md` scripts.

## 🛠️ Adding New Apps
See [DEPLOYMENT_RULES.md](./docs/DEPLOYMENT_RULES.md) for the contract and [/apps/template](./apps/template) for blueprints.
