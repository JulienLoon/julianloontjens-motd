#!/bin/bash
#
# install.sh – Installer for julianloontjens-motd
# GitHub: https://github.com/JulienLoon/julianloontjens-motd
# Author: Julian Loontjens
# Version: 1.5

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
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

# --- Paths ---
MOTD_SRC="$(pwd)/motd"
MOTD_DEST="/etc/update-motd.d"
BACKUP_DIR="/etc/update-motd.d.backup-$(date +%Y%m%d-%H%M%S)"

# --- Verify source ---
if [ ! -d "$MOTD_SRC" ]; then
    echo -e "${RED}✗ Error: motd/ directory not found.${RESET}"
    echo "Run this script from the root of the repository."
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi

echo -e "${CYAN}▶ Starting installation...${RESET}"
sleep 0.4

# --- Backup existing MOTD ---
echo -e "${YELLOW}→ Backing up existing MOTD to:${RESET} $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -a "$MOTD_DEST"/* "$BACKUP_DIR"/ 2>/dev/null || true
sleep 0.4

# --- Install new MOTD files ---
echo -e "${YELLOW}→ Installing custom MOTD scripts...${RESET}"
cp -a "$MOTD_SRC"/* "$MOTD_DEST"/
sleep 0.4

# --- Permissions ---
echo -e "${YELLOW}→ Setting permissions...${RESET}"
chmod 755 "$MOTD_DEST"/*
chown root:root "$MOTD_DEST"/*
sleep 0.3

# --- Disable Ubuntu default MOTD scripts ---
echo -e "${YELLOW}→ Disabling Ubuntu default MOTD components...${RESET}"

UBUNTU_MOTD=(
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
    if [ -f "$MOTD_DEST/$f" ]; then
        chmod -x "$MOTD_DEST/$f"
        echo "   Disabled: $f"
    fi
done

# --- Disable static Ubuntu MOTD (PAM fallback) ---
echo -e "${YELLOW}→ Disabling static Ubuntu MOTD (pam_motd fallback)...${RESET}"

if [ -f /etc/motd ]; then
    truncate -s 0 /etc/motd
    chattr +i /etc/motd
    echo "   Locked /etc/motd"
fi

if [ -f /etc/motd.tail ]; then
    truncate -s 0 /etc/motd.tail
    echo "   Cleared /etc/motd.tail"
fi

# --- HARD BLOCK landscape (survives updates) ---
if [ -f "$MOTD_DEST/50-landscape-sysinfo" ]; then
    echo -e "${YELLOW}→ Permanently blocking landscape sysinfo...${RESET}"
    dpkg-divert --quiet --local --rename \
        --divert /etc/update-motd.d/50-landscape-sysinfo.disabled \
        /etc/update-motd.d/50-landscape-sysinfo || true
fi

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
