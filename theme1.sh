#!/bin/bash

# ==========================================
#        CARBON THEME INSTALLER v2
# ==========================================

REPO_URL="https://github.com/MuhammadAliUsman/carbon-them.git"
TEMP_DIR="/tmp/carbon-theme"
DEFAULT_PATH="/var/www/pterodactyl"
PTERO_PATH=""
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ===== Colors =====
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

pause() {
    read -p "Press Enter to continue..."
}

detect_panel() {
    if [ -d "$DEFAULT_PATH" ]; then
        PTERO_PATH="$DEFAULT_PATH"
    else
        PTERO_PATH=$(find / -type d -name "pterodactyl" 2>/dev/null | head -n 1)
    fi

    if [ -z "$PTERO_PATH" ]; then
        echo -e "${RED}❌ Pterodactyl panel not found!${NC}"
        exit 1
    fi

    echo -e "${CYAN}✔ Panel detected at:${NC} $PTERO_PATH"
}

install_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Git not found. Installing...${NC}"
        apt update && apt install git -y
    fi
}

backup_panel() {
    BACKUP_DIR="$PTERO_PATH/carbon_backup_$TIMESTAMP"
    echo -e "${YELLOW}Creating backup at:${NC} $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$PTERO_PATH/resources/views" "$BACKUP_DIR/"
    cp -r "$PTERO_PATH/public" "$BACKUP_DIR/"
    echo -e "${GREEN}✔ Backup completed${NC}"
}

clear_cache() {
    cd "$PTERO_PATH" || exit
    php artisan view:clear
    php artisan cache:clear
}

install_theme() {
    clear
    echo -e "${CYAN}Installing Carbon Theme...${NC}"

    detect_panel
    install_git
    backup_panel

    rm -rf "$TEMP_DIR"
    git clone "$REPO_URL" "$TEMP_DIR"

    if [ ! -d "$TEMP_DIR" ]; then
        echo -e "${RED}❌ Failed to clone repository${NC}"
        exit 1
    fi

    echo -e "${CYAN}Applying theme files...${NC}"
    cp -r "$TEMP_DIR/"* "$PTERO_PATH/"

    chown -R www-data:www-data "$PTERO_PATH"
    chmod -R 755 "$PTERO_PATH"

    clear_cache

    echo -e "${GREEN}✅ Carbon Theme Installed Successfully!${NC}"
    pause
}

uninstall_theme() {
    clear
    echo -e "${CYAN}Available Backups:${NC}"
    ls -d $PTERO_PATH/carbon_backup_* 2>/dev/null

    read -p "Enter full backup folder name to restore: " RESTORE_DIR

    if [ ! -d "$RESTORE_DIR" ]; then
        echo -e "${RED}❌ Backup not found${NC}"
        pause
        return
    fi

    echo -e "${YELLOW}Restoring backup...${NC}"

    rm -rf "$PTERO_PATH/resources/views"
    rm -rf "$PTERO_PATH/public"

    cp -r "$RESTORE_DIR/views" "$PTERO_PATH/resources/"
    cp -r "$RESTORE_DIR/public" "$PTERO_PATH/"

    chown -R www-data:www-data "$PTERO_PATH"
    chmod -R 755 "$PTERO_PATH"

    clear_cache

    echo -e "${GREEN}✅ Backup Restored Successfully!${NC}"
    pause
}

update_theme() {
    clear
    echo -e "${CYAN}Updating Carbon Theme...${NC}"
    install_theme
}

menu() {
    clear
    echo -e "${CYAN}=================================${NC}"
    echo -e "${CYAN}      CARBON INSTALLER v2       ${NC}"
    echo -e "${CYAN}=================================${NC}"
    echo "1) Install Carbon Theme"
    echo "2) Uninstall (Restore Backup)"
    echo "3) Update Theme"
    echo "0) Exit"
    echo -e "${CYAN}=================================${NC}"
    read -p "Select option: " choice

    case $choice in
        1) install_theme ;;
        2) uninstall_theme ;;
        3) update_theme ;;
        0) exit 0 ;;
        *) echo "Invalid option"; pause ;;
    esac
}

while true; do
    menu
done
