#!/bin/bash
#
# install.sh – Installer for julianloontjens-motd
# GitHub: https://github.com/JulienLoon/julianloontjens-motd
# Author: Julian Loontjens
# Version: 1.6

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

# --- Remove landscape-common to prevent Ubuntu MOTD override ---
echo -e "${YELLOW}→ Removing landscape-common to prevent MOTD reset...${RESET}"
if dpkg -l | grep -q landscape-common; then
    apt-get purge -y landscape-common
    echo "   landscape-common removed."
else
    echo "   landscape-common not installed."
fi
sleep 0.3

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOTD_SRC="$SCRIPT_DIR/motd"
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

# --- HARD BLOCK Ubuntu help-text (Documentation / Support links) ---
echo -e "${YELLOW}→ Permanently disabling Ubuntu help text...${RESET}"

HELP_TEXT="/etc/update-motd.d/10-help-text"

if [ -f "$HELP_TEXT" ]; then
    dpkg-divert --quiet --local --rename \
        --divert /etc/update-motd.d/10-help-text.ubuntu \
        "$HELP_TEXT"

    # Replace with empty executable script
    cat << 'EOF' > "$HELP_TEXT"
#!/bin/sh
exit 0
EOF

    chmod 755 "$HELP_TEXT"
    chown root:root "$HELP_TEXT"

    echo "   Diverted and neutralized: 10-help-text"
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