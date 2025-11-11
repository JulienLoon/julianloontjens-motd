#!/bin/bash
#
# install.sh – Installer for julianloontjens-motd
# GitHub: https://github.com/JulienLoon/julianloontjens-motd
# Author: Julian Loontjens
# Version: 1.2

set -e

# --- Colors ---
BOLD="\033[1m"
CYAN="\033[36m"
YELLOW="\033[33m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

clear
echo -e "${CYAN}"
cat << "EOF"
       ____  ____    _______    _   __   __    ____  ____  _   ________  _________   _______
      / / / / / /   /  _/   |  / | / /  / /   / __ \/ __ \/ | / /_  __/ / / ____/ | / / ___/
 __  / / / / / /    / // /| | /  |/ /  / /   / / / / / / /  |/ / / /_  / / __/ /  |/ /\__ \ 
/ /_/ / /_/ / /____/ // ___ |/ /|  /  / /___/ /_/ / /_/ / /|  / / / /_/ / /___/ /|  /___/ / 
\____/\____/_____/___/_/  |_/_/ |_/  /_____/\____/\____/_/ |_/ /_/\____/_____/_/ |_//____/ 
EOF
echo -e "${RESET}${BOLD}\n      Julian Loontjens MOTD Installer${RESET}"
echo

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✗ This script must be run as root.${RESET}"
    echo "Try: sudo ./install.sh"
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

# --- Paths ---
MOTD_SRC="$(pwd)/motd"
MOTD_DEST="/etc/update-motd.d"
BACKUP_DIR="/etc/update-motd.d.backup-$(date +%Y%m%d-%H%M%S)"

# --- Verify source ---
if [ ! -d "$MOTD_SRC" ]; then
    echo -e "${RED}✗ Error: 'motd/' directory not found in current path.${RESET}"
    echo "Please run this script from the root of the cloned repository."
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo -e "${CYAN}▶ Starting installation...${RESET}"
sleep 0.5

# --- Backup existing MOTD ---
if [ -d "$MOTD_DEST" ]; then
    echo -e "${YELLOW}→ Backing up current MOTD to ${BACKUP_DIR}${RESET}"
    mkdir -p "$BACKUP_DIR"
    cp -a "$MOTD_DEST"/* "$BACKUP_DIR"/ 2>/dev/null || true
    sleep 0.5
fi

# --- Install new files ---
echo -e "${YELLOW}→ Copying new MOTD files...${RESET}"
cp -a "$MOTD_SRC"/* "$MOTD_DEST"/
sleep 0.5

# --- Set permissions on your files ---
echo -e "${YELLOW}→ Setting permissions on new files...${RESET}"
chmod 755 "$MOTD_DEST"/*
chown root:root "$MOTD_DEST"/*

# --- Disable all other MOTD scripts that are not yours ---
echo -e "${YELLOW}→ Disabling other MOTD scripts not part of your package...${RESET}"
for f in "$MOTD_DEST"/*; do
    BASENAME=$(basename "$f")
    # Check if this file exists in your source directory
    if [ ! -f "$MOTD_SRC/$BASENAME" ]; then
        chmod -x "$f" 2>/dev/null || true
        echo "   Disabled $BASENAME"
    fi
done

# --- Done ---
echo
echo -e "${GREEN}✓ Installation complete!${RESET}"
echo -e "${BOLD}Your new MOTD will appear on the next login.${RESET}"
echo -e "Backup created at: ${YELLOW}${BACKUP_DIR}${RESET}"
echo

# --- Optional preview ---
read -p "Would you like to preview it now? (y/n) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${CYAN}───────────────────── MOTD PREVIEW ─────────────────────${RESET}\n"
    run-parts /etc/update-motd.d/
    echo -e "\n${CYAN}────────────────────────────────────────────────────────${RESET}\n"
fi

echo
echo -e "${BOLD}${CYAN}Installation finished successfully.${RESET}"
echo -e "Press any key to continue..."
read -n 1 -s
echo
clear