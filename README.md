# Zipline VPS Setup

This repository contains a bash script to quickly set up Zipline (self-hosted file upload server) on a fresh Debian 13 VPS using Docker.

## Features
- Updates and upgrades the system
- Installs Docker
- Sets up Zipline with PostgreSQL via Docker Compose
- Nice colored CLI output
- Prints access URL with public IP

## Quick Start
1. Download the script:
   ```bash
   curl -LO https://your-domain-or-ip/setup-zipline.sh  # Or copy from artifacts
   ```
2. Make executable:
   ```bash
   chmod +x setup-zipline.sh
   ```
3. Run:
   ```bash
   sudo ./setup-zipline.sh
   ```

## Files
- `setup-zipline.sh`: Main installation script
- `MANUAL.txt`: Detailed manual

## Access
After setup, visit `http://YOUR_VPS_IP:3000`

## Management
- Directory: `/opt/zipline`
- Logs: `cd /opt/zipline && docker compose logs -f`
- Restart: `docker compose restart`
- Update: `docker compose pull && docker compose up -d`

For more, see official docs: https://zipline.diced.sh
