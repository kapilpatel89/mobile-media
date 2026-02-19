#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
#   MediaLoad v1.0.0 - Social Media Downloader for Termux
#   Powered by yt-dlp | https://github.com/yt-dlp/yt-dlp
#   Built for Android (Termux) | College Learning Project
# ============================================================

# ─────────────────────────────────────────────
# CONFIGURATION & CONSTANTS
# ─────────────────────────────────────────────

APP_NAME="MediaLoad"
APP_VERSION="1.0.0"
INSTALL_DIR="$HOME/.mediaload"
CONFIG_FILE="$INSTALL_DIR/config/settings.conf"
LOG_FILE="$INSTALL_DIR/logs/download.log"
DOWNLOAD_BASE="$INSTALL_DIR/downloads"

# Load user config if exists
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# Fallback defaults
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$DOWNLOAD_BASE}"
THEME_COLOR="${THEME_COLOR:-cyan}"
MAX_CONCURRENT="${MAX_CONCURRENT:-3}"
USE_ARIA2="${USE_ARIA2:-true}"
NOTIFY_ON_DONE="${NOTIFY_ON_DONE:-true}"
DEFAULT_VIDEO_QUALITY="${DEFAULT_VIDEO_QUALITY:-best}"
DEFAULT_VIDEO_FORMAT="${DEFAULT_VIDEO_FORMAT:-mp4}"
DEFAULT_AUDIO_FORMAT="${DEFAULT_AUDIO_FORMAT:-mp3}"

# ─────────────────────────────────────────────
# ANSI COLORS & THEME
# ─────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
BLINK='\033[5m'
RESET='\033[0m'
BG_DARK='\033[48;5;235m'

# Set theme accent color
case "$THEME_COLOR" in
    green)   ACCENT='\033[0;32m' ;;
    magenta) ACCENT='\033[0;35m' ;;
    yellow)  ACCENT='\033[1;33m' ;;
    blue)    ACCENT='\033[0;34m' ;;
    *)       ACCENT='\033[0;36m' ;;  # default cyan
esac

# Get terminal width
TERM_WIDTH=$(tput cols 2>/dev/null || echo 70)

# ─────────────────────────────────────────────
# UI HELPER FUNCTIONS
# ─────────────────────────────────────────────

cls() { clear; }

center_text() {
    local text="$1"
    local color="${2:-$RESET}"
    local text_clean="${text//\033\[[0-9;]*m/}"
    local text_len=${#text_clean}
    local pad=$(( (TERM_WIDTH - text_len) / 2 ))
    printf "%${pad}s" ""
    echo -e "${color}${text}${RESET}"
}

draw_line() {
    local char="${1:-─}"
    local color="${2:-$DIM}"
    printf "${color}"
    printf "%${TERM_WIDTH}s" | tr ' ' "$char"
    printf "${RESET}\n"
}

draw_box_top() {
    echo -e "${ACCENT}  ╔$(printf '═%.0s' $(seq 1 $((TERM_WIDTH-4))))╗${RESET}"
}

draw_box_bottom() {
    echo -e "${ACCENT}  ╚$(printf '═%.0s' $(seq 1 $((TERM_WIDTH-4))))╝${RESET}"
}

draw_box_row() {
    local text="$1"
    local text_clean="${text//\033\[[0-9;]*m/}"
    local inner_width=$((TERM_WIDTH - 6))
    local pad=$((inner_width - ${#text_clean}))
    echo -e "${ACCENT}  ║ ${RESET}${text}$(printf '%*s' $pad '')${ACCENT} ║${RESET}"
}

spinner() {
    local pid=$1
    local msg="${2:-Processing...}"
    local delay=0.1
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while kill -0 $pid 2>/dev/null; do
        echo -ne "\r  ${ACCENT}${frames[$((i % ${#frames[@]}))]}${RESET}  ${WHITE}${msg}${RESET}   "
        sleep $delay
        ((i++))
    done
    echo -ne "\r  ${GREEN}✔${RESET}  ${WHITE}${msg}${RESET}   \n"
}

print_status() {
    local type="$1"
    local msg="$2"
    case $type in
        ok)      echo -e "  ${GREEN}✔${RESET}  $msg" ;;
        err)     echo -e "  ${RED}✖${RESET}  ${RED}$msg${RESET}" ;;
        warn)    echo -e "  ${YELLOW}⚠${RESET}  $msg" ;;
        info)    echo -e "  ${BLUE}ℹ${RESET}  $msg" ;;
        arrow)   echo -e "  ${ACCENT}▶${RESET}  $msg" ;;
    esac
}

press_any_key() {
    echo ""
    echo -e "  ${DIM}Press any key to continue...${RESET}"
    read -n 1 -s
}

confirm() {
    local msg="${1:-Are you sure?}"
    echo -ne "  ${YELLOW}${msg} [y/N]: ${RESET}"
    read -r ans
    [[ "${ans,,}" == "y" ]]
}

input_prompt() {
    local msg="$1"
    local var_name="$2"
    local default="$3"
    echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}${msg}${RESET}"
    [[ -n "$default" ]] && echo -ne " ${DIM}[${default}]${RESET}"
    echo -ne ": "
    read -r "$var_name"
    # Use default if empty
    if [[ -z "${!var_name}" ]] && [[ -n "$default" ]]; then
        eval "$var_name=\"$default\""
    fi
}

# ─────────────────────────────────────────────
# BANNER / SPLASH SCREEN
# ─────────────────────────────────────────────

print_banner() {
    cls
    echo ""
    echo -e "${ACCENT}"
    echo "  ███╗   ███╗███████╗██████╗ ██╗ █████╗    ██╗      ██████╗  █████╗ ██████╗ "
    echo "  ████╗ ████║██╔════╝██╔══██╗██║██╔══██╗   ██║     ██╔═══██╗██╔══██╗██╔══██╗"
    echo "  ██╔████╔██║█████╗  ██║  ██║██║███████║   ██║     ██║   ██║███████║██║  ██║"
    echo "  ██║╚██╔╝██║██╔══╝  ██║  ██║██║██╔══██║   ██║     ██║   ██║██╔══██║██║  ██║"
    echo "  ██║ ╚═╝ ██║███████╗██████╔╝██║██║  ██║   ███████╗╚██████╔╝██║  ██║██████╔╝"
    echo "  ╚═╝     ╚═╝╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ "
    echo -e "${RESET}"
    echo -e "       ${WHITE}Social Media Downloader${RESET}  ${DIM}│${RESET}  ${DIM}v${APP_VERSION}${RESET}  ${DIM}│${RESET}  ${GREEN}Powered by yt-dlp${RESET}"
    draw_line "─" "$DIM"
    echo ""
}

print_status_bar() {
    local ytdlp_ver=$(yt-dlp --version 2>/dev/null || echo "N/A")
    local disk_free=$(df -h "$DOWNLOAD_DIR" 2>/dev/null | awk 'NR==2{print $4}' || echo "N/A")
    local dl_count=$(find "$DOWNLOAD_DIR" -type f 2>/dev/null | wc -l)
    echo -e "  ${DIM}yt-dlp: ${CYAN}${ytdlp_ver}${RESET}  ${DIM}│  Free: ${CYAN}${disk_free}${RESET}  ${DIM}│  Downloads: ${CYAN}${dl_count}${RESET}"
    echo ""
}

# ─────────────────────────────────────────────
# MAIN MENU
# ─────────────────────────────────────────────

main_menu() {
    while true; do
        print_banner
        print_status_bar
        
        echo -e "  ${WHITE}${BOLD}MAIN MENU${RESET}"
        draw_line "─" "$DIM"
        echo ""
        echo -e "  ${ACCENT}  1  ${RESET}  ${WHITE}📥  Download Video${RESET}           ${DIM}(MP4, MKV, WEBM...)${RESET}"
        echo -e "  ${ACCENT}  2  ${RESET}  ${WHITE}🎵  Download Audio${RESET}           ${DIM}(MP3, M4A, FLAC...)${RESET}"
        echo -e "  ${ACCENT}  3  ${RESET}  ${WHITE}📸  Download Images${RESET}          ${DIM}(Instagram, Twitter...)${RESET}"
        echo -e "  ${ACCENT}  4  ${RESET}  ${WHITE}📋  Download Playlist${RESET}        ${DIM}(YouTube, SoundCloud...)${RESET}"
        echo -e "  ${ACCENT}  5  ${RESET}  ${WHITE}⚡  Batch Download${RESET}           ${DIM}(Multiple URLs at once)${RESET}"
        echo -e "  ${ACCENT}  6  ${RESET}  ${WHITE}🔍  Get Video Info${RESET}           ${DIM}(Without downloading)${RESET}"
        echo -e "  ${ACCENT}  7  ${RESET}  ${WHITE}📁  My Downloads${RESET}            ${DIM}(Browse & manage files)${RESET}"
        echo -e "  ${ACCENT}  8  ${RESET}  ${WHITE}📱  Supported Sites${RESET}          ${DIM}(1000+ platforms)${RESET}"
        echo -e "  ${ACCENT}  9  ${RESET}  ${WHITE}⚙️   Settings${RESET}               ${DIM}(Configure app)${RESET}"
        echo -e "  ${ACCENT}  0  ${RESET}  ${WHITE}❌  Exit${RESET}"
        echo ""
        draw_line "─" "$DIM"
        echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}Select option: ${RESET}"
        read -r choice
        
        case "$choice" in
            1) download_video_menu ;;
            2) download_audio_menu ;;
            3) download_images_menu ;;
            4) download_playlist_menu ;;
            5) batch_download_menu ;;
            6) video_info_menu ;;
            7) my_downloads_menu ;;
            8) supported_sites_menu ;;
            9) settings_menu ;;
            0|q|Q|exit|quit) 
                echo ""
                echo -e "  ${GREEN}Thanks for using MediaLoad! Goodbye! 👋${RESET}"
                echo ""
                exit 0 ;;
            *)
                print_status err "Invalid option. Please try again."
                sleep 1 ;;
        esac
    done
}

# ─────────────────────────────────────────────
# QUALITY SELECTOR
# ─────────────────────────────────────────────

select_quality() {
    echo ""
    echo -e "  ${WHITE}${BOLD}SELECT VIDEO QUALITY:${RESET}"
    echo ""
    echo -e "  ${ACCENT}  1  ${RESET}  ${WHITE}🏆 Best Available${RESET}     ${DIM}(Highest quality, largest file)${RESET}"
    echo -e "  ${ACCENT}  2  ${RESET}  ${WHITE}🖥️  4K / 2160p${RESET}       ${DIM}(Ultra HD)${RESET}"
    echo -e "  ${ACCENT}  3  ${RESET}  ${WHITE}📺  1080p Full HD${RESET}     ${DIM}(Recommended)${RESET}"
    echo -e "  ${ACCENT}  4  ${RESET}  ${WHITE}📺  720p HD${RESET}           ${DIM}(Good balance)${RESET}"
    echo -e "  ${ACCENT}  5  ${RESET}  ${WHITE}📱  480p SD${RESET}           ${DIM}(Smaller files)${RESET}"
    echo -e "  ${ACCENT}  6  ${RESET}  ${WHITE}📱  360p${RESET}              ${DIM}(Minimum quality)${RESET}"
    echo -e "  ${ACCENT}  7  ${RESET}  ${WHITE}💾  Worst${RESET}             ${DIM}(Smallest file size)${RESET}"
    echo ""
    echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}Select quality [1]: ${RESET}"
    read -r q_choice
    
    case "${q_choice:-1}" in
        1) echo "bestvideo+bestaudio/best" ;;
        2) echo "bestvideo[height<=2160]+bestaudio/best[height<=2160]" ;;
        3) echo "bestvideo[height<=1080]+bestaudio/best[height<=1080]" ;;
        4) echo "bestvideo[height<=720]+bestaudio/best[height<=720]" ;;
        5) echo "bestvideo[height<=480]+bestaudio/best[height<=480]" ;;
        6) echo "bestvideo[height<=360]+bestaudio/best[height<=360]" ;;
        7) echo "worstvideo+worstaudio/worst" ;;
        *) echo "bestvideo+bestaudio/best" ;;
    esac
}

select_video_format() {
    echo ""
    echo -e "  ${WHITE}${BOLD}SELECT OUTPUT FORMAT:${RESET}"
    echo ""
    echo -e "  ${ACCENT}  1  ${RESET}  ${WHITE}MP4${RESET}   ${DIM}(Most compatible, recommended)${RESET}"
    echo -e "  ${ACCENT}  2  ${RESET}  ${WHITE}MKV${RESET}   ${DIM}(High quality container)${RESET}"
    echo -e "  ${ACCENT}  3  ${RESET}  ${WHITE}WEBM${RESET}  ${DIM}(Web-friendly format)${RESET}"
    echo -e "  ${ACCENT}  4  ${RESET}  ${WHITE}AVI${RESET}   ${DIM}(Classic format)${RESET}"
    echo -e "  ${ACCENT}  5  ${RESET}  ${WHITE}MOV${RESET}   ${DIM}(Apple QuickTime)${RESET}"
    echo -e "  ${ACCENT}  6  ${RESET}  ${WHITE}FLV${RESET}   ${DIM}(Flash Video)${RESET}"
    echo ""
    echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}Select format [1]: ${RESET}"
    read -r f_choice
    
    case "${f_choice:-1}" in
        1) echo "mp4" ;;
        2) echo "mkv" ;;
        3) echo "webm" ;;
        4) echo "avi" ;;
        5) echo "mov" ;;
        6) echo "flv" ;;
        *) echo "mp4" ;;
    esac
}

select_audio_format() {
    echo ""
    echo -e "  ${WHITE}${BOLD}SELECT AUDIO FORMAT:${RESET}"
    echo ""
    echo -e "  ${ACCENT}  1  ${RESET}  ${WHITE}MP3${RESET}   ${DIM}(Most compatible, universal)${RESET}"
    echo -e "  ${ACCENT}  2  ${RESET}  ${WHITE}M4A${RESET}   ${DIM}(Apple AAC, great quality)${RESET}"
    echo -e "  ${ACCENT}  3  ${RESET}  ${WHITE}OPUS${RESET}  ${DIM}(Best compression, modern)${RESET}"
    echo -e "  ${ACCENT}  4  ${RESET}  ${WHITE}FLAC${RESET}  ${DIM}(Lossless, high quality)${RESET}"
    echo -e "  ${ACCENT}  5  ${RESET}  ${WHITE}WAV${RESET}   ${DIM}(Uncompressed audio)${RESET}"
    echo -e "  ${ACCENT}  6  ${RESET}  ${WHITE}OGG${RESET}   ${DIM}(Open format)${RESET}"
    echo -e "  ${ACCENT}  7  ${RESET}  ${WHITE}AAC${RESET}   ${DIM}(Advanced Audio Codec)${RESET}"
    echo ""
    echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}Select format [1]: ${RESET}"
    read -r f_choice
    
    case "${f_choice:-1}" in
        1) echo "mp3" ;;
        2) echo "m4a" ;;
        3) echo "opus" ;;
        4) echo "flac" ;;
        5) echo "wav" ;;
        6) echo "vorbis" ;;
        7) echo "aac" ;;
        *) echo "mp3" ;;
    esac
}

# ─────────────────────────────────────────────
# DETECT PLATFORM FROM URL
# ─────────────────────────────────────────────

detect_platform() {
    local url="$1"
    case "$url" in
        *youtube.com*|*youtu.be*)    echo "YouTube 🎬" ;;
        *instagram.com*)              echo "Instagram 📸" ;;
        *twitter.com*|*x.com*)       echo "Twitter/X 🐦" ;;
        *tiktok.com*)                 echo "TikTok 🎵" ;;
        *facebook.com*|*fb.com*)      echo "Facebook 📘" ;;
        *reddit.com*)                 echo "Reddit 🤖" ;;
        *twitch.tv*)                  echo "Twitch 🎮" ;;
        *spotify.com*)                echo "Spotify 🎵" ;;
        *soundcloud.com*)             echo "SoundCloud 🎧" ;;
        *vimeo.com*)                  echo "Vimeo 🎥" ;;
        *dailymotion.com*)            echo "Dailymotion 📹" ;;
        *pinterest.com*)              echo "Pinterest 📌" ;;
        *linkedin.com*)               echo "LinkedIn 💼" ;;
        *tumblr.com*)                 echo "Tumblr 📝" ;;
        *bilibili.com*)               echo "Bilibili 📺" ;;
        *niconico.jp*|*nicovideo.jp*) echo "NicoNico 🎌" ;;
        *ok.ru*)                      echo "OK.ru 🌐" ;;
        *vk.com*)                     echo "VKontakte 🌐" ;;
        *)                            echo "Website 🌐" ;;
    esac
}

# ─────────────────────────────────────────────
# CORE DOWNLOAD ENGINE
# ─────────────────────────────────────────────

run_download() {
    local url="$1"
    shift
    local extra_args=("$@")
    local platform=$(detect_platform "$url")
    
    echo ""
    draw_line "─" "$DIM"
    print_status info "Platform: ${ACCENT}${platform}${RESET}"
    print_status info "URL: ${DIM}${url:0:60}...${RESET}"
    draw_line "─" "$DIM"
    echo ""
    
    # Build yt-dlp command
    local cmd=(yt-dlp)
    
    # Use aria2c if available and enabled
    if [[ "$USE_ARIA2" == "true" ]] && command -v aria2c &>/dev/null; then
        cmd+=(--downloader aria2c --downloader-args "aria2c:-j ${MAX_CONCURRENT} -s ${MAX_CONCURRENT}")
    fi
    
    # Progress bar style
    cmd+=(--progress --newline)
    
    # Output template
    cmd+=(-o "${DOWNLOAD_DIR}/%(uploader)s/%(title)s.%(ext)s")
    
    # Add rate limit protection
    cmd+=(--sleep-interval 2 --max-sleep-interval 5)
    
    # Add user provided args
    cmd+=("${extra_args[@]}")
    
    # Add URL
    cmd+=("$url")
    
    # Log the command
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${cmd[*]}" >> "$LOG_FILE"
    
    echo -e "  ${WHITE}${BOLD}Starting download...${RESET}"
    echo ""
    
    # Run download
    "${cmd[@]}"
    local exit_code=$?
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        draw_line "─" "$GREEN"
        print_status ok "${GREEN}${BOLD}Download completed successfully!${RESET}"
        draw_line "─" "$GREEN"
        
        # Show file location
        local latest_file=$(find "$DOWNLOAD_DIR" -type f -newer "$LOG_FILE" 2>/dev/null | head -1)
        if [[ -n "$latest_file" ]]; then
            echo ""
            print_status info "Saved to: ${CYAN}${latest_file}${RESET}"
        fi
        
        # Send notification
        if [[ "$NOTIFY_ON_DONE" == "true" ]]; then
            termux-notification \
                --title "MediaLoad ✅" \
                --content "Download complete!" \
                --priority high 2>/dev/null &
        fi
        
        # Open folder in Android
        echo ""
        if confirm "Open downloads folder?"; then
            termux-open "$DOWNLOAD_DIR" 2>/dev/null || \
            am start -a android.intent.action.VIEW \
                -d "file://$DOWNLOAD_DIR" 2>/dev/null &
        fi
    else
        draw_line "─" "$RED"
        print_status err "Download failed! (exit code: $exit_code)"
        draw_line "─" "$RED"
        echo ""
        print_status info "Common fixes:"
        echo -e "  ${DIM}• Check your internet connection${RESET}"
        echo -e "  ${DIM}• URL may be geo-restricted or private${RESET}"
        echo -e "  ${DIM}• Try updating: ${CYAN}pip install -U yt-dlp${RESET}"
        echo -e "  ${DIM}• For age-restricted content, use cookies${RESET}"
    fi
    
    echo ""
    press_any_key
}

# ─────────────────────────────────────────────
# 1. DOWNLOAD VIDEO
# ─────────────────────────────────────────────

download_video_menu() {
    cls
    print_banner
    echo -e "  ${WHITE}${BOLD}📥 DOWNLOAD VIDEO${RESET}"
    draw_line "─" "$DIM"
    echo ""
    
    input_prompt "Enter URL" url ""
    [[ -z "$url" ]] && { print_status warn "No URL entered."; sleep 1; return; }
    
    # Select quality
    quality=$(select_quality)
    
    # Select format
    format=$(select_video_format)
    
    # Subtitle option
    echo ""
    echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}Download subtitles? [y/N]: ${RESET}"
    read -r subs
    
    # Build args
    local args=(-f "$quality" --merge-output-format "$format")
    [[ "${subs,,}" == "y" ]] && args+=(--write-auto-subs --sub-lang en --embed-subs)
    
    # Add to downloads/videos dir
    args+=(-P "$DOWNLOAD_DIR/videos")
    
    run_download "$url" "${args[@]}"
}

# ─────────────────────────────────────────────
# 2. DOWNLOAD AUDIO
# ─────────────────────────────────────────────

download_audio_menu() {
    cls
    print_banner
    echo -e "  ${WHITE}${BOLD}🎵 DOWNLOAD AUDIO${RESET}"
    draw_line "─" "$DIM"
    echo ""
    
    input_prompt "Enter URL" url ""
    [[ -z "$url" ]] && { print_status warn "No URL entered."; sleep 1; return; }
    
    format=$(select_audio_format)
    
    echo ""
    echo -e "  ${WHITE}${BOLD}SELECT AUDIO QUALITY:${RESET}"
    echo ""
    echo -e "  ${ACCENT}  1  ${RESET}  ${WHITE}Best available${RESET}"
    echo -e "  ${ACCENT}  2  ${RESET}  ${WHITE}320 kbps${RESET}"
    echo -e "  ${ACCENT}  3  ${RESET}  ${WHITE}192 kbps${RESET}"
    echo -e "  ${ACCENT}  4  ${RESET}  ${WHITE}128 kbps${RESET}"
    echo ""
    echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}Select quality [1]: ${RESET}"
    read -r aq
    
    local bitrate
    case "${aq:-1}" in
        1) bitrate="0" ;;
        2) bitrate="320" ;;
        3) bitrate="192" ;;
        4) bitrate="128" ;;
        *) bitrate="0" ;;
    esac
    
    local args=(-x --audio-format "$format" --audio-quality "$bitrate")
    args+=(-P "$DOWNLOAD_DIR/audio")
    # Embed thumbnail in audio file
    args+=(--embed-thumbnail --add-metadata)
    
    run_download "$url" "${args[@]}"
}

# ─────────────────────────────────────────────
# 3. DOWNLOAD IMAGES
# ─────────────────────────────────────────────

download_images_menu() {
    cls
    print_banner
    echo -e "  ${WHITE}${BOLD}📸 DOWNLOAD IMAGES${RESET}"
    draw_line "─" "$DIM"
    echo ""
    
    echo -e "  ${DIM}Supported: Instagram posts/stories, Twitter/X, Reddit, Pinterest...${RESET}"
    echo ""
    
    input_prompt "Enter URL" url ""
    [[ -z "$url" ]] && { print_status warn "No URL entered."; sleep 1; return; }
    
    local args=(--write-thumbnail --skip-download)
    # Also try to download actual images if it's a gallery
    args+=(--yes-playlist -P "$DOWNLOAD_DIR/images")
    
    echo ""
    echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}Download all images in post? [Y/n]: ${RESET}"
    read -r all_imgs
    
    if [[ "${all_imgs,,}" != "n" ]]; then
        args=(--yes-playlist -P "$DOWNLOAD_DIR/images")
        # For galleries, get all images
        args+=(--write-thumbnail)
    fi
    
    run_download "$url" "${args[@]}"
}

# ─────────────────────────────────────────────
# 4. DOWNLOAD PLAYLIST
# ─────────────────────────────────────────────

download_playlist_menu() {
    cls
    print_banner
    echo -e "  ${WHITE}${BOLD}📋 DOWNLOAD PLAYLIST${RESET}"
    draw_line "─" "$DIM"
    echo ""
    
    input_prompt "Enter Playlist URL" url ""
    [[ -z "$url" ]] && { print_status warn "No URL entered."; sleep 1; return; }
    
    # Get playlist info first
    print_status info "Fetching playlist info..."
    local playlist_title=$(yt-dlp --flat-playlist --print "%(playlist_title)s" "$url" 2>/dev/null | head -1)
    local playlist_count=$(yt-dlp --flat-playlist --print "%(playlist_count)s" "$url" 2>/dev/null | head -1)
    
    echo ""
    echo -e "  ${ACCENT}Playlist:${RESET} ${WHITE}${playlist_title:-Unknown}${RESET}"
    echo -e "  ${ACCENT}Videos:${RESET}   ${WHITE}${playlist_count:-Unknown}${RESET}"
    echo ""
    
    # Download range
    input_prompt "Start index (leave empty for all)" start_idx "1"
    input_prompt "End index (leave empty for all)" end_idx ""
    
    quality=$(select_quality)
    format=$(select_video_format)
    
    local args=(-f "$quality" --merge-output-format "$format")
    args+=(--yes-playlist)
    args+=(-P "$DOWNLOAD_DIR/playlists")
    args+=(-o "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s")
    
    [[ -n "$start_idx" && -n "$end_idx" ]] && args+=(--playlist-start "$start_idx" --playlist-end "$end_idx")
    [[ -n "$start_idx" && -z "$end_idx" ]] && args+=(--playlist-start "$start_idx")
    
    # Concurrent downloads
    args+=(--concurrent-fragments "$MAX_CONCURRENT")
    
    run_download "$url" "${args[@]}"
}

# ─────────────────────────────────────────────
# 5. BATCH DOWNLOAD
# ─────────────────────────────────────────────

batch_download_menu() {
    cls
    print_banner
    echo -e "  ${WHITE}${BOLD}⚡ BATCH DOWNLOAD${RESET}"
    draw_line "─" "$DIM"
    echo ""
    
    echo -e "  ${DIM}Enter URLs one per line. Type ${CYAN}DONE${DIM} when finished.${RESET}"
    echo ""
    
    local url_file="$INSTALL_DIR/batch_urls_$(date +%s).txt"
    > "$url_file"
    
    local count=0
    while true; do
        echo -ne "  ${ACCENT}URL $((count+1))${RESET}> "
        read -r line
        [[ "${line^^}" == "DONE" || -z "$line" ]] && break
        echo "$line" >> "$url_file"
        ((count++))
        print_status ok "Added: ${DIM}${line:0:50}...${RESET}"
    done
    
    if [[ $count -eq 0 ]]; then
        print_status warn "No URLs entered."
        sleep 1
        rm -f "$url_file"
        return
    fi
    
    echo ""
    print_status info "Ready to download $count URLs"
    
    quality=$(select_quality)
    format=$(select_video_format)
    
    local args=(-f "$quality" --merge-output-format "$format")
    args+=(-P "$DOWNLOAD_DIR/videos")
    args+=(--concurrent-fragments "$MAX_CONCURRENT")
    args+=(-a "$url_file")  # Read URLs from file
    
    # Use batch file mode
    echo ""
    print_status arrow "Starting batch download of $count URLs..."
    echo ""
    
    yt-dlp -f "$quality" \
        --merge-output-format "$format" \
        -P "$DOWNLOAD_DIR/videos" \
        -o "%(uploader)s/%(title)s.%(ext)s" \
        -a "$url_file" \
        --progress --newline
    
    rm -f "$url_file"
    echo ""
    print_status ok "Batch download process completed!"
    press_any_key
}

# ─────────────────────────────────────────────
# 6. VIDEO INFO
# ─────────────────────────────────────────────

video_info_menu() {
    cls
    print_banner
    echo -e "  ${WHITE}${BOLD}🔍 GET VIDEO INFO${RESET}"
    draw_line "─" "$DIM"
    echo ""
    
    input_prompt "Enter URL" url ""
    [[ -z "$url" ]] && { print_status warn "No URL entered."; sleep 1; return; }
    
    echo ""
    print_status info "Fetching video information..."
    echo ""
    
    # Get info in JSON and parse
    local info=$(yt-dlp --dump-single-json \
        --no-warnings \
        --no-playlist \
        "$url" 2>/dev/null)
    
    if [[ -z "$info" ]]; then
        print_status err "Could not fetch video info. Check the URL."
        press_any_key
        return
    fi
    
    draw_line "═" "$ACCENT"
    echo ""
    
    local title=$(echo "$info" | python -c "import sys,json; d=json.load(sys.stdin); print(d.get('title','N/A'))" 2>/dev/null)
    local uploader=$(echo "$info" | python -c "import sys,json; d=json.load(sys.stdin); print(d.get('uploader','N/A'))" 2>/dev/null)
    local duration=$(echo "$info" | python -c "import sys,json; d=json.load(sys.stdin); s=d.get('duration',0); print(f'{s//3600:02d}:{(s%3600)//60:02d}:{s%60:02d}')" 2>/dev/null)
    local views=$(echo "$info" | python -c "import sys,json; d=json.load(sys.stdin); v=d.get('view_count',0); print(f'{v:,}' if v else 'N/A')" 2>/dev/null)
    local likes=$(echo "$info" | python -c "import sys,json; d=json.load(sys.stdin); l=d.get('like_count',0); print(f'{l:,}' if l else 'N/A')" 2>/dev/null)
    local upload_date=$(echo "$info" | python -c "import sys,json; d=json.load(sys.stdin); date=d.get('upload_date',''); print(f'{date[:4]}-{date[4:6]}-{date[6:]}' if date else 'N/A')" 2>/dev/null)
    local description=$(echo "$info" | python -c "import sys,json; d=json.load(sys.stdin); print(d.get('description','N/A')[:200])" 2>/dev/null)
    local webpage_url=$(echo "$info" | python -c "import sys,json; d=json.load(sys.stdin); print(d.get('webpage_url','N/A'))" 2>/dev/null)
    
    printf "  ${ACCENT}%-15s${RESET}  %s\n" "Title:" "$title"
    printf "  ${ACCENT}%-15s${RESET}  %s\n" "Uploader:" "$uploader"
    printf "  ${ACCENT}%-15s${RESET}  %s\n" "Duration:" "$duration"
    printf "  ${ACCENT}%-15s${RESET}  %s\n" "Views:" "$views"
    printf "  ${ACCENT}%-15s${RESET}  %s\n" "Likes:" "$likes"
    printf "  ${ACCENT}%-15s${RESET}  %s\n" "Upload Date:" "$upload_date"
    printf "  ${ACCENT}%-15s${RESET}  %s\n" "URL:" "${webpage_url:0:60}"
    echo ""
    
    draw_line "─" "$DIM"
    echo -e "  ${DIM}Description:${RESET}"
    echo -e "  ${DIM}${description}${RESET}"
    echo ""
    
    # Show available formats
    draw_line "─" "$DIM"
    echo -e "  ${WHITE}${BOLD}AVAILABLE FORMATS:${RESET}"
    echo ""
    yt-dlp --list-formats --no-warnings "$url" 2>/dev/null | head -30
    echo ""
    
    # Offer to download
    if confirm "Download this video?"; then
        download_video_menu_with_url "$url"
    fi
    
    press_any_key
}

download_video_menu_with_url() {
    local url="$1"
    quality=$(select_quality)
    format=$(select_video_format)
    local args=(-f "$quality" --merge-output-format "$format" -P "$DOWNLOAD_DIR/videos")
    run_download "$url" "${args[@]}"
}

# ─────────────────────────────────────────────
# 7. MY DOWNLOADS
# ─────────────────────────────────────────────

my_downloads_menu() {
    while true; do
        cls
        print_banner
        echo -e "  ${WHITE}${BOLD}📁 MY DOWNLOADS${RESET}"
        draw_line "─" "$DIM"
        echo ""
        
        # Stats
        local total_files=$(find "$DOWNLOAD_DIR" -type f 2>/dev/null | wc -l)
        local total_size=$(du -sh "$DOWNLOAD_DIR" 2>/dev/null | cut -f1)
        local video_count=$(find "$DOWNLOAD_DIR/videos" -type f 2>/dev/null | wc -l)
        local audio_count=$(find "$DOWNLOAD_DIR/audio" -type f 2>/dev/null | wc -l)
        local image_count=$(find "$DOWNLOAD_DIR/images" -type f 2>/dev/null | wc -l)
        
        echo -e "  ${ACCENT}Total Files:${RESET}  ${WHITE}${total_files}${RESET}  ${DIM}│${RESET}  ${ACCENT}Total Size:${RESET}  ${WHITE}${total_size}${RESET}"
        echo ""
        echo -e "  ${ACCENT}📹 Videos:${RESET}  ${WHITE}${video_count}${RESET}  ${DIM}│${RESET}  ${ACCENT}🎵 Audio:${RESET}  ${WHITE}${audio_count}${RESET}  ${DIM}│${RESET}  ${ACCENT}📸 Images:${RESET}  ${WHITE}${image_count}${RESET}"
        echo ""
        draw_line "─" "$DIM"
        echo ""
        echo -e "  ${ACCENT}  1  ${RESET}  List all files"
        echo -e "  ${ACCENT}  2  ${RESET}  Open downloads folder in Android"
        echo -e "  ${ACCENT}  3  ${RESET}  Delete all downloads"
        echo -e "  ${ACCENT}  4  ${RESET}  View download history (log)"
        echo -e "  ${ACCENT}  5  ${RESET}  Share a file"
        echo -e "  ${ACCENT}  0  ${RESET}  Back to main menu"
        echo ""
        echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}Select option: ${RESET}"
        read -r choice
        
        case "$choice" in
            1)
                echo ""
                echo -e "  ${WHITE}${BOLD}Recent Downloads:${RESET}"
                echo ""
                find "$DOWNLOAD_DIR" -type f -newer /tmp 2>/dev/null | \
                    sort -r | head -20 | while read -r f; do
                    local size=$(du -sh "$f" 2>/dev/null | cut -f1)
                    echo -e "  ${DIM}${size}${RESET}  ${CYAN}$(basename "$f")${RESET}"
                done
                press_any_key ;;
            2)
                termux-open "$DOWNLOAD_DIR" 2>/dev/null || \
                    xdg-open "$DOWNLOAD_DIR" 2>/dev/null
                print_status ok "Opened in file manager" ;;
            3)
                if confirm "Delete ALL downloads? This cannot be undone!"; then
                    rm -rf "${DOWNLOAD_DIR:?}"/*
                    print_status ok "All downloads deleted"
                    sleep 1
                fi ;;
            4)
                echo ""
                echo -e "  ${WHITE}${BOLD}Recent Download History:${RESET}"
                echo ""
                tail -30 "$LOG_FILE" 2>/dev/null || \
                    print_status info "No download history found"
                press_any_key ;;
            5)
                echo ""
                input_prompt "Enter file path to share" share_path ""
                if [[ -f "$share_path" ]]; then
                    termux-share "$share_path" 2>/dev/null || \
                        print_status warn "termux-api not installed"
                else
                    print_status err "File not found"
                fi
                sleep 1 ;;
            0|b|B) return ;;
        esac
    done
}

# ─────────────────────────────────────────────
# 8. SUPPORTED SITES
# ─────────────────────────────────────────────

supported_sites_menu() {
    cls
    print_banner
    echo -e "  ${WHITE}${BOLD}📱 SUPPORTED PLATFORMS${RESET}"
    draw_line "─" "$DIM"
    echo ""
    
    echo -e "  ${WHITE}${BOLD}🌟 Popular Platforms:${RESET}"
    echo ""
    
    local platforms=(
        "YouTube"           "Videos, shorts, live, playlists"
        "Instagram"         "Posts, reels, stories, IGTV"
        "Twitter / X"       "Videos, GIFs, images"
        "TikTok"            "Videos, slideshows"
        "Facebook"          "Videos, reels, stories"
        "Reddit"            "Videos, GIFs, images"
        "Twitch"            "VODs, clips, streams"
        "Vimeo"             "HD videos"
        "Dailymotion"       "Videos"
        "SoundCloud"        "Tracks, playlists"
        "Pinterest"         "Images, videos"
        "LinkedIn"          "Videos"
        "Tumblr"            "Videos, images"
        "Bilibili"          "Videos"
        "NicoNico"          "Japanese videos"
        "Twitch"            "Clips, VODs"
        "Bandcamp"          "Music"
        "Mixcloud"          "Podcasts, music"
        "Odysee"            "Videos"
        "Rumble"            "Videos"
    )
    
    local i=0
    while [[ $i -lt ${#platforms[@]} ]]; do
        printf "  ${ACCENT}%-20s${RESET}  ${DIM}%s${RESET}\n" "${platforms[$i]}" "${platforms[$((i+1))]}"
        ((i+=2))
    done
    
    echo ""
    draw_line "─" "$DIM"
    echo ""
    print_status info "yt-dlp supports 1000+ sites! Run: ${CYAN}yt-dlp --list-extractors${RESET}"
    echo ""
    
    if confirm "Show full list of supported extractors?"; then
        yt-dlp --list-extractors 2>/dev/null | less
    fi
    
    press_any_key
}

# ─────────────────────────────────────────────
# 9. SETTINGS
# ─────────────────────────────────────────────

settings_menu() {
    while true; do
        cls
        print_banner
        echo -e "  ${WHITE}${BOLD}⚙️  SETTINGS${RESET}"
        draw_line "─" "$DIM"
        echo ""
        
        echo -e "  ${ACCENT}  1  ${RESET}  Download Directory    ${DIM}[${CYAN}${DOWNLOAD_DIR: -30}${RESET}${DIM}]${RESET}"
        echo -e "  ${ACCENT}  2  ${RESET}  Video Quality         ${DIM}[${CYAN}${DEFAULT_VIDEO_QUALITY}${RESET}${DIM}]${RESET}"
        echo -e "  ${ACCENT}  3  ${RESET}  Video Format          ${DIM}[${CYAN}${DEFAULT_VIDEO_FORMAT}${RESET}${DIM}]${RESET}"
        echo -e "  ${ACCENT}  4  ${RESET}  Audio Format          ${DIM}[${CYAN}${DEFAULT_AUDIO_FORMAT}${RESET}${DIM}]${RESET}"
        echo -e "  ${ACCENT}  5  ${RESET}  Use Aria2c            ${DIM}[${CYAN}${USE_ARIA2}${RESET}${DIM}]${RESET}"
        echo -e "  ${ACCENT}  6  ${RESET}  Max Concurrent        ${DIM}[${CYAN}${MAX_CONCURRENT}${RESET}${DIM}]${RESET}"
        echo -e "  ${ACCENT}  7  ${RESET}  Notifications         ${DIM}[${CYAN}${NOTIFY_ON_DONE}${RESET}${DIM}]${RESET}"
        echo -e "  ${ACCENT}  8  ${RESET}  Theme Color           ${DIM}[${ACCENT}${THEME_COLOR}${RESET}${DIM}]${RESET}"
        echo -e "  ${ACCENT}  9  ${RESET}  Update yt-dlp"
        echo -e "  ${ACCENT}  10 ${RESET}  Update MediaLoad"
        echo -e "  ${ACCENT}  11 ${RESET}  Android Shortcut Help"
        echo -e "  ${ACCENT}  0  ${RESET}  Back"
        echo ""
        echo -ne "  ${ACCENT}◆${RESET}  ${WHITE}Select option: ${RESET}"
        read -r choice
        
        case "$choice" in
            1)
                input_prompt "New download directory" new_dir "$DOWNLOAD_DIR"
                mkdir -p "$new_dir"
                sed -i "s|DOWNLOAD_DIR=.*|DOWNLOAD_DIR=\"$new_dir\"|" "$CONFIG_FILE"
                DOWNLOAD_DIR="$new_dir"
                print_status ok "Download directory updated" ;;
            2)
                echo -e "\n  ${DIM}Options: best/1080p/720p/480p/360p/worst${RESET}"
                input_prompt "Video quality" new_q "$DEFAULT_VIDEO_QUALITY"
                sed -i "s|DEFAULT_VIDEO_QUALITY=.*|DEFAULT_VIDEO_QUALITY=\"$new_q\"|" "$CONFIG_FILE"
                DEFAULT_VIDEO_QUALITY="$new_q"
                print_status ok "Video quality updated" ;;
            3)
                echo -e "\n  ${DIM}Options: mp4/mkv/webm/avi/mov${RESET}"
                input_prompt "Video format" new_f "$DEFAULT_VIDEO_FORMAT"
                sed -i "s|DEFAULT_VIDEO_FORMAT=.*|DEFAULT_VIDEO_FORMAT=\"$new_f\"|" "$CONFIG_FILE"
                DEFAULT_VIDEO_FORMAT="$new_f"
                print_status ok "Video format updated" ;;
            4)
                echo -e "\n  ${DIM}Options: mp3/m4a/opus/flac/wav${RESET}"
                input_prompt "Audio format" new_af "$DEFAULT_AUDIO_FORMAT"
                sed -i "s|DEFAULT_AUDIO_FORMAT=.*|DEFAULT_AUDIO_FORMAT=\"$new_af\"|" "$CONFIG_FILE"
                DEFAULT_AUDIO_FORMAT="$new_af"
                print_status ok "Audio format updated" ;;
            5)
                [[ "$USE_ARIA2" == "true" ]] && USE_ARIA2="false" || USE_ARIA2="true"
                sed -i "s|USE_ARIA2=.*|USE_ARIA2=$USE_ARIA2|" "$CONFIG_FILE"
                print_status ok "Aria2c: $USE_ARIA2" ;;
            6)
                input_prompt "Max concurrent downloads (1-8)" new_mc "$MAX_CONCURRENT"
                sed -i "s|MAX_CONCURRENT=.*|MAX_CONCURRENT=$new_mc|" "$CONFIG_FILE"
                MAX_CONCURRENT="$new_mc"
                print_status ok "Concurrent downloads: $new_mc" ;;
            7)
                [[ "$NOTIFY_ON_DONE" == "true" ]] && NOTIFY_ON_DONE="false" || NOTIFY_ON_DONE="true"
                sed -i "s|NOTIFY_ON_DONE=.*|NOTIFY_ON_DONE=$NOTIFY_ON_DONE|" "$CONFIG_FILE"
                print_status ok "Notifications: $NOTIFY_ON_DONE" ;;
            8)
                echo -e "\n  ${DIM}Options: cyan/green/magenta/yellow/blue${RESET}"
                input_prompt "Theme color" new_theme "$THEME_COLOR"
                sed -i "s|THEME_COLOR=.*|THEME_COLOR=\"$new_theme\"|" "$CONFIG_FILE"
                THEME_COLOR="$new_theme"
                print_status ok "Theme updated. Restart to apply." ;;
            9)
                echo ""
                print_status arrow "Updating yt-dlp..."
                pip install -U yt-dlp && print_status ok "yt-dlp updated!" || \
                    yt-dlp -U && print_status ok "yt-dlp updated!" ;;
            10)
                echo ""
                print_status arrow "Updating MediaLoad..."
                SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                cd "$SCRIPT_DIR" && git pull 2>/dev/null && \
                    cp mediaload.sh "$PREFIX/bin/mediaload" && \
                    print_status ok "MediaLoad updated!" || \
                    print_status warn "Could not auto-update. Pull manually from GitHub." ;;
            11) shortcut_help ;;
            0|b|B) return ;;
        esac
        
        sleep 1
    done
}

shortcut_help() {
    cls
    print_banner
    echo -e "  ${WHITE}${BOLD}📱 ANDROID HOME SCREEN SHORTCUT${RESET}"
    draw_line "─" "$DIM"
    echo ""
    echo -e "  ${WHITE}Method 1: Termux:Widget (Recommended)${RESET}"
    echo ""
    echo -e "  ${ACCENT}Step 1:${RESET} Install ${CYAN}Termux:Widget${RESET} from F-Droid"
    echo -e "           ${BLUE}https://f-droid.org/packages/com.termux.widget/${RESET}"
    echo ""
    echo -e "  ${ACCENT}Step 2:${RESET} The shortcut script is already installed at:"
    echo -e "           ${DIM}~/.shortcuts/MediaLoad.sh${RESET}"
    echo ""
    echo -e "  ${ACCENT}Step 3:${RESET} Long-press your Android home screen"
    echo -e "           → Add Widget → Termux:Widget"
    echo -e "           → Select ${CYAN}MediaLoad${RESET}"
    echo ""
    draw_line "─" "$DIM"
    echo ""
    echo -e "  ${WHITE}Method 2: Termux:Tasker Integration${RESET}"
    echo ""
    echo -e "  Install ${CYAN}Tasker${RESET} + ${CYAN}Termux:Tasker${RESET} from Play Store/F-Droid"
    echo -e "  Create a Task that runs: ${GREEN}bash ~/.shortcuts/MediaLoad.sh${RESET}"
    echo -e "  Assign it a launcher shortcut or a home screen tap gesture"
    echo ""
    press_any_key
}

# ─────────────────────────────────────────────
# COMMAND LINE ARGUMENT HANDLER
# ─────────────────────────────────────────────

handle_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--url)
                shift
                url="$1"
                shift
                ;;
            -f|--format)
                shift
                format="$1"
                shift
                ;;
            -a|--audio)
                mode="audio"
                shift
                ;;
            -v|--video)
                mode="video"
                shift
                ;;
            -p|--playlist)
                mode="playlist"
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            -U|--update)
                pip install -U yt-dlp
                exit 0
                ;;
            *)
                # Assume it's a URL
                url="$1"
                shift
                ;;
        esac
    done
    
    if [[ -n "$url" ]]; then
        case "${mode:-video}" in
            audio)    args=(-x --audio-format "${format:-mp3}")
                      run_download "$url" "${args[@]}"
                      exit 0 ;;
            playlist) args=(--yes-playlist -f "bestvideo+bestaudio/best" --merge-output-format mp4)
                      run_download "$url" "${args[@]}"
                      exit 0 ;;
            *)        args=(-f "bestvideo+bestaudio/best" --merge-output-format "${format:-mp4}")
                      run_download "$url" "${args[@]}"
                      exit 0 ;;
        esac
    fi
}

print_help() {
    print_banner
    echo -e "  ${WHITE}${BOLD}USAGE:${RESET}"
    echo ""
    echo -e "  ${CYAN}mediaload${RESET}                    Launch interactive menu"
    echo -e "  ${CYAN}mediaload${RESET} [URL]              Quick download (auto-detect)"
    echo -e "  ${CYAN}mediaload${RESET} -u [URL] -v        Download video"
    echo -e "  ${CYAN}mediaload${RESET} -u [URL] -a        Download audio"
    echo -e "  ${CYAN}mediaload${RESET} -u [URL] -p        Download playlist"
    echo -e "  ${CYAN}mediaload${RESET} -u [URL] -f mp3    Specify format"
    echo -e "  ${CYAN}mediaload${RESET} -U                 Update yt-dlp"
    echo -e "  ${CYAN}mediaload${RESET} -h                 Show this help"
    echo ""
    echo -e "  ${WHITE}${BOLD}EXAMPLES:${RESET}"
    echo ""
    echo -e "  ${DIM}# Download YouTube video${RESET}"
    echo -e "  ${CYAN}mediaload https://youtu.be/dQw4w9WgXcQ${RESET}"
    echo ""
    echo -e "  ${DIM}# Download Instagram reel as MP4${RESET}"
    echo -e "  ${CYAN}mediaload -u https://instagram.com/reel/abc -v -f mp4${RESET}"
    echo ""
    echo -e "  ${DIM}# Download audio as MP3${RESET}"
    echo -e "  ${CYAN}mediaload -u https://youtu.be/xyz -a -f mp3${RESET}"
    echo ""
}

# ─────────────────────────────────────────────
# STARTUP CHECKS
# ─────────────────────────────────────────────

startup_checks() {
    # Ensure directories exist
    mkdir -p "$INSTALL_DIR" "$DOWNLOAD_DIR" \
        "$DOWNLOAD_DIR/videos" "$DOWNLOAD_DIR/audio" \
        "$DOWNLOAD_DIR/images" "$DOWNLOAD_DIR/playlists" \
        "$INSTALL_DIR/logs" "$INSTALL_DIR/config" 2>/dev/null
    
    # Ensure log file exists
    touch "$LOG_FILE" 2>/dev/null
    
    # Check yt-dlp
    if ! command -v yt-dlp &>/dev/null; then
        echo -e "${RED}Error: yt-dlp is not installed!${RESET}"
        echo -e "Run: ${CYAN}pip install yt-dlp${RESET}"
        exit 1
    fi
}

# ─────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────

startup_checks

# Handle command-line arguments
if [[ $# -gt 0 ]]; then
    handle_args "$@"
fi

# Launch interactive menu
main_menu
