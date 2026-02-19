#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
#   MediaLoad - Uninstaller
#   Cleanly removes MediaLoad from Termux
# ============================================================

CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
DIM='\033[2m'
RESET='\033[0m'

echo ""
echo -e "${RED}  ┌─────────────────────────────────────┐${RESET}"
echo -e "${RED}  │   MediaLoad - Uninstaller           │${RESET}"
echo -e "${RED}  └─────────────────────────────────────┘${RESET}"
echo ""
echo -e "  ${YELLOW}⚠  This will remove MediaLoad from your device.${RESET}"
echo -ne "  ${WHITE}Continue? [y/N]: ${RESET}"
read -r confirm

if [[ "${confirm,,}" != "y" ]]; then
    echo -e "  ${GREEN}Uninstall cancelled.${RESET}"
    exit 0
fi

echo ""

# Remove main binary
rm -f "$PREFIX/bin/mediaload"
echo -e "  ${GREEN}✔${RESET}  Removed: mediaload binary"

# Remove shortcut scripts
rm -f "$HOME/.shortcuts/MediaLoad.sh"
rm -f "$HOME/.shortcuts/MediaLoad-QuickDL.sh"
rm -f "$HOME/.shortcuts/tasks/MediaLoad.sh"
rm -f "$HOME/.shortcuts/tasks/MediaLoad-QuickDL.sh"
echo -e "  ${GREEN}✔${RESET}  Removed: Android shortcut scripts"

# Remove aliases from .bashrc
sed -i '/# MediaLoad - Social Media Downloader/d' "$HOME/.bashrc" 2>/dev/null
sed -i '/alias mediaload=/d' "$HOME/.bashrc" 2>/dev/null
sed -i '/alias ml=/d' "$HOME/.bashrc" 2>/dev/null
echo -e "  ${GREEN}✔${RESET}  Removed: bash aliases"

# Ask about downloads
echo ""
echo -ne "  ${YELLOW}Delete all downloaded files? [y/N]: ${RESET}"
read -r del_files

if [[ "${del_files,,}" == "y" ]]; then
    rm -rf "$HOME/.mediaload/downloads"
    echo -e "  ${GREEN}✔${RESET}  Deleted: downloads folder"
fi

# Remove app config/logs (keep downloads if user chose to)
echo -ne "  ${YELLOW}Delete configuration and logs? [y/N]: ${RESET}"
read -r del_config

if [[ "${del_config,,}" == "y" ]]; then
    rm -rf "$HOME/.mediaload"
    echo -e "  ${GREEN}✔${RESET}  Deleted: configuration and logs"
fi

echo ""
echo -e "  ${GREEN}✅ MediaLoad has been uninstalled.${RESET}"
echo -e "  ${DIM}Your yt-dlp installation is kept. To remove it: pip uninstall yt-dlp${RESET}"
echo ""
