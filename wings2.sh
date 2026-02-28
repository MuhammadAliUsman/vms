#!/bin/bash
# DO NOT USE SET -E TO PREVENT CRASHING ON MINOR ERRORS
set +e 

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ASCII BRANDING
clear
echo -e "${BLUE}"
cat <<'EOF'
██╗     ██╗██╗███╗   ██╗ ██████╗ ███████╗    ██████╗  █████╗ ███████╗███╗   ███╗ ██████╗ ███╗   ██╗
██║     ██║██║████╗  ██║██╔════╝ ██╔════╝    ██╔══██╗██╔══██╗██╔════╝████╗ ████║██╔═══██╗████╗  ██║
██║ █╗  ██║██║██╔██╗ ██║██║  ███╗███████╗    ██║  ██║███████║█████╗  ██╔████╔██║██║   ██║██╔██╗ ██║
██║███╗ ██║██║██║╚██╗██║██║   ██║╚════██║    ██║  ██║██╔══██║██╔══╝  ██║╚██╔╝██║██║   ██║██║╚██╗██║
 ╚███╔███╔╝██║██║ ╚████║╚██████╔╝███████║    ██████╔╝██║  ██║███████╗██║ ╚═╝ ██║╚██████╔╝██║ ╚████║
  ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
EOF
echo -e "${NC}"

echo -e "${CYAN}═══════════════════ EMERGENCY WINGS INSTALLER ═══════════════════${NC}"

# 1. ARCH DETECTION
ARCH=$(uname -m)
[ "$ARCH" == "x86_64" ] && ARCH="amd64" || ARCH="arm64"

# 2. DIRECTORY CREATION
echo -e "${YELLOW}➤ Creating Directories...${NC}"
mkdir -p /etc/pterodactyl /var/lib/pterodactyl /var/log/pterodactyl /tmp/pterodactyl
echo -e "${GREEN}✓ Done${NC}"

# 3. DOWNLOAD WINGS (The Core Fix)
echo -e "${YELLOW}➤ Downloading Wings Binary...${NC}"
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH"
chmod u+x /usr/local/bin/wings
echo -e "${GREEN}✓ Wings installed to /usr/local/bin/wings${NC}"

# 4. DETECT IF IN DOCKER/CONTAINER
if [ -f /.dockerenv ] || [ ! -d /run/systemd/system ]; then
    echo -e "${MAGENTA}⚠ Container/Non-Systemd environment detected. Skipping services...${NC}"
else
    echo -e "${YELLOW}➤ Configuring Systemd Service...${NC}"
    tee /etc/systemd/system/wings.service > /dev/null <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
ExecStart=/usr/local/bin/wings
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable wings > /dev/null 2>&1
    echo -e "${GREEN}✓ Service Configured${NC}"
fi

# 5. SSL GENERATION
echo -e "${YELLOW}➤ Generating SSL...${NC}"
mkdir -p /etc/certs/wing
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=DragonCloud" \
-keyout /etc/certs/wing/privkey.pem -out /etc/certs/wing/fullchain.pem &> /dev/null
echo -e "${GREEN}✓ SSL Ready${NC}"

# 6. CONFIGURATION
echo -e "\n${CYAN}--- WINGS CONFIGURATION ---${NC}"
read -p "Enter UUID: " UUID
read -p "Enter Token ID: " TID
read -p "Enter Token: " TOK

# Save Config
tee /etc/pterodactyl/config.yml > /dev/null <<EOF
debug: false
uuid: $UUID
token_id: $TID
token: $TOK
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/certs/wing/fullchain.pem
    key: /etc/certs/wing/privkey.pem
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
remote: 'https://mc.dragoncl.qzz.io'
EOF

echo -e "${GREEN}✓ Configuration saved!${NC}"

# 7. EXECUTION
print_header "STARTING WINGS"
if [ -f /.dockerenv ] || [ ! -d /run/systemd/system ]; then
    echo -e "${YELLOW}To start Wings in this container, run:${NC}"
    echo -e "${GREEN}wings --debug${NC}"
else
    systemctl start wings
    echo -e "${GREEN}✓ Wings started via Systemd!${NC}"
fi

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}      Wings is now on your system!      ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
