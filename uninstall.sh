#!/bin/bash
#
# uninstall.sh – Uninstaller for julianloontjens-motd
# Restores the previous /etc/update-motd.d configuration
# Author: Julian Loontjens
# Version: 1.0

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
echo -e "${RESET}${BOLD}\n      Julian Loontjens MOTD Uninstaller${RESET}"
echo

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✗ This script must be run as root.${RESET}"
    echo "Try: sudo ./uninstall.sh"
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

# --- Variables ---
MOTD_DIR="/etc/update-motd.d"
BACKUP_BASE="/etc/update-motd.d.backup-*"

# --- Find latest backup ---
LATEST_BACKUP=$(ls -td /etc/update-motd.d.backup-* 2>/dev/null | head -n 1)

if [ -z "$LATEST_BACKUP" ]; then
    echo -e "${RED}✗ No backup directory found.${RESET}"
    echo "Nothing to restore. Exiting."
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo -e "${CYAN}▶ Starting MOTD uninstallation...${RESET}"
sleep 0.5

# --- Remove current MOTD ---
echo -e "${YELLOW}→ Removing current MOTD scripts from ${MOTD_DIR}${RESET}"
rm -f ${MOTD_DIR}/* 2>/dev/null || true
sleep 0.5

# --- Restore backup ---
echo -e "${YELLOW}→ Restoring from backup: ${LATEST_BACKUP}${RESET}"
cp -a "${LATEST_BACKUP}/"* "${MOTD_DIR}/"
chmod 755 "${MOTD_DIR}"/*
chown root:root "${MOTD_DIR}"/*
sleep 0.5

# --- Confirmation ---
echo
echo -e "${GREEN}✓ Restoration complete!${RESET}"
echo -e "Your previous MOTD configuration has been restored."
echo -e "Backup used: ${YELLOW}${LATEST_BACKUP}${RESET}"
echo

# --- Optional preview ---
read -p "Would you like to preview the restored MOTD? (y/n) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${CYAN}───────────────────── MOTD PREVIEW ─────────────────────${RESET}\n"
    run-parts /etc/update-motd.d/
    echo -e "\n${CYAN}────────────────────────────────────────────────────────${RESET}\n"
fi

echo
echo -e "${BOLD}${CYAN}Uninstallation finished successfully.${RESET}"
echo -e "Press any key to continue..."
read -n 1 -s
echo
clear