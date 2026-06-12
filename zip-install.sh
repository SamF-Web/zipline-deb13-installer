#!/bin/bash

# Colors for nice CLI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${GREEN}Zipline VPS Setup Script for Debian 13${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Functions for status messages
print_status() { 
    echo -e "${GREEN}[✓] $1${NC}"
}
print_error() { 
    echo -e "${RED}[✗] $1${NC}"
}
print_warning() { 
    echo -e "${YELLOW}[!] $1${NC}"
}

# 1. Update and upgrade
echo -e "${BLUE}Step 1: Updating and upgrading system...${NC}"
apt-get update -qq && apt-get upgrade -y -qq
print_status "System updated and upgraded"

# 2. Install Docker (following your manual closely)
echo -e "${BLUE}Step 2: Installing Docker...${NC}"
apt-get install -y ca-certificates curl gnupg lsb-release

# Docker official install
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | tee /etc/apt/keyrings/docker.asc > /dev/null
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo \$VERSION_CODENAME) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -qq
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker
systemctl enable --now docker
print_status "Docker installed and enabled"

# Verify
if docker --version > /dev/null 2>&1; then
    print_status "Docker verified"
else
    print_error "Docker installation failed"
    exit 1
fi

# 3. Setup Zipline
echo -e "${BLUE}Step 3: Setting up Zipline with Docker...${NC}"
mkdir -p /opt/zipline
cd /opt/zipline

curl -LO https://zipline.diced.sh/docker-compose.yml
print_status "docker-compose.yml downloaded"

# Secure secrets
echo "POSTGRESQL_PASSWORD=$(openssl rand -base64 42 | tr -dc A-Za-z0-9 | cut -c -32 | tr -d '\n')" > .env
echo "CORE_SECRET=$(openssl rand -base64 42 | tr -dc A-Za-z0-9 | cut -c -32 | tr -d '\n')" >> .env
print_status ".env file generated with secure secrets"

docker compose pull
docker compose up -d
print_status "Zipline started"

IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
print_status "Public IP detected: $IP"

echo ""
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}Access Zipline at: http://$IP:3000${NC}"
echo -e "${YELLOW}First time: Complete the setup wizard for admin account.${NC}"
echo -e "${BLUE}===============================================${NC}"

echo -e "\n${BLUE}Container Status:${NC}"
docker compose ps

echo -e "\n${GREEN}All done! Enjoy Zipline.${NC}"
