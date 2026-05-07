FROM alpine/openclaw

USER root
# Upgrade OpenClaw to latest stable release (skips beta/rc tags)
RUN LATEST=$(npm view openclaw dist-tags.latest) && \
    npm pack "openclaw@${LATEST}" -q && \
    tar -xzf openclaw-*.tgz && \
    cp -rf package/* /app/ && \
    rm -rf package openclaw-*.tgz && \
    cd /app && rm -rf package-lock.json node_modules && npm install --omit=dev

# Strip the `paperclip` envelope key from gateway RPC params before AJV
# validation. Workaround for an upstream schema bug — Paperclip cloud
# adapter wraps each RPC with a `paperclip` envelope that AJV rejects
# because the agent/chat.send schemas use `additionalProperties: false`.
# Remove this RUN step once the upstream fix lands.
COPY patches/paperclip-envelope-strip.sh /tmp/patches/paperclip-envelope-strip.sh
RUN chmod +x /tmp/patches/paperclip-envelope-strip.sh \
    && /tmp/patches/paperclip-envelope-strip.sh \
    && rm -rf /tmp/patches

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl \
       chromium \
       fonts-liberation \
       libasound2 \
       libatk-bridge2.0-0 \
       libatk1.0-0 \
       libatspi2.0-0 \
       libcups2 \
       libdbus-1-3 \
       libdrm2 \
       libgbm1 \
       libgtk-3-0 \
       libnspr4 \
       libnss3 \
       libwayland-client0 \
       libxcomposite1 \
       libxdamage1 \
       libxfixes3 \
       libxkbcommon0 \
       libxrandr2 \
       xdg-utils \
       # Python & audio/image processing
       python3 \
       python3-pip \
       python3-venv \
       ffmpeg \
       tesseract-ocr \
       tesseract-ocr-nld \
       libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Optional: Developer tools for the developer agent persona
# Build with: docker compose build --build-arg INSTALL_DEV_TOOLS=true
ARG INSTALL_DEV_TOOLS=false
RUN if [ "$INSTALL_DEV_TOOLS" = "true" ]; then \
      apt-get update && apt-get install -y --no-install-recommends \
        git \
        openssh-client \
      && rm -rf /var/lib/apt/lists/* \
      && npm install -g @anthropic-ai/claude-code; \
    fi

# Python packages for AI media processing (TTS, STT, image recognition)
RUN python3 -m venv /opt/ai-tools && \
    /opt/ai-tools/bin/pip install --no-cache-dir \
       openai \
       faster-whisper \
       edge-tts \
       pydub \
       soundfile \
       Pillow \
       pytesseract \
    && chmod -R a+rX /opt/ai-tools

ENV PATH="/opt/ai-tools/bin:${PATH}"

# Audio processing scripts (STT via faster-whisper, TTS via edge-tts)
COPY scripts/stt.py scripts/tts.py /opt/ai-tools/bin/
RUN chmod +x /opt/ai-tools/bin/stt.py /opt/ai-tools/bin/tts.py

# Pre-download Whisper base model so first transcription is instant
RUN /opt/ai-tools/bin/python -c "\
from faster_whisper import WhisperModel; \
WhisperModel('base', device='cpu', compute_type='int8', download_root='/opt/ai-tools/whisper-models')" \
    && chmod -R a+rX /opt/ai-tools/whisper-models
ENV WHISPER_CACHE_DIR=/opt/ai-tools/whisper-models

# Wrapper that always starts Chromium with --no-sandbox (required in Docker)
RUN printf '#!/bin/sh\nexec /usr/bin/chromium --no-sandbox --disable-gpu --disable-dev-shm-usage "$@"\n' \
    > /usr/local/bin/chromium-docker \
    && chmod +x /usr/local/bin/chromium-docker

# Fix execute permissions on skill scripts
RUN find /app/skills -type f -name "*.sh" -exec chmod +x {} \;

ENV CHROME_BIN=/usr/local/bin/chromium-docker
USER node
