document.addEventListener('DOMContentLoaded', () => {
    const urlInput = document.getElementById('url-input');
    const analyzeBtn = document.getElementById('analyze-btn');
    const resultCard = document.getElementById('result-card');
    const skeleton = document.getElementById('results-skeleton');
    const downloadBtn = document.getElementById('download-btn');
    const filesGrid = document.getElementById('files-grid');
    const downloadsContainer = document.getElementById('downloads-container');
    const activeDownloadsSection = document.getElementById('active-downloads');

    let currentVideoData = null;

    // --- API Calls ---

    async function analyzeUrl() {
        const url = urlInput.value.trim();
        if (!url) return showToast('Please paste a URL', 'error');

        // Reset UI
        resultCard.classList.add('hidden');
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

            displayResult(data);
        } catch (err) {
            showToast(err.message, 'error');
            console.error(err);
        } finally {
            skeleton.classList.add('hidden');
            analyzeBtn.disabled = false;
            analyzeBtn.innerHTML = '<i class="fas fa-search"></i> Analyze';
        }
    }

    async function startDownload() {
        if (!currentVideoData) return;

        const format = document.getElementById('format-select').value;
        const quality = document.getElementById('quality-select').value;
        const type = (format === 'mp3' || format === 'm4a') ? 'audio' : 'video';

        try {
            const response = await fetch('/api/download', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    url: currentVideoData.url,
                    title: currentVideoData.title,
                    type: type,
                    format: format,
                    quality: quality
                })
            });
            const data = await response.json();

            showToast('Download started!', 'success');
            trackDownload(data.download_id);
            activeDownloadsSection.classList.remove('hidden');
        } catch (err) {
            showToast('Failed to start download', 'error');
        }
    }

    async function fetchFiles() {
        try {
            const response = await fetch('/api/files');
            const files = await response.json();
            renderFiles(files);
        } catch (err) {
            console.error('Failed to fetch files');
        }
    }

    // --- UI Rendering ---

    function displayResult(data) {
        currentVideoData = data;
        document.getElementById('video-thumb').src = data.thumbnail;
        document.getElementById('video-title').textContent = data.title;
        document.getElementById('video-uploader').innerHTML = `<i class="fas fa-user"></i> ${data.uploader}`;
        document.getElementById('video-duration').textContent = data.duration_string;

        // Update quality options based on available formats
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

    function trackDownload(id) {
        const div = document.createElement('div');
        div.className = 'download-item';
        div.id = `dl-${id}`;
        div.innerHTML = `
            <div class="dl-info">
                <span class="dl-title">${currentVideoData.title}</span>
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

                if (status.status === 'not_found' || status.status === 'completed' || status.status === 'failed') {
                    clearInterval(checkStatus);
                    if (status.status === 'completed') {
                        div.querySelector('.dl-percentage').textContent = 'Completed!';
                        div.querySelector('.progress-fill').style.width = '100%';
                        div.querySelector('.progress-fill').style.background = 'linear-gradient(90deg, #00f2fe, #4facfe)';
                        showToast(`Finished: ${status.title}`, 'success');
                        setTimeout(() => div.remove(), 5000);
                        fetchFiles();
                    } else if (status.status === 'failed') {
                        div.querySelector('.dl-percentage').textContent = 'Failed';
                        div.querySelector('.dl-percentage').style.color = '#ef4444';
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

        files.forEach(file => {
            const card = document.createElement('div');
            card.className = 'file-card';
            const isAudio = file.name.endsWith('.mp3') || file.name.endsWith('.m4a');
            const icon = isAudio ? 'fa-music' : 'fa-video';

            card.innerHTML = `
                <div class="file-icon"><i class="fas ${icon}"></i></div>
                <div class="file-name" title="${file.name}">${file.name}</div>
                <div class="file-meta">${file.size}</div>
            `;
            filesGrid.appendChild(card);
        });
    }

    function showToast(message, type = 'info') {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.textContent = message;
        container.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
    }

    // --- Event Listeners ---

    analyzeBtn.addEventListener('click', analyzeUrl);
    urlInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') analyzeUrl();
    });

    downloadBtn.addEventListener('click', startDownload);

    document.getElementById('refresh-files').addEventListener('click', fetchFiles);

    // Initial load
    fetchFiles();
});
