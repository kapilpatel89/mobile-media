#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
#   MediaLoad - Android Home Screen Shortcut Creator
#   Creates a Termux:Widget compatible shortcut
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BLUE='\033[0;34m'
DIM='\033[2m'
RESET='\033[0m'

SHORTCUT_DIR="$HOME/.shortcuts"
WIDGET_DIR="$HOME/.shortcuts/tasks"

echo ""
echo -e "${CYAN}  ┌─────────────────────────────────────────┐${RESET}"
echo -e "${CYAN}  │   MediaLoad - Shortcut Setup            │${RESET}"
echo -e "${CYAN}  └─────────────────────────────────────────┘${RESET}"
echo ""

# Create shortcut directories
mkdir -p "$SHORTCUT_DIR" "$WIDGET_DIR"

# ─────────────────────────────────────────────
# CREATE MAIN SHORTCUT SCRIPT
# ─────────────────────────────────────────────

cat > "$SHORTCUT_DIR/MediaLoad.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# MediaLoad - Social Media Downloader
# Tap this shortcut from Termux:Widget to launch

# Start MediaLoad
exec mediaload
EOF

chmod +x "$SHORTCUT_DIR/MediaLoad.sh"

# Create a "Quick Download" shortcut (pastes clipboard URL)
cat > "$SHORTCUT_DIR/MediaLoad-QuickDL.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# MediaLoad - Quick Download from Clipboard

URL=$(termux-clipboard-get 2>/dev/null)

if [[ -n "$URL" ]] && [[ "$URL" =~ ^https?:// ]]; then
    echo -e "\033[0;36m┌──────────────────────────────────┐\033[0m"
    echo -e "\033[0;36m│  MediaLoad - Quick Download      │\033[0m"
    echo -e "\033[0;36m└──────────────────────────────────┘\033[0m"
    echo ""
    echo -e "\033[1;37mURL detected:\033[0m"
    echo -e "\033[2m${URL:0:60}...\033[0m"
    echo ""
    echo -e "\033[1;37mSelect type:\033[0m"
    echo -e "  \033[0;36m1\033[0m  Video (MP4)"
    echo -e "  \033[0;36m2\033[0m  Audio (MP3)"
    echo ""
    echo -ne "  Choice [1]: "
    read -r choice
    
    case "${choice:-1}" in
        2) mediaload -u "$URL" -a -f mp3 ;;
        *) mediaload -u "$URL" -v -f mp4 ;;
    esac
else
    echo -e "\033[1;33m⚠  No valid URL in clipboard!\033[0m"
    echo -e "\033[2mCopy a URL first, then tap this shortcut.\033[0m"
    echo ""
    echo -e "\033[0;36m  Launching MediaLoad menu instead...\033[0m"
    sleep 2
    exec mediaload
fi
EOF
chmod +x "$SHORTCUT_DIR/MediaLoad-QuickDL.sh"

# Also in tasks directory (needed for some Termux:Widget versions)
cp "$SHORTCUT_DIR/MediaLoad.sh" "$WIDGET_DIR/MediaLoad.sh"
cp "$SHORTCUT_DIR/MediaLoad-QuickDL.sh" "$WIDGET_DIR/MediaLoad-QuickDL.sh"

# ─────────────────────────────────────────────
# CREATE NOTIFICATION SHORTCUT
# ─────────────────────────────────────────────

# Create a persistent notification button (optional)
cat > "$HOME/.mediaload/create_notification_launcher.sh" << 'NOTIF'
#!/data/data/com.termux/files/usr/bin/bash
# Create a persistent Android notification with a "Download" action
termux-notification \
    --id 9999 \
    --title "MediaLoad" \
    --content "Tap to open social media downloader" \
    --button1 "Open App" \
    --button1-action "am start --user 0 -n com.termux/com.termux.app.TermuxActivity" \
    --ongoing \
    --priority default \
    --icon "ic_get_app" 2>/dev/null &

echo "Persistent notification created!"
NOTIF
chmod +x "$HOME/.mediaload/create_notification_launcher.sh"

# ─────────────────────────────────────────────
# DISPLAY SETUP INSTRUCTIONS
# ─────────────────────────────────────────────

echo -e "  ${GREEN}✔${RESET}  Shortcut scripts created successfully!"
echo ""
echo -e "  ${WHITE}Files created:${RESET}"
echo -e "  ${DIM}~/.shortcuts/MediaLoad.sh${RESET}"
echo -e "  ${DIM}~/.shortcuts/MediaLoad-QuickDL.sh${RESET}"
echo ""
echo -e "  ${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  HOW TO ADD TO HOME SCREEN:"
echo -e "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${YELLOW}Step 1:${RESET} Install ${CYAN}Termux:Widget${RESET} from F-Droid:"
echo -e "  ${BLUE}  https://f-droid.org/packages/com.termux.widget/${RESET}"
echo ""
echo -e "  ${YELLOW}Step 2:${RESET} Long-press your Android home screen"
echo ""
echo -e "  ${YELLOW}Step 3:${RESET} Tap '${WHITE}Widgets${RESET}' → Scroll to '${CYAN}Termux:Widget${RESET}'"
echo -e "          → Choose either:"
echo -e "          ${DIM}• Small Widget (icon only)${RESET}"
echo -e "          ${DIM}• Large Widget (list of shortcuts)${RESET}"
echo ""
echo -e "  ${YELLOW}Step 4:${RESET} In the widget, tap '${CYAN}MediaLoad${RESET}' or '${CYAN}MediaLoad-QuickDL${RESET}'"
echo ""
echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${GREEN}✅ Done! Your Android shortcut is ready!${RESET}"
echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${DIM}Alternative: Use Termux:Tasker for more advanced shortcuts${RESET}"
echo -e "  ${BLUE}  https://f-droid.org/packages/com.termux.tasker/${RESET}"
echo ""
