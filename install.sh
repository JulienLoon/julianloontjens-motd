#!/bin/bash
#
# install.sh – Installer for julianloontjens-motd
# GitHub: https://github.com/JulienLoon/julianloontjens-motd
# Author: Julian Loontjens
# Version: 1.4

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
echo -e "${RESET}${BOLD}\n      Julian Loontjens MOTD Installer${RESET}\n"

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✗ This script must be run as root.${RESET}"
    echo "Try: sudo ./install.sh"
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

# --- Paths ---
MOTD_SRC="$(pwd)/motd"
MOTD_DEST="/etc/update-motd.d"
BACKUP_DIR="/etc/update-motd.d.backup-$(date +%Y%m%d-%H%M%S)"

# --- Check motd folder ---
if [ ! -d "$MOTD_SRC" ]; then
    echo -e "${RED}✗ Error: motd/ directory not found.${RESET}"
    echo "Run this script from the root of the cloned repository."
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

echo -e "${CYAN}▶ Starting installation...${RESET}"
sleep 0.4

# --- Backup current MOTD ---
echo -e "${YELLOW}→ Backing up existing MOTD to:${RESET} $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -a "$MOTD_DEST"/* "$BACKUP_DIR"/ 2>/dev/null || true
sleep 0.4

# --- Install new files ---
echo -e "${YELLOW}→ Installing new MOTD scripts...${RESET}"
cp -a "$MOTD_SRC"/* "$MOTD_DEST"/
sleep 0.4

# --- Set permissions ---
echo -e "${YELLOW}→ Setting permissions...${RESET}"
chmod 755 "$MOTD_DEST"/*
chown root:root "$MOTD_DEST"/*
sleep 0.3

# --- Disable non-Julian files ---
echo -e "${YELLOW}→ Disabling other MOTD scripts...${RESET}"

ALLOWED=(
    "00-header"
    "01-system-info"
    "02-resources"
    "03-network"
    "10-footer"
)

for FILE in "$MOTD_DEST"/*; do
    BASENAME=$(basename "$FILE")
    if [[ ! " ${ALLOWED[*]} " =~ " ${BASENAME} " ]]; then
        chmod -x "$FILE" 2>/dev/null || true
        echo "   Disabled: $BASENAME"
    fi
done

# --- Done ---
echo
echo -e "${GREEN}✓ Installation complete!${RESET}"
echo -e "Backup directory: ${YELLOW}${BACKUP_DIR}${RESET}\n"

# --- Preview ---
read -p "Would you like to preview the MOTD now? (y/n) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${CYAN}────────── MOTD PREVIEW ──────────${RESET}\n"
    run-parts /etc/update-motd.d/
    echo -e "\n${CYAN}──────────────────────────────────${RESET}\n"
fi

echo -e "${BOLD}Installation finished.${RESET}"
echo -e "Press any key to continue..."
read -n 1 -s
clear
