FROM alpine/openclaw

USER root

# Patched Node.js (base image alpine/openclaw is stale; Node security release 2026-10-21)
COPY --from=node:24.22.1-bookworm-slim /usr/local/bin/node /usr/local/bin/node

# Upgrade OpenClaw in-place (overwrite base image version)
# RUN npm pack openclaw@2026.7.1-2 -q && \
RUN npm pack openclaw@2026.10.5 -q && \
    tar -xzf openclaw-*.tgz --no-same-permissions --no-same-owner && \
    cp -rf package/* /app/ && \
    rm -rf package openclaw-*.tgz && \
    cd /app && \
    rm -rf package-lock.json node_modules && \
    npm pkg delete devDependencies && \
    npm install --omit=dev --legacy-peer-deps

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl \
       git \
       openssh-client \
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
       python3-httpx \
       python3-rich \
       python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir --break-system-packages edge-tts

# Wrapper that always starts Chromium with --no-sandbox (required in Docker)
RUN printf '#!/bin/sh\nexec /usr/bin/chromium --no-sandbox --disable-gpu --disable-dev-shm-usage "$@"\n' \
    > /usr/local/bin/chromium-docker \
    && chmod +x /usr/local/bin/chromium-docker

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# AI CLI tools: Claude Code CLI (Anthropic) + Gemini CLI (Google)
RUN npm install -g @anthropic-ai/claude-code @google/gemini-cli

# Git config for Willy bot account
RUN git config --system user.name "Willy" \
    && git config --system user.email "noreply@madebyadem.dev"

# Global pre-push hook: block pushes to main/master
RUN mkdir -p /etc/git/hooks \
    && printf '#!/bin/sh\nwhile read local_ref local_sha remote_ref remote_sha; do\n  case "$remote_ref" in\n    refs/heads/main|refs/heads/master)\n      echo "BLOCKED: Willy mag niet pushen naar $remote_ref. Maak een feature branch." >&2\n      exit 1\n      ;;\n  esac\ndone\n' \
    > /etc/git/hooks/pre-push \
    && chmod +x /etc/git/hooks/pre-push \
    && git config --system core.hooksPath /etc/git/hooks

# Ownership/permissions herstellen na in-place upgrade + npm install als root
RUN chown -R node:node /app \
    && chmod -R u=rwX,go=rX /app \
    && find /app/skills -type f -name "*.sh" -exec chmod +x {} \;

ENV CHROME_BIN=/usr/local/bin/chromium-docker

USER node
