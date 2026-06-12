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

# Function to print status
print_status() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# 1. Update and upgrade system
echo -e "${BLUE}Step 1: Updating and upgrading system...${NC}"
apt-get update -qq && apt-get upgrade -y -qq
print_status "System updated and upgraded"

# 2. Install Docker
echo -e "${BLUE}Step 2: Installing Docker...${NC}"
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -qq
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
print_status "Docker installed"

# Verify Docker
if docker --version > /dev/null 2>&1; then
    print_status "Docker verified"
else
    print_error "Docker installation failed"
    exit 1
fi

# 3. Setup Zipline
echo -e "${BLUE}Step 3: Setting up Zipline with Docker...${NC}"

# Create directory
mkdir -p /opt/zipline
cd /opt/zipline

# Download docker-compose.yml
curl -LO https://zipline.diced.sh/docker-compose.yml
print_status "docker-compose.yml downloaded"

# Generate .env
echo "POSTGRESQL_PASSWORD=$(openssl rand -base64 42 | tr -dc A-Za-z0-9 | cut -c -32 | tr -d '\n')" > .env
echo "CORE_SECRET=$(openssl rand -base64 42 | tr -dc A-Za-z0-9 | cut -c -32 | tr -d '\n')" >> .env
print_status ".env file generated with secure secrets"

# Pull and run
docker compose pull
docker compose up -d
print_status "Zipline started"

# Get IP
IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
print_status "Public IP detected: $IP"

echo ""
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}Access Zipline at: http://$IP:3000${NC}"
echo -e "${YELLOW}First time: Complete the setup wizard for admin account.${NC}"
echo -e "${BLUE}===============================================${NC}"

# Status
echo -e "\n${BLUE}Container Status:${NC}"
docker compose ps

echo -e "\n${GREEN}All done! Enjoy Zipline.${NC}"
