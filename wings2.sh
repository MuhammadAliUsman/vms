#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# UI Elements
CHECKMARK="✓"
CROSSMARK="✗"
ARROW="➤"

print_header() {
    local text="$1"
    local width=42
    local text_length=${#text}
    local padding=$(( (width - text_length) / 2 ))
    printf "\n${MAGENTA}╔"
    printf '═%.0s' $(seq 1 $width)
    printf "╗${NC}\n"
    printf "${MAGENTA}║${NC}${CYAN}%*s%s%*s${NC}${MAGENTA}║${NC}\n" "$padding" "" "$text" "$padding" ""
    printf "${MAGENTA}╚"
    printf '═%.0s' $(seq 1 $width)
    printf "╝${NC}\n"
}

print_status() { echo -e "${YELLOW}${ARROW} $1...${NC}"; }
print_success() { echo -e "${GREEN}${CHECKMARK} $1${NC}"; }
print_error() { echo -e "${RED}${CROSSMARK} $1${NC}"; }

# Clear screen and show YOUR ASCII
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

echo -e "${CYAN}═══════════════════ 𝗗𝗥𝗔𝗚𝗢𝗡𝗖𝗟𝗢𝗨𝗗 𝗪𝗜𝗡𝗚𝗦 𝗠𝗘𝗡𝗨 ═══════════════════${NC}"
echo -e "${MAGENTA}1.${NC} Full Install (Install Docker + Wings)"
echo -e "${MAGENTA}2.${NC} Direct Install (Skip Docker Setup - Works on ANY VPS)"
echo -e "${MAGENTA}3.${NC} Exit"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
read -p "Select an option [1-3]: " OPTION

if [ "$OPTION" == "3" ] || [ -z "$OPTION" ]; then exit 1; fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# ------------------------
# 1. Docker Logic
# ------------------------
if [ "$OPTION" == "1" ]; then
    print_header "INSTALLING DOCKER"
    print_status "Installing Docker Engine"
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash
    # Try to enable but don't crash if it fails (Container check)
    systemctl enable --now docker > /dev/null 2>&1 || echo "Warning: Could not start Docker service automatically."
else
    print_header "USING EXISTING DOCKER"
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker not found! Install Docker on the host first."
        exit 1
    fi
    print_success "Docker is ready"
fi

# ------------------------
# 2. Wings Installation
# ------------------------
print_header "INSTALLING WINGS"
mkdir -p /etc/pterodactyl /var/lib/pterodactyl /var/log/pterodactyl
ARCH=$(uname -m)
[ "$ARCH" == "x86_64" ] && ARCH="amd64" || ARCH="arm64"

print_status "Downloading Wings binary ($ARCH)"
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH" > /dev/null 2>&1
chmod u+x /usr/local/bin/wings
print_success "Wings binary installed"

# ------------------------
# 3. Systemd / Service (Universal Check)
# ------------------------
if [ -d /run/systemd/system ]; then
    print_header "CONFIGURING SERVICE"
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
    print_success "Systemd service ready"
else
    print_status "Systemd not found (Container Mode). Manual start required."
fi

# ------------------------
# 4. SSL Generation
# ------------------------
print_header "SSL GENERATION"
mkdir -p /etc/certs/wing
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=DragonCloud" \
-keyout /etc/certs/wing/privkey.pem -out /etc/certs/wing/fullchain.pem > /dev/null 2>&1
print_success "Self-signed SSL generated"

# ------------------------
# 5. Helper Command
# ------------------------
tee /usr/local/bin/wing > /dev/null <<'EOF'
#!/bin/bash
echo -e "\033[1;33mℹ️  Wings Helper\033[0m"
echo -e "Start:   sudo systemctl start wings (or run 'wings' manually)"
echo -e "Logs:    sudo journalctl -u wings -f"
EOF
chmod +x /usr/local/bin/wing

# ------------------------
# 6. Auto-Config
# ------------------------
echo -e "\n${YELLOW}🔧 AUTO-CONFIGURATION${NC}"
read -p "Do you want to configure Wings now? (y/N): " AUTO_CONFIG

if [[ "$AUTO_CONFIG" =~ ^[Yy]$ ]]; then
    read -p "UUID: " UUID
    read -p "Token ID: " TID
    read -p "Token: " TOK
    read -p "Panel URL (e.g., https://panel.host.io): " URL

    tee /etc/pterodactyl/config.yml > /dev/null <<CFG
debug: false
uuid: ${UUID}
token_id: ${TID}
token: ${TOK}
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
remote: '${URL}'
CFG
    print_success "Config saved to /etc/pterodactyl/config.yml"
fi

print_header "INSTALLATION COMPLETE"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}      Thank you for using 𝗗𝗿𝗮𝗴𝗼𝗻𝗖𝗹𝗼𝘂𝗱      ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
