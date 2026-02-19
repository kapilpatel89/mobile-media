<div align="center">

```
  ███╗   ███╗███████╗██████╗ ██╗ █████╗    ██╗      ██████╗  █████╗ ██████╗ 
  ████╗ ████║██╔════╝██╔══██╗██║██╔══██╗   ██║     ██╔═══██╗██╔══██╗██╔══██╗
  ██╔████╔██║█████╗  ██║  ██║██║███████║   ██║     ██║   ██║███████║██║  ██║
  ██║╚██╔╝██║██╔══╝  ██║  ██║██║██╔══██║   ██║     ██║   ██║██╔══██║██║  ██║
  ██║ ╚═╝ ██║███████╗██████╔╝██║██║  ██║   ███████╗╚██████╔╝██║  ██║██████╔╝
  ╚═╝     ╚═╝╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ 
```

# 📲 MediaLoad - Social Media Downloader for Termux

**A beautiful, feature-rich social media downloader that runs directly in Termux on Android.**  
Download videos, audio, images, and playlists from 1000+ platforms with a stunning terminal UI.

[![Made for Termux](https://img.shields.io/badge/Made%20for-Termux-black?style=for-the-badge&logo=android&logoColor=green)](https://termux.dev)
[![Powered by yt-dlp](https://img.shields.io/badge/Powered%20by-yt--dlp-red?style=for-the-badge&logo=youtube)](https://github.com/yt-dlp/yt-dlp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![College Project](https://img.shields.io/badge/🎓-College%20Learning%20Project-blue?style=for-the-badge)]()
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash)](https://www.gnu.org/software/bash/)

</div>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎬 **Video Download** | MP4, MKV, WEBM, AVI, MOV — any quality from 360p to 4K |
| 🎵 **Audio Download** | MP3, M4A, OPUS, FLAC, WAV with embedded thumbnails |
| 📸 **Image Download** | Instagram posts, Twitter/X images, Reddit galleries |
| 📋 **Playlist Download** | Full playlists with index control |
| ⚡ **Batch Download** | Download multiple URLs simultaneously |
| 🔍 **Video Info** | Inspect metadata and formats before downloading |
| 📁 **File Manager** | Browse, manage, and share your downloads |
| 📱 **Android Shortcut** | Home screen icon via Termux:Widget |
| ⚙️ **Full Settings** | Quality, format, theme, notifications, aria2c |
| 🔔 **Notifications** | Android notification when download completes |
| 🌐 **1000+ Sites** | All platforms supported by yt-dlp |

---

## 📱 Supported Platforms

<div align="center">

| Platform | Content Types |
|---|---|
| 🎬 **YouTube** | Videos, Shorts, Live, Playlists, Chapters |
| 📸 **Instagram** | Posts, Reels, Stories, IGTV |
| 🐦 **Twitter / X** | Videos, GIFs, Images |
| 🎵 **TikTok** | Videos, Slideshows |
| 📘 **Facebook** | Videos, Reels, Stories |
| 🤖 **Reddit** | Videos, GIFs, Image galleries |
| 🎮 **Twitch** | VODs, Clips |
| 🎥 **Vimeo** | HD Videos |
| 🎧 **SoundCloud** | Tracks, Playlists |
| 📌 **Pinterest** | Images, Videos |
| 💼 **LinkedIn** | Videos |
| 📺 **Bilibili** | Videos |
| 🎵 **Spotify** | Podcasts (via YouTube match) |
| 🌐 **+1000 more** | See full list below |

</div>

> **Full list:** Run `yt-dlp --list-extractors` or visit [yt-dlp supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)

---

## 🚀 One-Command Install

Open **Termux** and paste this single command:

```bash
pkg install git -y && rm -rf mobile-media && git clone https://github.com/kapilpatel89/mobile-media && cd mobile-media && bash install.sh
```

> **Reinstalling?** The command above automatically removes any old folder first — safe to run multiple times.

> **That's it!** The installer automatically handles everything.

---

## 📦 What the Installer Does

```
1. ✅ Checks Termux environment
2. 📦 Installs: python, ffmpeg, curl, git, aria2, dialog, and more
3. 🔧 Installs yt-dlp (latest version via pip)
4. 📁 Creates download directories (linked to Android storage)
5. 🔑 Requests storage permission
6. ⚙️  Creates default config file
7. 📲 Sets up Android home screen shortcut scripts
8. 🔗 Creates 'mediaload' and 'ml' launch commands
9. 🔍 Verifies all installations
10. 🚀 Launches MediaLoad automatically
```

---

## 🎮 How to Use

### Interactive Mode (Recommended)
```bash
mediaload
# or use the shorthand:
ml
```

### Quick Downloads (Command Line)
```bash
# Download a YouTube video
mediaload https://youtu.be/VIDEO_ID

# Download as MP3 audio
mediaload -u https://youtu.be/VIDEO_ID -a -f mp3

# Download a video in best quality
mediaload -u https://youtu.be/VIDEO_ID -v -f mp4

# Download an entire playlist
mediaload -u https://youtube.com/playlist?list=XXXXX -p

# Update yt-dlp
mediaload -U
```

### From Android Home Screen
1. Install **Termux:Widget** from [F-Droid](https://f-droid.org/packages/com.termux.widget/)
2. Long-press home screen → Widgets → Termux:Widget
3. Add and tap **"MediaLoad"** shortcut

---

## 📂 App Structure

```
mediaload-termux/
│
├── 📜 install.sh           ← One-command installer (START HERE)
├── 📱 mediaload.sh         ← Main application with beautiful TUI
├── 🔗 create_shortcut.sh   ← Android home screen shortcut creator
├── 🗑️  uninstall.sh         ← Clean uninstaller
├── 📖 README.md            ← This file
│
└── After installation creates:
    ~/.mediaload/
    ├── config/
    │   └── settings.conf   ← User configuration
    ├── downloads/
    │   ├── videos/         ← Downloaded videos
    │   ├── audio/          ← Downloaded audio
    │   ├── images/         ← Downloaded images
    │   └── playlists/      ← Playlist downloads
    └── logs/
        └── download.log    ← Download history

~/.shortcuts/               ← Termux:Widget shortcut location
├── MediaLoad.sh            ← Main app shortcut
└── MediaLoad-QuickDL.sh    ← Clipboard URL quick download
```

---

## ⚙️ Configuration

After installation, edit `~/.mediaload/config/settings.conf`:

```bash
# Download directory
DOWNLOAD_DIR="$HOME/.mediaload/downloads"

# Default video quality (best/1080p/720p/480p/360p/worst)
DEFAULT_VIDEO_QUALITY="best"

# Default formats
DEFAULT_VIDEO_FORMAT="mp4"
DEFAULT_AUDIO_FORMAT="mp3"

# Use aria2c for faster multi-connection downloads
USE_ARIA2=true

# Max concurrent downloads
MAX_CONCURRENT=3

# UI theme color (cyan/green/magenta/yellow/blue)
THEME_COLOR="cyan"

# Send Android notification when download completes
NOTIFY_ON_DONE=true
```

---

## 🔧 Requirements

| Component | Version | Purpose |
|---|---|---|
| Termux | Latest | Android terminal environment |
| Python | 3.x | yt-dlp runtime |
| yt-dlp | Latest | Download engine |
| FFmpeg | Any | Video/audio processing & merging |
| aria2 | Any | Fast parallel downloading (optional) |
| Termux:Widget | Any | Android home screen shortcut |
| termux-api | Any | Notifications & clipboard (optional) |

---

## 📚 Learning Concepts Covered

This project demonstrates these programming concepts — perfect for a college presentation:

| Concept | Implementation |
|---|---|
| **Variables & Arrays** | Config, package lists, argument arrays |
| **Functions** | Modular UI helpers, download engine, menus |
| **Control Flow** | `if/else`, `case`, `while` loops, `for` loops |
| **Error Handling** | Exit codes, fallback methods, user feedback |
| **File I/O** | Reading/writing config, logging, creating scripts |
| **Pipes & Redirection** | `\|`, `>`, `>>`, `2>/dev/null` |
| **String Processing** | Pattern matching, `sed`, `grep`, `awk`, `cut` |
| **External Commands** | `pkg`, `pip`, `yt-dlp`, `ffmpeg`, `curl` |
| **User Input** | `read`, menu-driven navigation |
| **Signal Handling** | Exit traps, background processes |
| **ANSI Escape Codes** | Colors, bold, cursor control |
| **Command Substitution** | `$(...)` for dynamic values |
| **Text Processing** | `python -c` for JSON parsing |
| **Process Management** | Background jobs, `pid`, spinner |
| **Conditional Expressions** | `[[ ]]`, regex matching, file tests |

---

## 🛠️ Manual Commands (Without Installer)

```bash
# Install dependencies manually
pkg install python ffmpeg curl git aria2 dialog -y
pip install yt-dlp

# Run directly
bash mediaload.sh

# Update yt-dlp
pip install -U yt-dlp
# or
yt-dlp -U

# Download example
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 URL
```

---

## 🔄 Updating

```bash
# In-app update (Settings → Update yt-dlp)
mediaload
# Then press 9 → 9

# Manual update from terminal
cd mobile-media && git pull && bash install.sh
```

---

## 🗑️ Uninstall

```bash
bash uninstall.sh
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---|---|
| `yt-dlp: command not found` | Run `pip install yt-dlp` |
| `ffmpeg: command not found` | Run `pkg install ffmpeg` |
| Download fails | Run `pip install -U yt-dlp` to update |
| Storage permission denied | Run `termux-setup-storage` |
| Geo-restricted content | Use a VPN or `--proxy` option |
| Age-restricted YouTube | Export cookies with a browser extension |
| Shortcut not showing | Reinstall Termux:Widget from F-Droid |
| Script not executable | Run `chmod +x *.sh` |
| `fatal: destination path already exists` | Run `rm -rf mobile-media` then clone again |

---

## 📎 Resources

- [yt-dlp GitHub](https://github.com/yt-dlp/yt-dlp) — The download engine powering this app
- [yt-dlp Supported Sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md) — Full platform list
- [Termux Official](https://termux.dev) — Android terminal emulator
- [F-Droid](https://f-droid.org) — Download Termux and Termux:Widget
- [Termux Wiki](https://wiki.termux.com) — Termux documentation

---

## 📄 License

```
MIT License

Copyright (c) 2026 kapilpatel89

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

See [LICENSE](LICENSE) for full text.

---

<div align="center">

**Made with ❤️ as a College Learning Project**

*Bash Scripting | Android (Termux) | Open Source*

⭐ **If this helped you, please star the repository!** ⭐

</div>
