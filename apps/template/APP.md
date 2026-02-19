# App Manifest: {{APP_NAME}}

## 📋 Architectural Details
- **App Name**: {{APP_NAME}}
- **Domain**: {{SUBDOMAIN}}.valhallala.com
- **Internal Port**: {{INTERNAL_PORT}}
- **Docker Image**: {{IMAGE}} (PINNED)

## 🔒 Secrets
- **Bible Source**: `vps/{{APP_NAME}}.env`
- **VPS Runtime Path**: `/srv/secrets/{{APP_NAME}}.env`

## ✅ Verification
- **Endpoint**: `https://{{SUBDOMAIN}}.valhallala.com`
- **Expected Status**: `200 OK`
- **Direct Audit**: `curl -skI --resolve {{SUBDOMAIN}}.valhallala.com:443:167.86.84.248 https://{{SUBDOMAIN}}.valhallala.com`
