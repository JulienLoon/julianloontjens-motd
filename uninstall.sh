#!/bin/bash
#
# uninstall.sh – Uninstaller for julianloontjens-motd
# GitHub: https://github.com/JulienLoon/julianloontjens-motd
# Author: Julian Loontjens
# Version: 1.8

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
DEFAULT_MOTD_SRC="$(pwd)/default-ubuntu-motd"

echo -e "${CYAN}▶ Starting MOTD uninstallation...${RESET}"
sleep 0.4

# --- Remove dpkg-divert for 10-help-text ---
HELP_TEXT="$MOTD_DIR/10-help-text"
DIVERTED=$(dpkg-divert --list 2>/dev/null | grep "$HELP_TEXT" || true)
if [[ -n "$DIVERTED" ]]; then
    echo -e "${YELLOW}→ Removing dpkg-divert for 10-help-text...${RESET}"
    dpkg-divert --quiet --remove --rename "$HELP_TEXT" 2>/dev/null || true
    sleep 0.3
fi

# --- Strategy 1: Try to restore from repo's default-ubuntu-motd ---
if [ -d "$DEFAULT_MOTD_SRC" ]; then
    echo -e "${YELLOW}→ Restoring default Ubuntu MOTD from repository...${RESET}"
    
    # Remove current MOTD scripts
    rm -f "${MOTD_DIR}"/* 2>/dev/null || true
    
    # Copy default Ubuntu MOTD from repo
    cp -a "$DEFAULT_MOTD_SRC"/* "$MOTD_DIR"/
    chmod 755 "$MOTD_DIR"/*
    chown root:root "$MOTD_DIR"/*
    
    echo "   Restored from: $DEFAULT_MOTD_SRC"
    sleep 0.4
    
    RESTORE_METHOD="repository defaults"

# --- Strategy 2: Fallback to latest backup ---
else
    echo -e "${YELLOW}→ default-ubuntu-motd not found in repo.${RESET}"
    echo -e "${YELLOW}→ Attempting to restore from backup...${RESET}"
    
    LATEST_BACKUP=$(ls -td /etc/update-motd.d.backup-* 2>/dev/null | head -n 1 || true)
    
    if [[ -z "$LATEST_BACKUP" ]]; then
        echo -e "${RED}✗ No backup found and no default-ubuntu-motd directory.${RESET}"
        echo "Cannot restore MOTD."
        read -n 1 -s -r -p "Press any key to exit..."
        exit 1
    fi
    
    # Remove current MOTD scripts
    rm -f "${MOTD_DIR}"/* 2>/dev/null || true
    
    # Restore from backup
    cp -a "${LATEST_BACKUP}/"* "${MOTD_DIR}/"
    chmod 755 "${MOTD_DIR}"/*
    chown root:root "${MOTD_DIR}"/*
    
    echo "   Restored from: $LATEST_BACKUP"
    sleep 0.4
    
    RESTORE_METHOD="backup: $LATEST_BACKUP"
fi

# --- Reinstall landscape-common to restore default Ubuntu MOTD behavior ---
echo -e "${YELLOW}→ Reinstalling landscape-common to restore default Ubuntu MOTD behavior...${RESET}"
if ! dpkg -l | grep -q landscape-common; then
    apt-get update -qq
    apt-get install -y landscape-common
    echo "   landscape-common reinstalled."
else
    echo "   landscape-common already installed."
fi
sleep 0.3

# --- Re-enable all Ubuntu MOTD scripts ---
echo -e "${YELLOW}→ Re-enabling Ubuntu default MOTD scripts...${RESET}"

UBUNTU_MOTD=(
  00-header
  10-help-text
  50-landscape-sysinfo
  50-motd-news
  85-fwupd
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
    if [ -f "$MOTD_DIR/$f" ]; then
        chmod +x "$MOTD_DIR/$f"
        echo "   Enabled: $f"
    fi
done
sleep 0.3

echo
echo -e "${GREEN}✓ Restoration complete!${RESET}"
echo -e "Restore method: ${YELLOW}${RESTORE_METHOD}${RESET}\n"

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