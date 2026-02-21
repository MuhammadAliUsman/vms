#!/bin/bash

# ==============================
#        COLOR CONFIG
# ==============================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

echo -e "${GREEN}🚀 Starting Blueprint Auto-Installer...${RESET}"

# ==============================
#   CHECK PTERODACTYL PATH
# ==============================
if [ ! -d "/var/www/pterodactyl" ]; then
    echo -e "${RED}❌ Path /var/www/pterodactyl not found!${RESET}"
    exit 1
fi

cd /var/www/pterodactyl || exit 1

# ==============================
#        CLONE REPO
# ==============================

echo -e "${YELLOW}📥 Cloning GitHub repository...${RESET}"

GIT_REPO="https://github.com/MuhammadAliUsman/blueprints.git"

# Remove any old clone
rm -rf blueprints-temp

git clone "$GIT_REPO" blueprints-temp || {
    echo -e "${RED}❌ Git clone failed! Check internet or URL.${RESET}"
    exit 1
}

cd blueprints-temp || exit 1

# ==============================
#      INSTALL BLUEPRINTS
# ==============================

echo -e "${GREEN}🛠 Installing blueprints...${RESET}"

blueprint -i serverimporter.blueprint
blueprint -i serversplitter.blueprint
blueprint -i simplefavicons.blueprint
blueprint -i simplefooters.blueprint
blueprint -i versionchanger.blueprint
blueprint -i darkenate.blueprint
blueprint -i huxregister.blueprint
blueprint -i mcplugins.blueprint
blueprint -i playerlisting.blueprint
blueprint -i sagaautosuspension.blueprint
blueprint -i sagaminecraftplayermanager.blueprint

# ==============================
#          CLEANUP
# ==============================

cd ..
rm -rf blueprints-temp

echo -e "${GREEN}✅ All blueprints installed successfully!${RESET}"
