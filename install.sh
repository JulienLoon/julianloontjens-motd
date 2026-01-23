#!/bin/bash
#
# install.sh – Installer for julianloontjens-motd (v1.6 - Persistent Update Fix)
# GitHub: https://github.com
# Author: Julian Loontjens
# Version: 1.6 (2026 Edition)

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
echo -e "${RESET}${BOLD}\n      Julian Loontjens MOTD Installer (Anti-Update Persistent)${RESET}\n"

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

# --- Install new MOTD files ---
echo -e "${YELLOW}→ Installing custom MOTD scripts...${RESET}"
cp -a "$MOTD_SRC"/* "$MOTD_DEST"/

# --- Permissions for your scripts ---
echo -e "${YELLOW}→ Setting permissions...${RESET}"
chmod 755 "$MOTD_DEST"/*
chown root:root "$MOTD_DEST"/*

# --- PERMANENTLY BLOCK Ubuntu default scripts ---
# We use dpkg-divert so that updates don't overwrite or restore these files.
echo -e "${YELLOW}→ Permanently disabling Ubuntu default components...${RESET}"

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
    FILE_PATH="$MOTD_DEST/$f"
    if [ -f "$FILE_PATH" ]; then
        # If no divert exists for this file, create one
        if ! dpkg-divert --list | grep -q "$FILE_PATH"; then
            dpkg-divert --quiet --local --rename --divert "$FILE_PATH.ubuntu" "$FILE_PATH"
            
            # Create an empty dummy script that does nothing
            cat << 'EOF' > "$FILE_PATH"
#!/bin/sh
exit 0
EOF
            chmod 755 "$FILE_PATH"
            chown root:root "$FILE_PATH"
            echo "   Diverted and neutralized: $f"
        else
            echo "   Already neutralized: $f"
        fi
    fi
done

# Extra: Clear the "Legal" text that sometimes appears above the MOTD
if [ -f /etc/legal ]; then
    cat /dev/null > /etc/legal
    echo "   Cleared /etc/legal"
fi

# --- Done ---
echo
echo -e "${GREEN}✓ Installation complete!${RESET}"
echo -e "Backup directory: ${YELLOW}${BACKUP_DIR}${RESET}\n"

# --- Preview ---
read -p "Would you like to preview the MOTD now? (y/n) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${CYAN}────────── MOTD PREVIEW ──────────${RESET}\n"
    # Force regeneration for preview
    run-parts /etc/update-motd.d/
    echo -e "\n${CYAN}──────────────────────────────────${RESET}\n"
fi

echo -e "${BOLD}Installation finished.${RESET}"
echo -e "Press any key to exit..."
read -n 1 -s
clear
