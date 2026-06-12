#!/usr/bin/env bash

set -Eeuo pipefail

LOG_FILE="/var/log/zipline-install.log"

GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[36m"
RESET="\e[0m"

SPINNER='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

banner() {
clear

cat << "EOF"
╔══════════════════════════════════════════════════════╗
║                                                      ║
║      ███████╗██╗██████╗ ██╗     ██╗███╗   ██╗       ║
║      ╚══███╔╝██║██╔══██╗██║     ██║████╗  ██║       ║
║        ███╔╝ ██║██████╔╝██║     ██║██╔██╗ ██║       ║
║       ███╔╝  ██║██╔═══╝ ██║     ██║██║╚██╗██║       ║
║      ███████╗██║██║     ███████╗██║██║ ╚████║       ║
║      ╚══════╝╚═╝╚═╝     ╚══════╝╚═╝╚═╝  ╚═══╝       ║
║                                                      ║
║              Zipline Installer v1.0                 ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
EOF
}

run_step() {
local message="$1"
shift

```
printf "%s " "$message"

(
    "$@"
) >> "$LOG_FILE" 2>&1 &

local pid=$!

while kill -0 "$pid" 2>/dev/null; do
    for i in $(seq 0 9); do
        printf "\r%s ${BLUE}%s${RESET}" "$message" "${SPINNER:$i:1}"
        sleep 0.1
    done
done

wait "$pid"
local rc=$?

if [ $rc -eq 0 ]; then
    printf "\r%s ${GREEN}✓${RESET}\n" "$message"
else
    printf "\r%s ${RED}✗${RESET}\n" "$message"
    echo
    echo "Installation failed."
    echo "Check: $LOG_FILE"
    exit 1
fi
```

}

if [ "$EUID" -ne 0 ]; then
echo "Please run as root."
exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

banner

echo "[$(date '+%H:%M:%S')] Checking system requirements..."

if ! grep -qi debian /etc/os-release; then
echo "Unsupported operating system."
exit 1
fi

VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)

echo "[$(date '+%H:%M:%S')] Debian ${VERSION} detected"
echo

run_step "Updating packages..." bash -c '
apt-get update &&
apt-get upgrade -y &&
apt-get autoremove -y
'

run_step "Installing dependencies..." bash -c '
apt-get install -y 
curl 
wget 
git 
unzip 
openssl 
ca-certificates 
gnupg
'

run_step "Installing Docker Engine..." bash -c '
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg 
| gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo 
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] 
https://download.docker.com/linux/debian 
$(. /etc/os-release && echo $VERSION_CODENAME) stable" \

> /etc/apt/sources.list.d/docker.list

apt-get update

apt-get install -y 
docker-ce 
docker-ce-cli 
containerd.io 
docker-buildx-plugin 
docker-compose-plugin

systemctl enable docker
systemctl restart docker
'

run_step "Downloading Zipline..." bash -c '
mkdir -p /opt/zipline
cd /opt/zipline

curl -fsSL https://zipline.diced.sh/docker-compose.yml 
-o docker-compose.yml
'

run_step "Generating secrets..." bash -c '
cd /opt/zipline

POSTGRESQL_PASSWORD=$(openssl rand -base64 48 | tr -dc A-Za-z0-9 | head -c 32)
CORE_SECRET=$(openssl rand -base64 48 | tr -dc A-Za-z0-9 | head -c 32)

cat > .env << EOF
POSTGRESQL_PASSWORD=${POSTGRESQL_PASSWORD}
CORE_SECRET=${CORE_SECRET}
EOF

mkdir -p uploads
'

run_step "Starting containers..." bash -c '
cd /opt/zipline

docker compose pull
docker compose up -d
'

IP=$(curl -4 -s https://api.ipify.org || hostname -I | awk "{print $1}")

DOCKER_STATUS="Stopped"
ZIPLINE_STATUS="Stopped"

if systemctl is-active --quiet docker; then
DOCKER_STATUS="Running"
fi

if docker ps --format "{{.Names}}" | grep -qi zipline; then
ZIPLINE_STATUS="Running"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo -e "${GREEN}Installation Complete${RESET}"
echo
printf " %-10s %s\n" "URL:" "http://${IP}:3000"
printf " %-10s %s\n" "Docker:" "$DOCKER_STATUS"
printf " %-10s %s\n" "Zipline:" "$ZIPLINE_STATUS"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Logs: $LOG_FILE"
echo
