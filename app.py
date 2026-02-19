from flask import Flask, render_template, request, jsonify, send_from_directory
import yt_dlp
import os
import threading
import json
import subprocess
import time

app = Flask(__name__)

# Constants (matching bash config where possible)
INSTALL_DIR = os.path.expanduser("~/.mediaload")
DOWNLOAD_DIR = os.path.join(INSTALL_DIR, "downloads")
CONFIG_FILE = os.path.join(INSTALL_DIR, "config/settings.conf")

# In-memory storage for active downloads
active_downloads = {}

def get_config():
    config = {
        "DOWNLOAD_DIR": DOWNLOAD_DIR,
        "DEFAULT_VIDEO_QUALITY": "best",
        "DEFAULT_VIDEO_FORMAT": "mp4",
        "DEFAULT_AUDIO_FORMAT": "mp3",
        "THEME_COLOR": "cyan"
    }
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            for line in f:
                if "=" in line and not line.startswith("#"):
                    key, value = line.strip().split("=", 1)
                    config[key] = value.strip('"').strip("'").replace("$HOME", os.path.expanduser("~"))
    return config

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/info', methods=['POST'])
def get_info():
    url = request.json.get('url')
    if not url:
        return jsonify({"error": "No URL provided"}), 400
    
    try:
        ydl_opts = {'quiet': True, 'no_warnings': True}
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            # Simplify info for frontend
            simplified_info = {
                "title": info.get('title'),
                "thumbnail": info.get('thumbnail'),
                "uploader": info.get('uploader'),
                "duration": info.get('duration'),
                "duration_string": time.strftime('%H:%M:%S', time.gmtime(info.get('duration', 0))),
                "views": info.get('view_count'),
                "description": info.get('description', '')[:200] + "...",
                "formats": [],
                "url": url
            }
            
            # Extract useful formats (mp4/mkv/mp3)
            seen_heights = set()
            for f in info.get('formats', []):
                if f.get('vcodec') != 'none' and f.get('height'):
                    h = f.get('height')
                    if h not in seen_heights:
                        simplified_info['formats'].append({
                            "id": f.get('format_id'),
                            "ext": f.get('ext'),
                            "height": h,
                            "note": f.get('format_note', f"{h}p")
                        })
                        seen_heights.add(h)
            
            simplified_info['formats'].sort(key=lambda x: x['height'], reverse=True)
            return jsonify(simplified_info)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

class DownloadLogger:
    def __init__(self, download_id):
        self.download_id = download_id
    
    def debug(self, msg):
        pass
    def warning(self, msg):
        pass
    def error(self, msg):
        pass

def progress_hook(d):
    download_id = d.get('info_dict', {}).get('web_download_id')
    if download_id and d['status'] == 'downloading':
        p = d.get('_percent_str', '0%').strip().replace('%', '')
        active_downloads[download_id]['progress'] = p
        active_downloads[download_id]['speed'] = d.get('_speed_str', 'N/A')
        active_downloads[download_id]['eta'] = d.get('_eta_str', 'N/A')
    elif download_id and d['status'] == 'finished':
        active_downloads[download_id]['progress'] = '100'
        active_downloads[download_id]['status'] = 'finished'

def run_download_task(download_id, url, opts):
    try:
        active_downloads[download_id]['status'] = 'downloading'
        with yt_dlp.YoutubeDL(opts) as ydl:
            ydl.download([url])
        active_downloads[download_id]['status'] = 'completed'
    except Exception as e:
        active_downloads[download_id]['status'] = 'failed'
        active_downloads[download_id]['error'] = str(e)

@app.route('/api/download', methods=['POST'])
def download():
    data = request.json
    url = data.get('url')
    format_type = data.get('type', 'video') # video or audio
    quality = data.get('quality', 'best')
    
    download_id = str(int(time.time()))
    active_downloads[download_id] = {
        "status": "starting",
        "progress": "0",
        "title": data.get('title', 'Unknown'),
        "url": url
    }
    
    config = get_config()
    out_dir = os.path.join(config['DOWNLOAD_DIR'], format_type + "s")
    os.makedirs(out_dir, exist_ok=True)
    
    ydl_opts = {
        'progress_hooks': [progress_hook],
        'logger': DownloadLogger(download_id),
        'outtmpl': f'{out_dir}/%(uploader)s/%(title)s.%(ext)s',
    }
    
    if format_type == 'audio':
        ydl_opts.update({
            'format': 'bestaudio/best',
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': data.get('format', 'mp3'),
                'preferredquality': '192',
            }, {'key': 'EmbedThumbnail'}, {'key': 'FFmpegMetadata'}],
        })
    else:
        # Video
        fmt = f"bestvideo[height<={quality}]+bestaudio/best[height<={quality}]" if quality.isdigit() else "bestvideo+bestaudio/best"
        ydl_opts.update({
            'format': fmt,
            'merge_output_format': data.get('format', 'mp4'),
        })

    # Add id to info_dict via a custom extractor-like injection or just use global
    # Actually progress_hook can access info_dict. Let's wrap.
    def hook_wrapper(d):
        d['info_dict']['web_download_id'] = download_id
        progress_hook(d)
    
    ydl_opts['progress_hooks'] = [hook_wrapper]

    thread = threading.Thread(target=run_download_task, args=(download_id, url, ydl_opts))
    thread.start()
    
    return jsonify({"download_id": download_id})

@app.route('/api/status/<download_id>')
def status(download_id):
    return jsonify(active_downloads.get(download_id, {"status": "not_found"}))

@app.route('/api/files')
def list_files():
    files = []
    for root, dirs, filenames in os.walk(DOWNLOAD_DIR):
        for name in filenames:
            if not name.startswith('.'):
                full_path = os.path.join(root, name)
                rel_path = os.path.normpath(os.path.relpath(full_path, DOWNLOAD_DIR)).replace('\\', '/')
                files.append({
                    "name": name,
                    "path": rel_path,
                    "size": f"{os.path.getsize(full_path) / (1024*1024):.2f} MB",
                    "time": os.path.getmtime(full_path)
                })
    files.sort(key=lambda x: x['time'], reverse=True)
    return jsonify(files[:50])

@app.route('/api/serve/<path:filename>')
def serve_file(filename):
    return send_from_directory(DOWNLOAD_DIR, filename)

if __name__ == '__main__':
    # Get local IP for convenience
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    
    print(f"🔥 MediaLoad Web UI running at: http://localhost:5000")
    print(f"📱 Access from other devices: http://{IP}:5000")
    app.run(host='0.0.0.0', port=5000, debug=False)
