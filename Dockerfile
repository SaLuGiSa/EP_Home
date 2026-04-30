# EasyProxy - HuggingFace compatible (no Cloudflare WARP)
FROM python:3.12-slim-bookworm

WORKDIR /app
ENV PYTHONUNBUFFERED=1
ENV FLARESOLVERR_URL=http://localhost:8191

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    gnupg \
    gpg \
    netcat-openbsd \
    ffmpeg \
    chromium \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    libxshmfence1 \
    libglu1-mesa \
    ca-certificates \
    fonts-liberation \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONPATH=/app
ENV CHROME_EXE_PATH=/usr/bin/chromium
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROME_DRIVER_PATH=/usr/bin/chromedriver

RUN git clone https://github.com/FlareSolverr/FlareSolverr.git /app/flaresolverr \
    && cd /app/flaresolverr \
    && sed -i 's/driver_executable_path=driver_exe_path/driver_executable_path="\/usr\/bin\/chromedriver"/' src/utils.py \
    && sed -i "s|options.add_argument('--no-sandbox')|options.add_argument('--no-sandbox'); options.add_argument('--disable-dev-shm-usage'); options.add_argument('--disable-gpu'); options.add_argument('--headless=new')|" src/utils.py \
    && sed -i "s|^\([[:space:]]*\)start_xvfb_display()|\1pass|g" src/utils.py \
    && pip install --no-cache-dir -r requirements.txt

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN sed -i 's/async def _update_warp_status_loop(self):/async def _update_warp_status_loop(self):\n        if not ENABLE_WARP:\n            self.warp_status = "Disabled"\n            return/' /app/services/hls_proxy.py \
    && sed -i '/await self\._refresh_latest_version()/d' /app/services/hls_proxy.py

RUN chmod +x entrypoint.sh

ENV PORT=7860
ENV ENABLE_WARP=false
ENV WORKERS=1
ENV LOG_LEVEL=ERROR

EXPOSE 7860 8191
ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
