document.addEventListener('DOMContentLoaded', () => {
    const urlInput = document.getElementById('url-input');
    const analyzeBtn = document.getElementById('analyze-btn');
    const resultCard = document.getElementById('result-card');
    const playlistCard = document.getElementById('playlist-card');
    const skeleton = document.getElementById('results-skeleton');
    const downloadBtn = document.getElementById('download-btn');
    const filesGrid = document.getElementById('files-grid');
    const downloadsContainer = document.getElementById('downloads-container');
    const activeDownloadsSection = document.getElementById('active-downloads');

    // Player Elements
    const musicPlayer = document.getElementById('music-player');
    const audioElement = document.getElementById('audio-element');
    const playPauseBtn = document.getElementById('play-pause-btn');
    const seekFill = document.getElementById('seek-fill');
    const seekBar = document.querySelector('.seek-bar');
    const currTimeText = document.getElementById('curr-time');
    const totalTimeText = document.getElementById('total-time');
    const volumeSlider = document.getElementById('volume-slider');
    const playerTitle = document.getElementById('player-title');
    const playerMeta = document.getElementById('player-meta');
    const loopBtn = document.getElementById('loop-btn');
    const shuffleBtn = document.getElementById('shuffle-btn');

    // Video Modal Elements
    const videoModal = document.getElementById('video-modal');
    const mainVideo = document.getElementById('main-video');
    const closeVideoBtn = document.getElementById('close-video');
    const modalVideoTitle = document.getElementById('modal-video-title');
    const shareBtn = document.getElementById('share-file');

    let currentVideoData = null;
    let playlist = [];
    let currentTrackIndex = -1;
    let isLooping = false;
    let isShuffling = false;
    let currentSharedFile = null;

    const offlineGateway = document.getElementById('offline-gateway');
    const wakeServerBtn = document.getElementById('wake-server');

    // --- Connectivity Check ---

    async function checkServerConnection() {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 2000);

            const response = await fetch('/api/files', { signal: controller.signal });
            clearTimeout(timeoutId);

            if (response.ok) {
                offlineGateway.classList.add('hidden');
                return true;
            }
        } catch (err) {
            console.log("Server unreachable, showing gateway...");
            offlineGateway.classList.remove('hidden');
            return false;
        }
    }

    wakeServerBtn.onclick = () => {
        showToast('Starting Termux...', 'info');
        // Android Intent for Termux to start the server
        window.location.href = 'intent://#Intent;component=com.termux/com.termux.app.TermuxActivity;end';

        // Wait a bit and try to reconnect
        setTimeout(() => {
            setInterval(async () => {
                if (await checkServerConnection()) {
                    location.reload();
                }
            }, 3000);
        }, 5000);
    };

    // --- PWA & Notification Logic ---

    function checkPWA() {
        const isStandalone = window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone;
        const bannerDismissed = localStorage.getItem('pwa-dismissed');
        const installBanner = document.getElementById('install-banner');

        if (!isStandalone && !bannerDismissed && installBanner) {
            installBanner.classList.remove('hidden');
        }
    }

    if ("Notification" in window) {
        Notification.requestPermission();
    }

    // --- API Calls ---

    async function analyzeUrl() {
        const url = urlInput.value.trim();
        if (!url) return showToast('Please paste a URL', 'error');

        resultCard.classList.add('hidden');
        playlistCard.classList.add('hidden');
        skeleton.classList.remove('hidden');
        analyzeBtn.disabled = true;
        analyzeBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Analyzing...';

        try {
            const response = await fetch('/api/info', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ url })
            });
            const data = await response.json();
            if (data.error) throw new Error(data.error);

            if (data.is_playlist) {
                displayPlaylist(data);
            } else {
                displayResult(data);
            }
        } catch (err) {
            showToast(err.message, 'error');
        } finally {
            skeleton.classList.add('hidden');
            analyzeBtn.disabled = false;
            analyzeBtn.innerHTML = '<i class="fas fa-search"></i> Analyze';
        }
    }

    async function startDownload(urlOverride = null, titleOverride = null) {
        const url = urlOverride || currentVideoData.url;
        const title = titleOverride || currentVideoData.title;
        const format = document.getElementById('format-select').value;
        const quality = document.getElementById('quality-select').value;
        const type = (format === 'mp3' || format === 'm4a') ? 'audio' : 'video';

        try {
            const response = await fetch('/api/download', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    url: url,
                    title: title,
                    type: type,
                    format: format,
                    quality: quality
                })
            });
            const data = await response.json();
            showToast('Download started!', 'success');
            trackDownload(data.download_id, title);
            activeDownloadsSection.classList.remove('hidden');
        } catch (err) {
            showToast('Failed to start download', 'error');
        }
    }

    async function fetchFiles() {
        try {
            const response = await fetch('/api/files');
            const files = await response.json();
            playlist = files;
            renderFiles(files);
        } catch (err) {
            console.error('Failed to fetch files');
        }
    }

    async function deleteFile(file, cardElement) {
        if (!confirm(`Permanently delete "${file.name}"?`)) return;

        cardElement.classList.add('deleting');
        try {
            const response = await fetch('/api/delete', {
                method: 'DELETE',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path: file.path })
            });
            const data = await response.json();
            if (data.error) throw new Error(data.error);
            showToast('File deleted', 'success');
            fetchFiles();
        } catch (err) {
            showToast('Delete failed', 'error');
            cardElement.classList.remove('deleting');
        }
    }

    // --- UI Rendering ---

    function displayResult(data) {
        currentVideoData = data;
        document.getElementById('video-thumb').src = data.thumbnail;
        document.getElementById('video-title').textContent = data.title;
        document.getElementById('video-uploader').innerHTML = `<i class="fas fa-user"></i> ${data.uploader}`;
        document.getElementById('video-duration').textContent = data.duration_string;

        const qSelect = document.getElementById('quality-select');
        qSelect.innerHTML = '<option value="best">Best Available</option>';
        data.formats.forEach(f => {
            if (f.height) {
                const opt = document.createElement('option');
                opt.value = f.height;
                opt.textContent = `${f.height}p - ${f.note}`;
                qSelect.appendChild(opt);
            }
        });

        resultCard.classList.remove('hidden');
        resultCard.scrollIntoView({ behavior: 'smooth' });
    }

    function displayPlaylist(data) {
        document.getElementById('playlist-title').textContent = data.title;
        document.getElementById('playlist-meta').innerHTML = `<i class="fas fa-list"></i> ${data.count} Videos`;

        const container = document.getElementById('playlist-entries');
        container.innerHTML = '';

        data.entries.forEach(entry => {
            const item = document.createElement('div');
            item.className = 'playlist-item';
            item.innerHTML = `
                <div class="playlist-item-info">
                    <i class="fas fa-play-circle text-dim"></i>
                    <span class="playlist-item-title">${entry.title}</span>
                </div>
                <div class="playlist-actions">
                    <button class="mini-btn play-now" title="Play without download"><i class="fas fa-play"></i></button>
                    <button class="mini-btn dl-now" title="Download"><i class="fas fa-download"></i></button>
                </div>
            `;

            item.querySelector('.play-now').onclick = () => {
                // For YouTube, use embed; otherwise try direct play
                const videoId = entry.id || entry.url.split('v=')[1];
                if (videoId) {
                    showToast('Opening Preview...', 'info');
                    // Simple logic: we'll use a YouTube embed for "play without download"
                    openVideoModal(`https://www.youtube.com/embed/${videoId}?autoplay=1`, entry.title, true);
                } else {
                    showToast('Streaming not supported for this source', 'error');
                }
            };

            item.querySelector('.dl-now').onclick = () => {
                startDownload(entry.url, entry.title);
            };

            container.appendChild(item);
        });

        playlistCard.classList.remove('hidden');
        playlistCard.scrollIntoView({ behavior: 'smooth' });
    }

    function trackDownload(id, title) {
        const div = document.createElement('div');
        div.className = 'download-item';
        div.id = `dl-${id}`;
        div.innerHTML = `
            <div class="dl-info">
                <span class="dl-title">${title}</span>
                <span class="dl-percentage">0%</span>
            </div>
            <div class="progress-bar-container">
                <div class="progress-fill" style="width: 0%"></div>
            </div>
            <div class="dl-meta" style="font-size: 10px; color: #94a3b8; margin-top: 5px;">
                <span class="dl-speed">Speed: --</span> | <span class="dl-eta">ETA: --</span>
            </div>
        `;
        downloadsContainer.prepend(div);

        const checkStatus = setInterval(async () => {
            try {
                const res = await fetch(`/api/status/${id}`);
                const status = await res.json();

                if (status.status === 'completed' || status.status === 'failed') {
                    clearInterval(checkStatus);
                    if (status.status === 'completed') {
                        div.querySelector('.dl-percentage').textContent = 'Completed!';
                        div.querySelector('.progress-fill').style.width = '100%';
                        showNotification('Download Complete', status.title);
                        showToast(`Finished: ${status.title}`, 'success');
                        setTimeout(() => div.remove(), 5000);
                        fetchFiles();
                    }
                    return;
                }

                const p = parseFloat(status.progress) || 0;
                div.querySelector('.progress-fill').style.width = `${p}%`;
                div.querySelector('.dl-percentage').textContent = `${p}%`;
                div.querySelector('.dl-speed').textContent = `Speed: ${status.speed || 'N/A'}`;
                div.querySelector('.dl-eta').textContent = `ETA: ${status.eta || 'N/A'}`;
            } catch (err) {
                clearInterval(checkStatus);
            }
        }, 1000);
    }

    function renderFiles(files) {
        filesGrid.innerHTML = '';
        if (files.length === 0) {
            filesGrid.innerHTML = '<p class="text-dim">No downloads yet.</p>';
            return;
        }

        files.forEach((file, index) => {
            const card = document.createElement('div');
            card.className = 'file-card';
            const isAudio = file.name.endsWith('.mp3') || file.name.endsWith('.m4a');
            const icon = isAudio ? 'fa-music' : 'fa-video';

            card.innerHTML = `
                <div class="file-icon"><i class="fas ${icon}"></i></div>
                <div class="file-name" title="${file.name}">${file.name}</div>
                <div class="file-meta">${file.size}</div>
                <div class="play-overlay">
                    <div class="play-circle"><i class="fas fa-play"></i></div>
                </div>
            `;

            // Interaction: Tap to play
            card.onclick = () => {
                if (isAudio) playTrack(index);
                else openVideoModal(`/api/serve/${file.path}`, file.name);
            };

            // Interaction: Long press to delete
            let timer;
            const start = () => {
                timer = setTimeout(() => deleteFile(file, card), 800);
            };
            const cancel = () => clearTimeout(timer);

            card.addEventListener('mousedown', start);
            card.addEventListener('touchstart', start);
            card.addEventListener('mouseup', cancel);
            card.addEventListener('mouseleave', cancel);
            card.addEventListener('touchend', cancel);

            filesGrid.appendChild(card);
        });
    }

    // --- Media Player & Modal Logic ---

    function playTrack(index) {
        if (index < 0) index = playlist.length - 1;
        if (index >= playlist.length) index = 0;

        currentTrackIndex = index;
        const track = playlist[index];

        audioElement.src = `/api/serve/${track.path}`;
        playerTitle.textContent = track.name;
        playerMeta.textContent = track.size;

        musicPlayer.classList.remove('hidden');
        audioElement.play();
        playPauseBtn.innerHTML = '<i class="fas fa-pause"></i>';
    }

    function openVideoModal(source, title, isEmbed = false) {
        modalVideoTitle.textContent = title;
        currentSharedFile = { source, title, isEmbed };

        const container = videoModal.querySelector('.video-container');
        container.innerHTML = '';

        if (isEmbed) {
            const iframe = document.createElement('iframe');
            iframe.src = source;
            iframe.className = 'main-video';
            iframe.setAttribute('allowfullscreen', 'true');
            iframe.setAttribute('frameborder', '0');
            container.appendChild(iframe);
            shareBtn.classList.add('hidden'); // Can't easily share embed URLs as files
        } else {
            const video = document.createElement('video');
            video.src = source;
            video.controls = true;
            video.className = 'main-video';
            video.autoplay = true;
            container.appendChild(video);
            shareBtn.classList.remove('hidden');

            // Try full screen on play
            video.onplay = () => {
                if (video.requestFullscreen) video.requestFullscreen();
            }
        }

        videoModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    closeVideoBtn.onclick = () => {
        const container = videoModal.querySelector('.video-container');
        container.innerHTML = ''; // Stop video playback
        videoModal.classList.add('hidden');
        document.body.style.overflow = 'auto';
    };

    shareBtn.onclick = async () => {
        if (!currentSharedFile || currentSharedFile.isEmbed) return;

        try {
            const response = await fetch(currentSharedFile.source);
            const blob = await response.blob();
            const file = new File([blob], currentSharedFile.title, { type: blob.type });

            if (navigator.share) {
                await navigator.share({
                    files: [file],
                    title: currentSharedFile.title,
                    text: 'Shared from MediaLoad'
                });
            } else {
                showToast('Share not supported on this browser', 'error');
            }
        } catch (err) {
            showToast('Sharing failed', 'error');
        }
    };

    // --- Control Handlers ---

    playPauseBtn.onclick = () => {
        if (audioElement.paused) {
            audioElement.play();
            playPauseBtn.innerHTML = '<i class="fas fa-pause"></i>';
        } else {
            audioElement.pause();
            playPauseBtn.innerHTML = '<i class="fas fa-play"></i>';
        }
    };

    seekBar.onclick = (e) => {
        const rect = seekBar.getBoundingClientRect();
        const p = (e.clientX - rect.left) / rect.width;
        audioElement.currentTime = p * audioElement.duration;
    };

    audioElement.ontimeupdate = () => {
        const p = (audioElement.currentTime / audioElement.duration) * 100;
        seekFill.style.width = `${p || 0}%`;
        currTimeText.textContent = formatTime(audioElement.currentTime);
        totalTimeText.textContent = formatTime(audioElement.duration);
    };

    audioElement.onended = () => {
        if (isLooping) {
            audioElement.currentTime = 0;
            audioElement.play();
        } else if (isShuffling) {
            const nextIndex = Math.floor(Math.random() * playlist.length);
            playTrack(nextIndex);
        } else {
            playTrack(currentTrackIndex + 1);
        }
    };

    loopBtn.onclick = () => {
        isLooping = !isLooping;
        loopBtn.classList.toggle('active', isLooping);
        showToast(isLooping ? 'Loop Enabled' : 'Loop Disabled');
    };

    shuffleBtn.onclick = () => {
        isShuffling = !isShuffling;
        shuffleBtn.classList.toggle('active', isShuffling);
        showToast(isShuffling ? 'Shuffle Enabled' : 'Shuffle Disabled');
    };

    function formatTime(seconds) {
        if (isNaN(seconds)) return '0:00';
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return `${m}:${s < 10 ? '0' : ''}${s}`;
    }

    volumeSlider.oninput = () => {
        audioElement.volume = volumeSlider.value;
    };

    document.getElementById('next-btn').onclick = () => {
        if (isShuffling) playTrack(Math.floor(Math.random() * playlist.length));
        else playTrack(currentTrackIndex + 1);
    };

    document.getElementById('prev-btn').onclick = () => {
        if (isShuffling) playTrack(Math.floor(Math.random() * playlist.length));
        else playTrack(currentTrackIndex - 1);
    };

    document.getElementById('close-player').onclick = () => {
        audioElement.pause();
        musicPlayer.classList.add('hidden');
    };

    // --- Helper Functions ---

    function showNotification(title, body) {
        if ("Notification" in window && Notification.permission === "granted") {
            new Notification(title, { body, icon: '/static/img/logo.svg' });
        }
    }

    function showToast(message, type = 'info') {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.textContent = message;
        container.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
    }

    // --- Init ---

    analyzeBtn.addEventListener('click', analyzeUrl);
    urlInput.addEventListener('keypress', (e) => { if (e.key === 'Enter') analyzeUrl(); });
    downloadBtn.addEventListener('click', () => startDownload());
    document.getElementById('refresh-files').addEventListener('click', fetchFiles);

    // PWA Close Banner Handler
    const closeBanner = document.getElementById('close-banner');
    if (closeBanner) {
        closeBanner.onclick = () => {
            document.getElementById('install-banner').classList.add('hidden');
            localStorage.setItem('pwa-dismissed', 'true');
        };
    }

    checkPWA();
    fetchFiles();
});
