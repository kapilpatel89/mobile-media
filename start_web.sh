#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
#   MediaLoad Web UI Launcher
#   Fast startup for the PWA Server
# ============================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
RESET='\033[0m'

clear
echo -e "${CYAN}🚀 Starting MediaLoad Web UI...${RESET}"

# Check for flask
if ! python3 -c "import flask" &> /dev/null; then
    echo -e "${WHITE}Installing Flask...${RESET}"
    pip install flask yt-dlp
fi

# Get Local IP
IP=$(ifconfig wlan0 | grep 'inet ' | awk '{print $2}')
if [ -z "$IP" ]; then
    IP="localhost"
fi

PORT=5000
URL="http://$IP:$PORT"

echo -e "${GREEN}✅ Server is starting!${RESET}"
echo -e "${WHITE}----------------------------------------${RESET}"
echo -e "📱 Access URL: ${CYAN}$URL${RESET}"
echo -e "${WHITE}----------------------------------------${RESET}"
echo -e "Press Ctrl+C to stop the server."

# Automatically open in browser if termux-open-url is available
if command -v termux-open-url &> /dev/null; then
    sleep 2
    termux-open-url "$URL"
fi

# Run the python app
python3 app.py
