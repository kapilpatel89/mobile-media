#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
#   MediaLoad - Social Media Downloader for Termux
#   One-Command Installer
#   https://github.com/kapilpatel89/mobile-media
# ============================================================

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# App Info
APP_NAME="MediaLoad"
APP_VERSION="1.0.0"
INSTALL_DIR="$HOME/.mediaload"
BIN_DIR="$PREFIX/bin"
SHORTCUT_DIR="$HOME/.shortcuts"
WIDGET_DIR="$HOME/.shortcuts/tasks"
REPO_URL="https://github.com/kapilpatel89/mobile-media"

# ─────────────────────────────────────────────
# HELPER FUNCTIONS
# ─────────────────────────────────────────────

clear_screen() {
    clear
}

print_banner() {
    clear_screen
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║                                                      ║"
    echo "  ║   ███╗   ███╗███████╗██████╗ ██╗ █████╗              ║"
    echo "  ║   ████╗ ████║██╔════╝██╔══██╗██║██╔══██╗             ║"
    echo "  ║   ██╔████╔██║█████╗  ██║  ██║██║███████║             ║"
    echo "  ║   ██║╚██╔╝██║██╔══╝  ██║  ██║██║██╔══██║             ║"
    echo "  ║   ██║ ╚═╝ ██║███████╗██████╔╝██║██║  ██║             ║"
    echo "  ║   ╚═╝     ╚═╝╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝             ║"
    echo "  ║                                                      ║"
    echo "  ║    ${WHITE}LOAD${CYAN}  ──  Social Media Downloader  ║"
    echo "  ║      v${APP_VERSION}  for Termux By Kapil Patel      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${DIM}A College Learning Project in Bash Scripting${RESET}"
    echo ""
}

step() {
    echo -e "${CYAN}  ▶  ${WHITE}$1${RESET}"
}

success() {
    echo -e "${GREEN}  ✔  $1${RESET}"
}

warn() {
    echo -e "${YELLOW}  ⚠  $1${RESET}"
}

error() {
    echo -e "${RED}  ✖  ERROR: $1${RESET}"
}

info() {
    echo -e "${BLUE}  ℹ  $1${RESET}"
}

progress_bar() {
    local msg="$1"
    local duration="${2:-2}"
    local width=40
    echo -ne "  ${CYAN}${msg}${RESET} ["
    for ((i=0; i<width; i++)); do
        sleep $(echo "scale=4; $duration/$width" | bc -l 2>/dev/null || echo "0.05")
        echo -ne "${GREEN}█${RESET}"
    done
    echo -e "] ${GREEN}Done!${RESET}"
}

separator() {
    echo -e "${DIM}  ────────────────────────────────────────────────────${RESET}"
}

# ─────────────────────────────────────────────
# CHECK TERMUX ENVIRONMENT
# ─────────────────────────────────────────────

check_termux() {
    step "Checking Termux environment..."
    if [[ -z "$PREFIX" ]] || [[ ! -d "/data/data/com.termux" ]]; then
        error "This script must be run inside Termux on Android!"
        echo ""
        echo -e "  ${YELLOW}Please install Termux from F-Droid:${RESET}"
        echo -e "  ${BLUE}https://f-droid.org/packages/com.termux/${RESET}"
        exit 1
    fi
    success "Termux environment detected"
}

# ─────────────────────────────────────────────
# UPDATE & UPGRADE
# ─────────────────────────────────────────────

update_packages() {
    separator
    step "Updating package repositories..."
    pkg update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" 2>/dev/null | tail -3
    success "Repositories updated"
}

# ─────────────────────────────────────────────
# INSTALL DEPENDENCIES
# ─────────────────────────────────────────────

install_packages() {
    separator
    step "Installing required packages..."
    
    local packages=(
        "python"        # Python runtime for yt-dlp
        "python-pip"    # Python package manager
        "ffmpeg"        # Media processing (merge video+audio, convert formats)
        "curl"          # URL transfers
        "wget"          # File downloads
        "git"           # Version control
        "jq"            # JSON parsing
        "dialog"        # Beautiful TUI dialogs
        "termux-tools"  # Termux utilities (termux-open, etc.)
        "openssh"       # SSH tools
        "aria2"         # Fast multi-connection downloader
        "bc"            # Math calculations
        "ncurses-utils" # Terminal utilities (tput)
        "toilet"        # ASCII art text (optional)
        "figlet"        # ASCII art text (fallback)
    )
    
    for pkg in "${packages[@]}"; do
        echo -ne "  ${DIM}Installing ${CYAN}${pkg}${DIM}...${RESET}"
        pkg install -y "$pkg" > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo -e " ${GREEN}✔${RESET}"
        else
            echo -e " ${YELLOW}⚠ (optional)${RESET}"
        fi
    done
    
    success "Core packages installed"
}

# ─────────────────────────────────────────────
# INSTALL YT-DLP
# ─────────────────────────────────────────────

install_ytdlp() {
    separator
    step "Installing yt-dlp (Social Media Download Engine)..."
    
    # Try pip first (latest version)
    pip install -U yt-dlp flask > /dev/null 2>&1
    
    if ! command -v yt-dlp &>/dev/null; then
        # Fallback: direct binary download
        warn "pip install failed, trying direct binary..."
        curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
            -o "$BIN_DIR/yt-dlp" 2>/dev/null
        chmod +x "$BIN_DIR/yt-dlp"
    fi
    
    if command -v yt-dlp &>/dev/null; then
        local version=$(yt-dlp --version 2>/dev/null)
        success "yt-dlp ${version} installed successfully"
    else
        error "yt-dlp installation failed. Please run: pip install yt-dlp"
    fi
}

# ─────────────────────────────────────────────
# SETUP APP DIRECTORIES
# ─────────────────────────────────────────────

setup_directories() {
    separator
    step "Setting up application directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/downloads"
    mkdir -p "$INSTALL_DIR/downloads/videos"
    mkdir -p "$INSTALL_DIR/downloads/audio"
    mkdir -p "$INSTALL_DIR/downloads/images"
    mkdir -p "$INSTALL_DIR/downloads/playlists"
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/config"
    mkdir -p "$SHORTCUT_DIR"
    mkdir -p "$WIDGET_DIR"
    
    # Create downloads symlink in storage
    if [[ -d "$HOME/storage/downloads" ]]; then
        ln -sf "$INSTALL_DIR/downloads" "$HOME/storage/downloads/MediaLoad" 2>/dev/null
        success "Linked to Android Downloads folder"
    fi
    
    success "Directories created at ${INSTALL_DIR}"
}

# ─────────────────────────────────────────────
# SETUP STORAGE PERMISSION
# ─────────────────────────────────────────────

setup_storage() {
    separator
    step "Setting up storage access..."
    info "You may be prompted to grant storage permission..."
    echo ""
    
    termux-setup-storage 2>/dev/null &
    sleep 2
    
    success "Storage setup initiated (grant permission if prompted)"
}

# ─────────────────────────────────────────────
# CREATE DEFAULT CONFIG
# ─────────────────────────────────────────────

create_config() {
    separator
    if [[ -f "$INSTALL_DIR/config/settings.conf" ]]; then
        step "Preserving existing configuration..."
        # Optional: Add new config keys if they are missing
        success "Configuration preserved"
        return
    fi

    step "Creating default configuration..."
    cat > "$INSTALL_DIR/config/settings.conf" << 'CONF'
# MediaLoad Configuration File
# Edit this file to customize your experience

# Download directory
DOWNLOAD_DIR="$HOME/.mediaload/downloads"

# Default video quality (best/1080p/720p/480p/360p/worst)
DEFAULT_VIDEO_QUALITY="best"

# Default audio quality (best/320k/192k/128k/worst)
DEFAULT_AUDIO_QUALITY="best"

# Default output format (mp4/mkv/webm/mp3/m4a/opus/flac/wav)
DEFAULT_VIDEO_FORMAT="mp4"
DEFAULT_AUDIO_FORMAT="mp3"

# Concurrent downloads (1-8)
MAX_CONCURRENT=3

# Use aria2c for faster downloads (true/false)
USE_ARIA2=true

# Embed subtitles in video (true/false)
EMBED_SUBTITLES=false

# Download thumbnails (true/false)
DOWNLOAD_THUMBNAIL=false

# Max file size in MB (0 = unlimited)
MAX_FILESIZE=0

# Proxy (leave empty if not using)
PROXY=""

# Cookies file (for age-restricted/private content)
COOKIES_FILE=""

# Color theme (cyan/green/magenta/yellow/blue)
THEME_COLOR="cyan"

# Notification when done (true/false)
NOTIFY_ON_DONE=true
CONF
    
    success "Configuration created at ${INSTALL_DIR}/config/settings.conf"
}

# ─────────────────────────────────────────────
# INSTALL MAIN APP SCRIPT
# ─────────────────────────────────────────────

install_app_script() {
    separator
    step "Installing MediaLoad main application..."
    
    # Copy from repo directory if running from cloned repo
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [[ -f "$SCRIPT_DIR/mediaload.sh" ]]; then
        cp "$SCRIPT_DIR/mediaload.sh" "$INSTALL_DIR/mediaload.sh"
        cp "$SCRIPT_DIR/mediaload.sh" "$BIN_DIR/mediaload"
        chmod +x "$INSTALL_DIR/mediaload.sh"
        chmod +x "$BIN_DIR/mediaload"
        success "App script installed from repository"
    else
        error "mediaload.sh not found! Make sure you cloned the full repository."
        exit 1
    fi
}

# ─────────────────────────────────────────────
# CREATE ANDROID SHORTCUT
# ─────────────────────────────────────────────

create_android_shortcut() {
    separator
    step "Creating Android Home Screen shortcut..."
    
    # Check if Termux:Widget is available
    if [[ ! -d "$SHORTCUT_DIR" ]]; then
        mkdir -p "$SHORTCUT_DIR"
    fi
    
    # Create the shortcut launcher script
    cat > "$SHORTCUT_DIR/MediaLoad.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# MediaLoad Android Shortcut Launcher
mediaload
EOF
    chmod +x "$SHORTCUT_DIR/MediaLoad.sh"
    
    # Also create in tasks (for Termux:Widget)
    cat > "$WIDGET_DIR/MediaLoad.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# MediaLoad Android Shortcut Launcher
mediaload
EOF
    chmod +x "$WIDGET_DIR/MediaLoad.sh"
    
    # Create desktop entry file for reference
    cat > "$INSTALL_DIR/MediaLoad.desktop" << 'EOF'
[Desktop Entry]
Name=MediaLoad
Comment=Social Media Downloader
Exec=termux-open-url mediaload://
Icon=mediaload
Type=Application
Categories=Utility;Network;
EOF
    
    success "Shortcut scripts created in ~/.shortcuts/"
    echo ""
    info "To add to Home Screen:"
    echo -e "  ${YELLOW}1.${RESET} Install ${CYAN}Termux:Widget${RESET} from F-Droid"
    echo -e "  ${YELLOW}2.${RESET} Long-press your Android home screen"
    echo -e "  ${YELLOW}3.${RESET} Add Widget → Termux:Widget"
    echo -e "  ${YELLOW}4.${RESET} Select '${CYAN}MediaLoad${RESET}' from the list"
    echo ""
}

# ─────────────────────────────────────────────
# CREATE BASH ALIAS
# ─────────────────────────────────────────────

setup_alias() {
    separator
    step "Setting up launch commands..."
    
    # Add alias to .bashrc if not already there
    if ! grep -q "alias mediaload" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# MediaLoad - Social Media Downloader" >> "$HOME/.bashrc"
        echo "alias mediaload='bash $BIN_DIR/mediaload'" >> "$HOME/.bashrc"
        echo "alias ml='bash $BIN_DIR/mediaload'" >> "$HOME/.bashrc"
    fi
    
    success "You can now launch with: ${CYAN}mediaload${RESET} or ${CYAN}ml${RESET}"
}

# ─────────────────────────────────────────────
# VERIFY INSTALLATION
# ─────────────────────────────────────────────

verify_installation() {
    separator
    step "Verifying installation..."
    
    local all_good=true
    
    # Check yt-dlp
    if command -v yt-dlp &>/dev/null; then
        success "yt-dlp: $(yt-dlp --version)"
    else
        warn "yt-dlp: Not found (some features may not work)"
        all_good=false
    fi
    
    # Check ffmpeg
    if command -v ffmpeg &>/dev/null; then
        success "FFmpeg: $(ffmpeg -version 2>&1 | head -1 | cut -d' ' -f3)"
    else
        warn "FFmpeg: Not found (format conversion will be limited)"
        all_good=false
    fi
    
    # Check python
    if command -v python &>/dev/null; then
        success "Python: $(python --version 2>&1)"
    else
        warn "Python: Not found"
        all_good=false
    fi
    
    # Check main script
    if [[ -f "$BIN_DIR/mediaload" ]]; then
        success "MediaLoad script: Installed"
    else
        error "MediaLoad script: Missing!"
        all_good=false
    fi
    
    if $all_good; then
        return 0
    else
        return 1
    fi
}

# ─────────────────────────────────────────────
# FINAL SUCCESS MESSAGE
# ─────────────────────────────────────────────

print_success() {
    echo ""
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║                                                      ║"
    echo "  ║      🎉  INSTALLATION COMPLETE!  🎉                  ║"
    echo "  ║                                                      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo ""
    echo -e "  ${WHITE}${BOLD}How to launch MediaLoad:${RESET}"
    echo ""
    echo -e "  ${CYAN}•${RESET} Type ${GREEN}mediaload${RESET} or ${GREEN}ml${RESET} in Termux"
    echo -e "  ${CYAN}•${RESET} Use ${GREEN}Termux:Widget${RESET} for home screen shortcut"
    echo -e "  ${CYAN}•${RESET} Quick download: ${GREEN}ml -u \"https://youtube.com/...\"${RESET}"
    echo ""
    echo -e "  ${DIM}Download directory: ${INSTALL_DIR}/downloads${RESET}"
    echo -e "  ${DIM}Config file: ${INSTALL_DIR}/config/settings.conf${RESET}"
    echo ""
    separator
    echo ""
    echo -e "  ${YELLOW}⭐ If you like this project, star it on GitHub!${RESET}"
    echo -e "  ${BLUE}   ${REPO_URL}${RESET}"
    echo ""
    echo -e "  ${MAGENTA}  Made with ❤️  as a College Learning Project${RESET}"
    echo ""
}

# ─────────────────────────────────────────────
# MAIN EXECUTION
# ─────────────────────────────────────────────

main() {
    print_banner
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "  ${YELLOW}${BOLD}Update detected!${RESET} ${WHITE}Upgrading ${CYAN}${APP_NAME}${WHITE} to v${APP_VERSION}...${RESET}"
    else
        echo -e "  ${WHITE}${BOLD}Installing ${CYAN}${APP_NAME}${WHITE} v${APP_VERSION}...${RESET}"
    fi
    echo ""
    
    check_termux
    update_packages
    install_packages
    install_ytdlp
    setup_directories
    setup_storage
    create_config
    install_app_script
    create_android_shortcut
    setup_alias
    verify_installation
    print_success
    
    echo -e "  ${GREEN}Launching MediaLoad in 3 seconds...${RESET}"
    sleep 3
    exec bash "$BIN_DIR/mediaload"
}

main "$@"
