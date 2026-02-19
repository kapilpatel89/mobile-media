#!/data/data/com.termux/files/usr/bin/bash

# Social Media Downloader - Web UI Launcher
# Designed for Termux Shortcut

APP_DIR="$HOME/.mediaload"
SERVER_SCRIPT="$HOME/mobile-media/app.py"

# Kill old instances
pkill -f "python app.py" 2>/dev/null

# Clear screen and show premium loader
clear
echo -e "\033[0;36m"
echo "  ███╗   ███╗███████╗██████╗ ██╗ █████╗ "
echo "  ████╗ ████║██╔════╝██╔══██╗██║██╔══██╗"
echo "  ██╔████╔██║█████╗  ██║  ██║██║███████║"
echo "  ██║╚██╔╝██║██╔══╝  ██║  ██║██║██╔══██║"
echo "  ██║ ╚═╝ ██║███████╗██████╔╝██║██║  ██║"
echo "  ╚═╝     ╚═╝╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝"
echo -e "\033[0m"
echo -e "\033[1;37m  Starting MediaLoad Web Server...\033[0m"
echo ""

# Start Flask in background
python "$SERVER_SCRIPT" > /dev/null 2>&1 &
SERVER_PID=$!

# Wait for server to be ready
sleep 2

# Open browser
termux-open "http://localhost:5000"

echo -e "\033[0;32m  ✔ Server is running at http://localhost:5000\033[0m"
echo -e "\033[0;33m  ℹ Do not close this terminal while using the app.\033[0m"
echo ""
echo -e "\033[1;37m  Press Ctrl+C to stop the server.\033[0m"

# Handle exit
trap "kill $SERVER_PID; exit" SIGINT SIGTERM

# Keep termux alive
wait $SERVER_PID
