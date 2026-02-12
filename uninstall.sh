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

# --- Remove dpkg-divert entries first ---
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

echo -e "${YELLOW}→ Removing dpkg-divert entries...${RESET}"
for f in "${UBUNTU_MOTD[@]}"; do
    SCRIPT_PATH="$MOTD_DIR/$f"
    DIVERTED=$(dpkg-divert --list 2>/dev/null | grep "$SCRIPT_PATH" || true)
    if [[ -n "$DIVERTED" ]]; then
        echo "   Removing divert for $f"
        dpkg-divert --quiet --remove --rename "$SCRIPT_PATH" 2>/dev/null || true
    fi
done
sleep 0.3

# --- Clean MOTD directory completely ---
echo -e "${YELLOW}→ Cleaning current MOTD directory...${RESET}"
rm -rf "${MOTD_DIR}"
mkdir -p "${MOTD_DIR}"
chmod 755 "${MOTD_DIR}"
sleep 0.4

# --- Restore backup ---
echo -e "${YELLOW}→ Restoring backup from:${RESET} ${LATEST_BACKUP}"
cp -a "${LATEST_BACKUP}/"* "${MOTD_DIR}/" 2>/dev/null || true
chmod 755 "${MOTD_DIR}"/* 2>/dev/null || true
chown root:root "${MOTD_DIR}"/* 2>/dev/null || true
sleep 0.4

# --- Reinstall packages to restore default Ubuntu MOTD scripts ---
echo -e "${YELLOW}→ Reinstalling Ubuntu packages to restore default MOTD scripts...${RESET}"

# Update package list
apt-get update -qq

# Reinstall base-files (contains 10-help-text and other core scripts)
echo "   Reinstalling base-files..."
apt-get install --reinstall -y base-files 2>/dev/null || true

# Reinstall update-notifier-common (contains update notifications)
echo "   Reinstalling update-notifier-common..."
apt-get install --reinstall -y update-notifier-common 2>/dev/null || true

# Reinstall landscape-common (contains landscape-sysinfo)
if dpkg -l | grep -q landscape-common 2>/dev/null; then
    echo "   Reinstalling landscape-common..."
    apt-get install --reinstall -y landscape-common 2>/dev/null || true
else
    echo "   Installing landscape-common..."
    apt-get install -y landscape-common 2>/dev/null || true
fi

# Reinstall ubuntu-advantage-tools (contains UA/ESM scripts)
if dpkg -l | grep -q ubuntu-pro-client 2>/dev/null; then
    echo "   Reinstalling ubuntu-pro-client..."
    apt-get install --reinstall -y ubuntu-pro-client 2>/dev/null || true
elif dpkg -l | grep -q ubuntu-advantage-tools 2>/dev/null; then
    echo "   Reinstalling ubuntu-advantage-tools..."
    apt-get install --reinstall -y ubuntu-advantage-tools 2>/dev/null || true
fi

# Reinstall unattended-upgrades if present
if dpkg -l | grep -q unattended-upgrades 2>/dev/null; then
    echo "   Reinstalling unattended-upgrades..."
    apt-get install --reinstall -y unattended-upgrades 2>/dev/null || true
fi

sleep 0.3

# --- Verify critical scripts exist, if not create minimal versions ---
echo -e "${YELLOW}→ Verifying critical MOTD scripts...${RESET}"

# 10-help-text
if [[ ! -f "$MOTD_DIR/10-help-text" ]]; then
    echo "   Creating 10-help-text..."
    cat > "$MOTD_DIR/10-help-text" << 'HELPEOF'
#!/bin/sh
printf "\n"
printf " * Documentation:  https://help.ubuntu.com\n"
printf " * Management:     https://landscape.canonical.com\n"
printf " * Support:        https://ubuntu.com/pro\n"
printf "\n"
HELPEOF
    chmod 755 "$MOTD_DIR/10-help-text"
fi

# 50-landscape-sysinfo
if [[ ! -f "$MOTD_DIR/50-landscape-sysinfo" ]] && command -v landscape-sysinfo &> /dev/null; then
    echo "   Creating 50-landscape-sysinfo..."
    cat > "$MOTD_DIR/50-landscape-sysinfo" << 'LANDEOF'
#!/bin/sh
[ -x /usr/bin/landscape-sysinfo ] && /usr/bin/landscape-sysinfo
LANDEOF
    chmod 755 "$MOTD_DIR/50-landscape-sysinfo"
fi

# 50-motd-news
if [[ ! -f "$MOTD_DIR/50-motd-news" ]]; then
    echo "   Creating 50-motd-news..."
    cat > "$MOTD_DIR/50-motd-news" << 'NEWSEOF'
#!/bin/sh
MOTD_DISABLE=1
[ -r /etc/default/motd-news ] && . /etc/default/motd-news
[ "$ENABLED" = "1" ] && [ -x /usr/lib/ubuntu-advantage/motd-news ] && exec /usr/lib/ubuntu-advantage/motd-news
exit 0
NEWSEOF
    chmod 755 "$MOTD_DIR/50-motd-news"
fi

echo
echo -e "${GREEN}✓ Restoration complete!${RESET}"
echo -e "Backup used: ${YELLOW}${LATEST_BACKUP}${RESET}"
echo -e "Packages reinstalled for full MOTD functionality\n"

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