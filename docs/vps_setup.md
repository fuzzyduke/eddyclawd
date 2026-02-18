# Private VPS Setup Guide for eddyclawd

This guide outlines the steps to prepare your private VPS for hosting `eddyclawd`.

## Prerequisites
- A Linux VPS (Ubuntu 22.04+ recommended).
- Docker and Docker Compose installed.
- SSH access.

## Installation Steps

1. **Connect to your VPS**:
   ```bash
   ssh your-user@your-vps-ip
   ```

2. **Clone the repository**:
   ```bash
   git clone <your-repo-url> eddyclawd
   cd eddyclawd
   ```

3. **Deploy with Docker**:
   ```bash
   docker compose up -d
   ```

4. **Initialize OpenClaw**:
   ```bash
   docker exec -it eddyclawd openclaw onboard
   ```

5. **Access the Dashboard**:
   The dashboard will be available at `http://your-vps-ip:18789`.

## Security Notes
- Ensure port `18789` is open in your VPS firewall (UFW/Security Groups).
- Consider setting up a reverse proxy (like Nginx) with SSL if you plan to access the dashboard over the public internet.
