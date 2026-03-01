# 🔍 SearXNG Setup Guide

> **Add private, self-hosted web search to your OpenClaw instance — including optional darkweb search via Tor.**

SearXNG is a privacy-respecting metasearch engine that aggregates results from 70+ sources (Google, Bing, DuckDuckGo, and more). This guide walks you through setting it up as a local search API for OpenClaw.

---

## 📋 Table of Contents

- [✅ Prerequisites](#-prerequisites)
- [📁 Step 1 — Create the directory structure](#-step-1--create-the-directory-structure)
- [🔑 Step 2 — Generate a secret key](#-step-2--generate-a-secret-key)
- [⚙️ Step 3 — Create the settings file](#️-step-3--create-the-settings-file)
- [🔒 Step 4 — Set file permissions](#-step-4--set-file-permissions)
- [🐳 Step 5 — Create the Docker Compose file](#-step-5--create-the-docker-compose-file)
- [🌐 Step 6 — Create the shared Docker network](#-step-6--create-the-shared-docker-network)
- [🚀 Step 7 — Start SearXNG](#-step-7--start-searxng)
- [✅ Step 8 — Verify it works](#-step-8--verify-it-works)
- [🔗 Connecting OpenClaw to SearXNG](#-connecting-openclaw-to-searxng)
- [🧩 Installing the SearXNG Skill](#-installing-the-searxng-skill)
- [🔧 Troubleshooting](#-troubleshooting)

---

## ✅ Prerequisites

Before you start, make sure you have:

| # | Requirement | Details |
| - | --- | --- |
| 1 | **Linux server** | Same server as your OpenClaw instance (Hetzner VPS, Ubuntu, etc.) |
| 2 | **Docker Engine + Compose v2** | [Install Docker](https://docs.docker.com/engine/install/) |
| 3 | **OpenClaw running** | Follow the [main setup guide](../README.md) first |

---

## 📁 Step 1 — Create the directory structure

```bash
mkdir -p /home/docker/searxng/searxng
cd /home/docker/searxng
```

---

## 🔑 Step 2 — Generate a secret key

```bash
openssl rand -hex 32
```

Copy the output — you'll need it in the next step.

---

## ⚙️ Step 3 — Create the settings file

```bash
nano searxng/settings.yml
```

Paste the following content. Replace `<YOUR-SECRET-KEY>` with the key you generated:

```yaml
use_default_settings:
  engines:
    remove:
      - torch

server:
  secret_key: "<YOUR-SECRET-KEY>"
  limiter: false
  image_proxy: true
  bind_address: "0.0.0.0"

outgoing:
  proxies:
    all://:
      - socks5h://tor-proxy:9050

search:
  safe_search: 0
  autocomplete: "google"
  formats:
    - html
    - json

engines:
  - name: google
    engine: google
    shortcut: g
  - name: duckduckgo
    engine: duckduckgo
    shortcut: ddg
  - name: bing
    engine: bing
    shortcut: b
  - name: ahmia
    engine: ahmia
    shortcut: ah
    using_tor_proxy: true
```

> [!IMPORTANT]
> - `use_default_settings` with `engines.remove: torch` is required because the torch engine no longer exists in recent SearXNG versions. Without this exclusion, SearXNG will fail to start.
> - `formats: - json` is critical — without it, the JSON API won't work.
> - The `outgoing.proxies` section routes traffic through the Tor proxy container for darkweb engines (like Ahmia).

<details>
<summary>🌑 <strong>Enabling/disabling darkweb search</strong></summary>

To disable darkweb search (Ahmia) without removing the config, add `disabled: true`:

```yaml
  - name: ahmia
    engine: ahmia
    shortcut: ah
    using_tor_proxy: true
    disabled: true
```

After editing, fix permissions and restart:

```bash
chown 977:977 searxng/settings.yml && chmod 644 searxng/settings.yml
docker compose restart
```

Remove `disabled: true` to re-enable it.

</details>

---

## 🔒 Step 4 — Set file permissions

SearXNG runs as UID 977 inside the container:

```bash
chown -R 977:977 /home/docker/searxng/searxng/
chmod 644 /home/docker/searxng/searxng/settings.yml
```

---

## 🐳 Step 5 — Create the Docker Compose file

```bash
nano /home/docker/searxng/docker-compose.yaml
```

```yaml
services:
  searxng:
    image: searxng/searxng:latest
    container_name: searxng
    restart: unless-stopped
    ports:
      - "8888:8080"
    volumes:
      - ./searxng:/etc/searxng
    environment:
      - SEARXNG_BASE_URL=https://searxng.yourdomain.com/
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
    mem_limit: 1g
    cpus: 1.0
    depends_on:
      - tor
    networks:
      - searxng-net
      - openclaw-shared

  tor:
    image: dperson/torproxy:latest
    container_name: tor-proxy
    restart: unless-stopped
    mem_limit: 512m
    cpus: 0.5
    networks:
      - searxng-net

networks:
  searxng-net:
    driver: bridge
  openclaw-shared:
    external: true
```

> [!NOTE]
> 🧅 The `tor` service provides a SOCKS5 proxy on port 9050. SearXNG uses it automatically for engines with `using_tor_proxy: true` (like Ahmia) via the `outgoing.proxies` setting in `settings.yml`.

---

## 🌐 Step 6 — Create the shared Docker network

This network connects SearXNG and OpenClaw:

```bash
docker network create openclaw-shared
```

---

## 🚀 Step 7 — Start SearXNG

```bash
cd /home/docker/searxng
docker compose up -d
```

---

## ✅ Step 8 — Verify it works

```bash
# Check logs (there should be no errors)
docker logs searxng --tail 20

# Test the JSON API
curl -s "http://localhost:8888/search?q=test&format=json" | head -c 500

# Check if the Tor proxy is running
docker logs tor-proxy --tail 5
```

You should see a JSON response with search results.

---

## 🔗 Connecting OpenClaw to SearXNG

### Step 9 — Update the OpenClaw Docker Compose file

Edit `/home/docker/openClaw/docker-compose.yaml` and make two changes:

**1.** Add `openclaw-shared` to the `openclaw-gateway` service networks:

```yaml
    networks:
      - openclaw-net
      - openclaw-shared
```

**2.** Add the external network to the `networks` definition at the bottom:

```yaml
networks:
  openclaw-net:
    driver: bridge
  openclaw-shared:
    external: true
```

### Step 10 — Restart OpenClaw

```bash
cd /home/docker/openClaw
docker compose down
docker compose up -d
```

### Step 11 — Test the connection

```bash
docker exec openclaw-gateway curl -s "http://searxng:8080/search?q=test&format=json" | head -c 300
```

You should see a JSON response with search results. This confirms OpenClaw can reach SearXNG through the shared Docker network.

> [!NOTE]
> 🔌 **Internal address:** OpenClaw reaches SearXNG via `http://searxng:8080` (Docker DNS on the shared network). No Cloudflare Tunnel is needed for this internal communication.

---

## 🧩 Installing the SearXNG Skill

### Step 12 — Install the official skill via ClawHub

The official `searxng` skill (by Avinash Venkatswamy) is installed via ClawHub. Run this on the **host** (not inside the container — it's read-only). The files go into the mounted config volume.

```bash
# Create the skills directory
mkdir -p /home/docker/openClaw/data/config/skills

# Install the skill via ClawHub
npx -y clawhub install searxng --dir /home/docker/openClaw/data/config/skills
```

<details>
<summary>🔍 <strong>Reviewing the skill for safety</strong></summary>

The skill contains a single Python script (`scripts/searxng.py`) that makes HTTP GET requests to your own SearXNG instance. No outbound calls to external servers, no file writes, no telemetry.

**Dependencies:** `httpx` (HTTP client) and `rich` (terminal formatting).

Review the code after installation:

```bash
cat /home/docker/openClaw/data/config/skills/searxng/scripts/searxng.py
```

</details>

### Step 13 — Add Python dependencies to the Dockerfile

The SearXNG skill requires `httpx` and `rich`. The OpenClaw container doesn't include `pip` by default, so add them via `apt-get` in the Dockerfile.

Edit `/home/docker/openClaw/Dockerfile` and add `python3-httpx` and `python3-rich` to the `apt-get install` line:

```dockerfile
       xdg-utils \
       python3-httpx \
       python3-rich \
```

### Step 14 — Set permissions for the skills directory

The container runs as user `node` (UID 1000). The skills directory must be owned by this user:

```bash
chown -R 1000:1000 /home/docker/openClaw/data/config/skills/
```

### Step 15 — Add the SEARXNG_URL environment variable

Edit `/home/docker/openClaw/docker-compose.yaml` and add `SEARXNG_URL` to the `openclaw-gateway` environment:

```yaml
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN}
      CHROME_BIN: /usr/local/bin/chromium-docker
      CHROMIUM_FLAGS: "--no-sandbox --disable-gpu --disable-dev-shm-usage"
      SEARXNG_URL: "http://searxng:8080"
```

### Step 16 — Rebuild and restart OpenClaw

Since the Dockerfile was modified, the image needs to be rebuilt:

```bash
cd /home/docker/openClaw
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Step 17 — Verify the skill

```bash
# Check if the searxng skill is loaded
docker compose exec openclaw-gateway node dist/index.js skills 2>&1 | grep -i searxng
# Expected: ✓ ready │ 📦 searxng

# Test the skill end-to-end
docker exec -e SEARXNG_URL=http://searxng:8080 openclaw-gateway \
  python3 /home/node/.openclaw/skills/searxng/scripts/searxng.py search "test" --format json 2>&1 | head -c 300
# Expected: JSON with search results
```

### Step 18 — Update TOOLS.md for the agent

Add a SearXNG section to `/home/docker/openClaw/data/workspace/TOOLS.md` so your agent knows how to use the skill:

```bash
cat >> /home/docker/openClaw/data/workspace/TOOLS.md << 'EOF'

## SearXNG Web Search

- **Skill:** `searxng` (ClawHub, official)
- **What:** Privacy-respecting metasearch engine aggregating 70+ engines (Google, Bing, DuckDuckGo, Ahmia/darkweb)
- **Internal address:** `http://searxng:8080`
- **Env:** `SEARXNG_URL=http://searxng:8080`

### Commands

```bash
python3 ~/.openclaw/skills/searxng/scripts/searxng.py search "query"                    # Top 10 results
python3 ~/.openclaw/skills/searxng/scripts/searxng.py search "query" -n 20               # Top 20 results
python3 ~/.openclaw/skills/searxng/scripts/searxng.py search "query" --format json        # JSON output
python3 ~/.openclaw/skills/searxng/scripts/searxng.py search "query" --category news      # News
python3 ~/.openclaw/skills/searxng/scripts/searxng.py search "query" --category images    # Images
python3 ~/.openclaw/skills/searxng/scripts/searxng.py search "query" --time-range day     # Last 24h
python3 ~/.openclaw/skills/searxng/scripts/searxng.py search "query" --language nl        # Dutch results
```

### When to use

- **Always** use as first choice for web searches — free, unlimited, private
- Use `--format json` when you need to process results programmatically
- Use `--category news --time-range day` for current news
- Combine `--language nl` for Dutch-specific results
- Ahmia engine searches darkweb (.onion sites) via Tor proxy
EOF
```

> [!TIP]
> 📖 **Why TOOLS.md?** This file is your agent's cheat sheet. It reads TOOLS.md at the start of every session to know what tools are available and how to use them. By adding SearXNG here, your agent will automatically use it as the first choice for web searches.

---

## 🔧 Troubleshooting

| Problem | Cause | Solution |
| --- | --- | --- |
| `Permission denied: settings.yml` | Wrong owner/permissions | `chown 977:977 searxng/settings.yml && chmod 644 searxng/settings.yml` |
| `loading engine torch failed` | Torch no longer exists in recent versions | Use `use_default_settings.engines.remove: [torch]` instead of `use_default_settings: true` |
| Empty response from JSON API | `formats: - json` is missing | Add `json` under `search.formats` in `settings.yml` |
| Ahmia engine fails | Tor proxy not reachable | Check if the `tor-proxy` container is running and on the same network |
| Skill doesn't appear in `skills` output | Wrong permissions on skills directory | `chown -R 1000:1000 /home/docker/openClaw/data/config/skills/` |
| `No module named 'httpx'` | Python dependencies missing in container | Add `python3-httpx python3-rich` to the Dockerfile and rebuild |
| `clawhub` fails in container | Container is read-only | Install skills on the host, not inside the container |

---

## 📡 Next Steps (optional)

- ☁️ Expose SearXNG via Cloudflare Tunnel + Access Policy for remote use
- 🔄 Update the skill: `npx -y clawhub update searxng --dir /home/docker/openClaw/data/config/skills`

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/MadeByAdem">MadeByAdem</a>
</p>
