# Eddy VPS Architecture Overview

## Folder Structure
- `/srv/infra/traefik`: Traefik v2 reverse proxy configuration.
- `/srv/apps/`: Individual application stacks.
- `/srv/deploy.sh`: Global deployment script.

## Deployment Flow
1. Create a new directory in `/srv/apps/`.
2. Add a `docker-compose.yml` (see `/srv/apps/app-template/`).
3. Ensure the app joins the `proxy` network.
4. Run `/srv/deploy.sh <app-name>`.

## Adding New Apps
Standard labeling for Traefik:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.my-app.rule=Host(`my-app.valhallala.com`)"
  - "traefik.http.routers.my-app.entrypoints=websecure"
  - "traefik.http.routers.my-app.tls.certresolver=letsencrypt"
```

## Backup & Disaster Recovery
- Backup volumes via `docker run --rm --volumes-from <container> -v $(pwd):/backup alpine tar cvf /backup/data.tar /data`.
- Rollback: `git revert` + `./deploy.sh <app-name>`.
