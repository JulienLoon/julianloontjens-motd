#!/bin/bash
#
# uninstall.sh – Uninstaller for julianloontjens-motd
# GitHub: https://github.com/JulienLoon/julianloontjens-motd
# Author: Julian Loontjens
# Version: 1.7

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
echo -e "${RESET}${BOLD}\n      Julian Loontjens MOTD Uninstaller${RESET}\n"

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✗ This script must be run as root.${RESET}"
    echo "Try: sudo ./uninstall.sh"
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

# --- Paths ---
MOTD_DIR="/etc/update-motd.d"

# --- Find latest backup ---
LATEST_BACKUP=$(ls -td /etc/update-motd.d.backup-* 2>/dev/null | head -n 1 || true)

if [[ -z "$LATEST_BACKUP" ]]; then
    echo -e "${RED}✗ No backup found.${RESET}"
    echo "Nothing to restore."
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

echo -e "${CYAN}▶ Starting MOTD uninstallation...${RESET}"
sleep 0.4

# --- Restore Ubuntu default MOTD scripts using dpkg-divert remove ---
UBUNTU_MOTD=(
  10-help-text
  50-landscape-sysinfo
  50-motd-news
  90-updates-available
  91-contract-ua-esm-status
  91-release-upgrade
  92-unattended-upgrades
  95-hwe-eol
  97-overlayroot
  98-fsck-at-reboot
  98-reboot-required
)

for f in "${UBUNTU_MOTD[@]}"; do
    SCRIPT_PATH="$MOTD_DIR/$f"
    DIVERTED=$(dpkg-divert --list 2>/dev/null | grep "$SCRIPT_PATH" || true)
    if [[ -n "$DIVERTED" ]]; then
        echo -e "${YELLOW}→ Removing dpkg-divert for $f...${RESET}"
        dpkg-divert --quiet --remove --divert "$SCRIPT_PATH.ubuntu" "$SCRIPT_PATH" || true
    fi
done
sleep 0.3

# --- Remove current MOTD scripts ---
echo -e "${YELLOW}→ Removing current MOTD scripts...${RESET}"
rm -f "${MOTD_DIR}"/* 2>/dev/null || true
sleep 0.4

# --- Restore backup ---
echo -e "${YELLOW}→ Restoring backup from:${RESET} ${LATEST_BACKUP}"
cp -a "${LATEST_BACKUP}/"* "${MOTD_DIR}/"
chmod 755 "${MOTD_DIR}"/*
chown root:root "${MOTD_DIR}"/*
sleep 0.4

# --- Reinstall landscape-common to restore default MOTD behavior ---
echo -e "${YELLOW}→ Reinstalling landscape-common to restore default Ubuntu MOTD behavior...${RESET}"
if ! dpkg -l | grep -q landscape-common; then
    apt-get update
    apt-get install -y landscape-common
    echo "   landscape-common reinstalled."
else
    echo "   landscape-common already installed."
fi
sleep 0.3

echo
echo -e "${GREEN}✓ Restoration complete!${RESET}"
echo -e "Backup used: ${YELLOW}${LATEST_BACKUP}${RESET}\n"

# --- Preview ---
read -p "Would you like to preview the restored MOTD? (y/n) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${CYAN}────────── MOTD PREVIEW ──────────${RESET}\n"
    run-parts /etc/update-motd.d/
    echo -e "\n${CYAN}──────────────────────────────────${RESET}\n"
fi

echo -e "${BOLD}Uninstallation finished.${RESET}"
echo -e "Press any key to continue..."
read -n 1 -s
clear
