# App: eddyclawd

Our custom implementation of Clawdbot (OpenClaw).

## Deployment
Managed via the global `deploy.sh`. 

### Configuration
Variables live in a local `.env` file on the VPS:
- `OPENCLAW_PORT=18789`
- `NODE_ENV=production`

### Skills
AI Skills are stored in `./src/skills`.
