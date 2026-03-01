<p align="center">
  <img src="https://openclaw.ai/blog/openclaw-logo-text.png" alt="OpenClaw" width="300" />
  <br />
  <img src="https://www.docker.com/wp-content/uploads/2022/03/Moby-logo.png" alt="Docker" width="80" />
</p>

<h1 align="center">openClaw Docker</h1>

<p align="center">
  <strong>Self-host OpenClaw on your own server — hardened, Dockerized, ready to go.</strong>
</p>

<p align="center">
  <a href="https://github.com/MadeByAdem/openClaw-Docker/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License" /></a>
  <a href="#security"><img src="https://img.shields.io/badge/security-hardened-brightgreen.svg" alt="Security Hardened" /></a>
  <img src="https://img.shields.io/badge/docker-ready-2496ED.svg?logo=docker&logoColor=white" alt="Docker Ready" />
  <img src="https://img.shields.io/badge/platform-linux%20%7C%20raspberry%20pi-lightgrey.svg" alt="Platform" />
</p>

---

> [!CAUTION]
>
> ## ⛔🔴 Security Warning — Read Before Use
>
> **OpenClaw is still new and actively in development.** The creators themselves and independent security researchers warn about significant security risks:
>
> - 🔓 [Aikido](https://www.aikido.dev/blog/why-trying-to-secure-openclaw-is-ridiculous) — *"Why trying to secure OpenClaw is ridiculous"*
> - 🏢 [Microsoft](https://www.microsoft.com/en-us/security/blog/2026/02/19/running-openclaw-safely-identity-isolation-runtime-risk/) — *"Run OpenClaw only in fully isolated environments"*
> - 🌐 [Cisco](https://blogs.cisco.com/ai/personal-ai-agents-like-openclaw-are-a-security-nightmare) — *"Personal AI agents like OpenClaw are a security nightmare"*
>
> **⚠️ A completely secure setup is not currently achievable.** Despite the hardening measures in this repository, **you remain fully responsible** for evaluating the risks of running OpenClaw in your environment. Do not run it on machines with access to sensitive data without understanding the implications.
>
> 👉 See [Security](#-security) and [SECURITY.md](docs/SECURITY.md) for details and hardening measures.

> **What is OpenClaw?** OpenClaw is an open-source AI assistant that connects to messaging platforms like WhatsApp, Telegram and Discord. This repository lets you self-host it in a Docker container on any Linux server — with security hardening built in.

---

## 📋 Table of Contents

- [📦 What&#39;s Included](#-whats-included)
- [✅ Prerequisites](#-prerequisites)
- [🚀 Installation](#-installation)
- [🎨 Personalization](#-personalization)
- [💬 Connecting Channels](#-connecting-channels)
- [🖥️ Accessing the Dashboard](#️-accessing-the-dashboard)
- [⚙️ Managing Your Server](#️-managing-your-server)
- [🔐 Environment Variables](#-environment-variables)
- [🔧 Troubleshooting](#-troubleshooting)
- [🔒 Security](#-security)
- [🔄 Updating](#-updating)
- [📦 Migrating to Hardened Setup](#-migrating-to-hardened-setup)
- [🤖 Choosing a Model](#-choosing-a-model)
- [🔍 Add-ons](#-add-ons)
- [📁 File Overview](#-file-overview)
- [💾 Data &amp; Backups](#-data--backups)
- [📄 License](#-license)

---

## 📦 What's Included

This project adds a thin Docker layer on top of the official `alpine/openclaw` image:

- 🌐 **Chromium browser** with all required dependencies for browser automation skills
- 🐳 A `--no-sandbox` wrapper so Chromium runs correctly inside Docker
- 🔧 Execute-permission fixes for bundled skill scripts
- 🔒 **Security hardening** — read-only filesystem, dropped capabilities, rate limiting, health checks

Everything else is standard OpenClaw — no custom code.

---

## ✅ Prerequisites

Before you start, make sure you have:

| # | Requirement                          | Details                                                                   |
| - | ------------------------------------ | ------------------------------------------------------------------------- |
| 1 | **Linux server**               | Ubuntu recommended, Raspberry Pi also works                               |
| 2 | **Docker Engine + Compose v2** | [Install Docker](https://docs.docker.com/engine/install/)                    |
| 3 | **AI provider API key**        | Any OpenAI-compatible provider (OpenAI, Anthropic, Google, Mistral, etc.) |

<details>
<summary>📥 <strong>Installing Docker (if you don't have it yet)</strong></summary>

```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Allow your user to run Docker without sudo
sudo usermod -aG docker $USER

# Log out and back in for the group change to take effect
exit
```

After logging back in, verify it works:

```bash
docker --version
docker compose version
```

Both commands should print a version number without errors.

</details>

---

## 🚀 Installation

Follow these steps one by one. Each step includes the exact command to run.

### Step 1 — Clone this repository

```bash
git clone https://github.com/MadeByAdem/openClaw-Docker.git
cd openClaw-Docker
```

### Step 2 — Run the setup script

```bash
chmod +x setup.sh
sudo ./setup.sh
```

The setup script will automatically:

1. ✅ Check that Docker and Docker Compose are installed
2. 📁 Create the required data directories (`./data/config` and `./data/workspace`)
3. 🔑 Generate a `.env` file with a secure 256-bit gateway token
4. 🐳 Build the Docker image with security hardening
5. 🧙 Start the interactive onboarding process
6. 🔒 Run `doctor --repair` and `security audit`

### Step 3 — Complete the onboarding

The onboarding wizard will start automatically. It will ask you to:

1. **Enter your AI provider API key** (e.g. OpenAI, Anthropic, Google, Mistral, or any compatible provider)
2. **Connect your first messaging channel** (WhatsApp, Telegram or Discord)

Follow the prompts on screen. When it's done, your OpenClaw gateway will be running.

### Step 4 — Verify it's running

```bash
docker compose logs -f openclaw-gateway
```

You should see log output indicating the gateway is active. Press `Ctrl+C` to stop following the logs (the gateway keeps running in the background).

> [!TIP]
> **Ask the AI itself for help!** Once your bot is running, you can message it directly:
>
> - *"Connect my Telegram bot"* — walks you through BotFather setup
> - *"Switch my model to Claude Sonnet"* — updates its own config
> - *"Why am I getting an error?"* — paste the error and it suggests a fix
> - *"Set up a daily summary cron job"* — configures scheduled tasks
> - *"What skills do you have?"* — lists available capabilities
>
> You don't need to memorize CLI commands. If you're unsure, just ask your bot.

### Step 5 — Personalize your agent (optional)

Make your AI agent yours — give it a name, personality, and context about you:

```bash
chmod +x personalize.sh
./personalize.sh
```

See [Personalization](#-personalization) for details.

---

## 🎨 Personalization

After the initial setup, you can personalize your AI agent by running the personalization script. This creates configuration files in the workspace that define your agent's identity, personality, and behavior.

```bash
./personalize.sh
```

The script walks you through creating these files:

| File | Purpose |
| --- | --- |
| `IDENTITY.md` | Your agent's name, roles, language, and how it introduces itself |
| `SOUL.md` | Core values, communication style, and personality |
| `USER.md` | About you — name, timezone, preferences, so the agent knows who it's helping |
| `AGENTS.md` | Behavioral guidelines — memory management, safety rules, group chat behavior |
| `CONVENTIONS.md` | Coding standards, git workflow, project terminology (for developers) |
| `TOOLS.md` | Integration notes — scripts, APIs, credentials locations |
| `HEARTBEAT.md` | Periodic tasks your agent should check on |
| `MEMORY.md` | Long-term memory (starts empty, your agent fills this over time) |

For each file, you can:

- **Edit** — open in your text editor to customize
- **View example** — see a working example before editing
- **Skip** — use the default template (you can always edit later)

The script restarts OpenClaw automatically when done. You can also edit these files manually at any time in `./data/workspace/` and restart with `docker compose restart openclaw-gateway`.

> [!TIP]
> Check the `workspace/` directory in this repository for a complete example of a personalized agent workspace.

---

## 💬 Connecting Channels

You can connect one or more messaging platforms after setup.

### WhatsApp

1. Enable the WhatsApp plugin (skip if you already selected WhatsApp during onboarding):

```bash
docker compose exec openclaw-gateway node dist/index.js plugins enable whatsapp
```

2. Login and scan the QR code:

```bash
docker compose exec openclaw-gateway node dist/index.js channels login --channel whatsapp
```

A QR code will appear in your terminal. Scan it with WhatsApp on your phone (**Settings > Linked Devices > Link a Device**).

### Telegram

1. Enable the Telegram plugin (skip if you already selected Telegram during onboarding):

```bash
docker compose exec openclaw-gateway node dist/index.js plugins enable telegram
```

2. Create a bot via [@BotFather](https://t.me/BotFather) on Telegram and copy the bot token.
3. Add the bot:

```bash
docker compose exec openclaw-gateway node dist/index.js channels add --channel telegram --token "YOUR_BOT_TOKEN"
```

4. Send a message to your bot on Telegram. It will ask you to approve the pairing:

```bash
docker compose exec openclaw-gateway node dist/index.js pairing approve telegram CODE
```

Replace `CODE` with the pairing code shown in the message.

> [!NOTE]
> **Webhook conflict?** If the bot was previously used in another project, you may need to remove the old webhook first:
>
> ```bash
> curl -s "https://api.telegram.org/botYOUR_BOT_TOKEN/deleteWebhook"
> docker compose restart openclaw-gateway
> ```
>
> Alternatively, create a fresh bot via @BotFather.

### Discord

1. Enable the Discord plugin (skip if you already selected Discord during onboarding):

```bash
docker compose exec openclaw-gateway node dist/index.js plugins enable discord
```

2. Create a bot on the [Discord Developer Portal](https://discord.com/developers/applications) and copy the bot token.
3. Add the bot:

```bash
docker compose exec openclaw-gateway node dist/index.js channels add --channel discord --token "YOUR_BOT_TOKEN"
```

---

## 🖥️ Accessing the Dashboard

OpenClaw includes a web dashboard (Control UI) for managing your instance. The setup script automatically configures it for you.

### Local access

After running `setup.sh`, the dashboard URL is printed in the terminal. You can also retrieve it at any time:

```bash
docker compose exec openclaw-gateway node dist/index.js dashboard --no-open
```

Open the printed URL in your browser. It looks like this:

```
http://127.0.0.1:18789/#token=YOUR_GATEWAY_TOKEN
```

> [!IMPORTANT]
> 🔑 The token is passed after the `#` (hash), not as a `?` query parameter. Do not share URLs containing your token.

> [!WARNING]
> 🚫 **Never expose the dashboard directly to the internet.** The gateway should only be accessible on `127.0.0.1`. Use an SSH tunnel, Tailscale, or a reverse proxy with TLS termination for remote access. Exposed instances have been found in sensitive sectors ([Bitsight](https://www.bitsight.com/blog/openclaw-ai-security-risks-exposed-instances)). See [Security](#-security) for details.

### Remote access (reverse proxy)

If you access OpenClaw through a reverse proxy (Cloudflare Tunnel, nginx, Caddy, etc.), the setup script already configures the required settings. If you set up a reverse proxy after initial installation, add these settings to `./data/config/openclaw.json`:

```json
{
  "gateway": {
    "bind": "lan",
    "trustedProxies": ["172.17.0.0/16"],
    "controlUi": {
      "allowInsecureAuth": true
    }
  }
}
```

> [!WARNING]
> Setting `allowInsecureAuth: true` allows token authentication over plain HTTP. **Only enable this if your reverse proxy terminates TLS** — otherwise your gateway token is sent in plaintext. If you used `setup.sh`, this is `false` by default and can be opted in via `OPENCLAW_ALLOW_INSECURE_AUTH=true` in `.env`.

Then restart the gateway:

```bash
docker compose restart openclaw-gateway
```

Open the dashboard in your browser using your domain:

```
https://your-domain.com/#token=YOUR_GATEWAY_TOKEN
```

Replace `YOUR_GATEWAY_TOKEN` with the token from your `.env` file.

**What these settings do:**

| Setting                         | Purpose                                                                                   |
| ------------------------------- | ----------------------------------------------------------------------------------------- |
| `bind: "lan"`                 | Allows connections from Docker's internal network (default `loopback` blocks them)      |
| `trustedProxies`              | Tells the gateway to trust proxy headers from Docker's bridge network (`172.17.0.0/16`) |
| `controlUi.allowInsecureAuth` | Allows the dashboard to authenticate over HTTP (only safe behind a TLS-terminating proxy) |

<details>
<summary>🔧 <strong>Troubleshooting the dashboard</strong></summary>

**"gateway token mismatch"** — The token in your browser URL does not match the token in `openclaw.json`. Check that `gateway.auth.token` in `./data/config/openclaw.json` matches the `OPENCLAW_GATEWAY_TOKEN` in your `.env` file. If they differ, update one to match the other and restart.

**"pairing required"** — The gateway doesn't trust the proxy connection. Make sure `trustedProxies` and `controlUi.allowInsecureAuth` are set as shown above, then restart the gateway.

**"Proxy headers detected from untrusted address"** — Same cause as above. Add `trustedProxies` with the Docker network range to your gateway config.

</details>

<details>
<summary>☁️ <strong>Cloudflare Tunnel + Access (recommended for remote access)</strong></summary>

Cloudflare Tunnel exposes your gateway to the internet **without opening any ports** on your server. Cloudflare Access adds a Zero Trust authentication layer **in front of** the gateway — users must authenticate with Cloudflare before they even reach the OpenClaw dashboard.

**What you get:**

- No open ports on your server
- TLS handled by Cloudflare (no certificate management)
- Extra authentication layer before the gateway token
- Your server's IP address stays hidden

#### Step 1 — Install `cloudflared`

```bash
# Debian/Ubuntu
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install -y cloudflared
```

#### Step 2 — Authenticate and create a tunnel

```bash
# Login to your Cloudflare account (opens a browser)
cloudflared tunnel login

# Create a tunnel
cloudflared tunnel create openclaw
```

Note the **Tunnel ID** from the output — you'll need it in the next step.

#### Step 3 — Configure the tunnel

Create the config file at `~/.cloudflared/config.yml`:

```yaml
tunnel: <YOUR_TUNNEL_ID>
credentials-file: /root/.cloudflared/<YOUR_TUNNEL_ID>.json

ingress:
  - hostname: pa.example.com
    service: http://localhost:18789
  - service: http_status:404
```

Replace `pa.example.com` with your actual domain.

#### Step 4 — Create a DNS route

```bash
cloudflared tunnel route dns openclaw pa.example.com
```

This creates a CNAME record pointing your domain to the tunnel.

#### Step 5 — Run as a systemd service

```bash
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

#### Step 6 — Set up Cloudflare Access

1. Go to the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Access** → **Applications** → **Add an application**
3. Select **Self-hosted** and enter your domain (`pa.example.com`)
4. Create a policy — for example, allow specific email addresses:
   - **Policy name:** `OpenClaw admins`
   - **Action:** Allow
   - **Include:** Emails — `you@example.com`
5. Save the application

Now anyone accessing `pa.example.com` must first authenticate through Cloudflare Access before reaching the OpenClaw dashboard.

#### Step 7 — Update `openclaw.json`

Add your Cloudflare domain to the allowed origins:

```json
{
  "gateway": {
    "controlUi": {
      "allowedOrigins": [
        "http://localhost:18789",
        "http://127.0.0.1:18789",
        "https://pa.example.com"
      ],
      "allowInsecureAuth": true
    }
  }
}
```

> `allowInsecureAuth: true` is safe here because Cloudflare terminates TLS — traffic between `cloudflared` and your local gateway stays on `localhost`.

Make sure `gateway.mode` is set to `"local"` — the gateway refuses to start without it:

```json
{
  "gateway": {
    "mode": "local",
    "bind": "lan"
  }
}
```

Restart the gateway:

```bash
docker compose restart openclaw-gateway
```

#### Step 8 — Approve the device pairing

When you open the dashboard for the first time via Cloudflare, the gateway will show a **pairing request**. Approve it from the server:

```bash
# List pending pairing requests
docker compose exec openclaw-gateway node dist/index.js devices list

# Approve the request
docker compose exec openclaw-gateway node dist/index.js devices approve <REQUEST_ID>
```

Replace `<REQUEST_ID>` with the ID shown in the list.

Open the dashboard at:

```
https://pa.example.com/#token=YOUR_GATEWAY_TOKEN
```

#### Troubleshooting Cloudflare setup

**"Gateway start blocked: set gateway.mode=local"** — Add `"mode": "local"` to the `gateway` object in `openclaw.json`.

**Gateway ignores bind setting** — Do not use `--bind` in the docker-compose `command`. Let `openclaw.json` handle it via `"bind": "lan"`. The `--bind` CLI flag overrides the config file and can cause conflicts.

**Dashboard loads but pairing fails** — Make sure `trustedProxies` includes the Docker bridge subnet (`172.17.0.0/16`) and `allowInsecureAuth` is `true`. Then approve the device pairing as shown in Step 8.

</details>

---

## ⚙️ Managing Your Server

Common commands for managing your OpenClaw instance:

| Action                    | Command                                                                            |
| ------------------------- | ---------------------------------------------------------------------------------- |
| 📋 View live logs         | `docker compose logs -f openclaw-gateway`                                        |
| ⏹️ Stop the server      | `docker compose down`                                                            |
| ▶️ Start the server     | `docker compose up -d`                                                           |
| 🔄 Restart the server     | `docker compose restart openclaw-gateway`                                        |
| 💻 Interactive TUI        | `docker compose exec openclaw-gateway node dist/index.js tui`                                       |
| ⚙️ Change configuration | `docker compose exec openclaw-gateway node dist/index.js configure`                                 |
| 🔨 Rebuild after updates  | `docker compose down && docker compose build --no-cache && docker compose up -d` |
| 🔒 Run a security audit   | `docker compose exec openclaw-gateway node dist/index.js security audit --deep`                     |
| 🩺 Run doctor check       | `docker compose exec openclaw-gateway node dist/index.js doctor --repair`                           |

---

## 🔐 Environment Variables

You can use `${VAR_NAME}` references in `openclaw.json` instead of hardcoding secrets like API keys, bot tokens and chat IDs. OpenClaw resolves these references at startup from environment variables.

### Example

Instead of hardcoding your Telegram bot token:

```json
{
  "channels": {
    "telegram": {
      "botToken": "123456:ABC-DEF..."
    }
  }
}
```

Reference an environment variable:

```json
{
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}"
    }
  }
}
```

### Where to put the `.env` file

This project uses **two** `.env` files with different purposes:

| File | Read by | Purpose |
| --- | --- | --- |
| `./.env` (project root) | Docker Compose | Interpolates `${...}` variables in `docker-compose.yaml` |
| `./data/config/.env` | OpenClaw | Resolves `${...}` references in `openclaw.json` |

The **project root** `.env` is created by `setup.sh` and feeds Docker Compose. It does **not** reach OpenClaw inside the container.

To use `${VAR}` references in `openclaw.json`, create a `.env` file in the **config directory**:

```bash
# Create the file
cat > ./data/config/.env << 'EOF'
TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
GATEWAY_TOKEN=your-gateway-token
OPENAI_API=sk-...
NOTION_API=secret_...
EOF

# Set ownership to the container's node user (uid 1000)
chown 1000:1000 ./data/config/.env

# Restrict permissions
chmod 600 ./data/config/.env
```

> [!IMPORTANT]
> The file **must** be owned by uid `1000:1000` (the `node` user inside the container). If it is owned by `root`, OpenClaw cannot read it and will fail with `MissingEnvVarError`.

Then restart the gateway:

```bash
docker compose restart openclaw-gateway
```

> [!WARNING]
> **Known issue:** Commands like `doctor --fix`, `configure` and `update` can resolve `${VAR}` references back to **plaintext** and write the actual secrets into `openclaw.json`. After running these commands, check `openclaw.json` and restore any `${...}` references that were overwritten.

---

## 🔧 Troubleshooting

<details>
<summary><strong>"Unknown model" error</strong></summary>

If you see `Unknown model: anthropic/claude-sonnet-4`, the configured model name is outdated. Update it:

```bash
docker compose exec openclaw-gateway sed -i \
  's|anthropic/claude-sonnet-4|anthropic/claude-sonnet-4-5|g' \
  /home/node/.openclaw/openclaw.json
docker compose restart openclaw-gateway
```

Available Anthropic models:

- `anthropic/claude-opus-4-5`
- `anthropic/claude-sonnet-4-5`
- `anthropic/claude-haiku-4-5`

> **Which model should I choose?** See [Choosing a Model](#-choosing-a-model) below for guidance.

</details>

<details>
<summary><strong>Skill installation fails (EACCES permission error)</strong></summary>

Some skills may fail to install during onboarding due to permissions. Fix it with:

```bash
docker compose run --rm --user root openclaw-cli npm install -g clawhub
```

</details>

<details>
<summary><strong>"Gateway start blocked: set gateway.mode=local"</strong></summary>

The gateway requires `gateway.mode` to be set in `openclaw.json`. Add it:

```bash
docker compose exec openclaw-gateway sed -i \
  's|"gateway": {|"gateway": {\n    "mode": "local",|' \
  /home/node/.openclaw/openclaw.json
docker compose restart openclaw-gateway
```

Or edit `./data/config/openclaw.json` directly and add `"mode": "local"` inside the `gateway` object.

</details>

<details>
<summary><strong>Container won't start</strong></summary>

Check if Docker is running:

```bash
sudo systemctl status docker
```

If it's not active, start it:

```bash
sudo systemctl start docker
```

Then try again:

```bash
docker compose up -d
```

</details>

---

## 🔒 Security

> [!CAUTION]
> ⚠️ **OpenClaw has access to your files, messages and API keys.** Security researchers have identified vulnerabilities including SSRF bugs, path traversal, missing webhook authentication and malicious skills on the ClawHub marketplace. **Take security seriously — review the hardening measures below.**

This Docker setup includes several hardening measures out of the box:

| Measure                               | What it does                                                                     |
| ------------------------------------- | -------------------------------------------------------------------------------- |
| 🔏**Read-only filesystem**      | The container filesystem is immutable — malware cannot modify application files |
| 🚫**Dropped capabilities**      | All Linux capabilities are removed (`cap_drop: ALL`)                           |
| ⬆️**No privilege escalation** | `no-new-privileges` prevents processes from gaining additional permissions     |
| 📊**Resource limits**           | Memory, CPU, and PID limits prevent resource exhaustion and fork-bomb attacks    |
| 🏠**Localhost binding**         | Ports are bound to `127.0.0.1` — the gateway is not exposed to the internet   |
| 🔑**Token authentication**      | A 256-bit gateway token is required for all dashboard and API access             |
| 🛡️**Auth rate limiting**      | Brute-force protection: 10 attempts per minute, 5-minute lockout                 |
| 💓**Health checks**             | Docker automatically detects and restarts unhealthy containers                   |
| 🌐**Isolated network**          | Containers run in a dedicated Docker network                                     |

### 🛡️ Application-level hardening

In addition to Docker container isolation, the setup script applies these **application-level** security settings to `openclaw.json`:

| Setting | Value | What it does |
| --- | --- | --- |
| `session.dmScope` | `"per-channel-peer"` | Each sender gets an isolated session — prevents cross-user context leakage |
| `tools.deny` | `["sessions_spawn", "sessions_send"]` | Blocks session hijacking tools |
| `tools.exec.security` | `"full"` | Allows command execution (for custom scripts) |
| `tools.fs.workspaceOnly` | `true` | Restricts file access to the workspace directory only |
| `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork` | `false` | Blocks browser access to private/internal networks (SSRF protection) |
| `logging.redactSensitive` | `"tools"` | Redacts tokens and secrets from log output |
| `discovery.mdns.mode` | `"off"` | Disables mDNS broadcast (leaks hostname and install path) |

> [!CAUTION]
> ⚠️ **Command execution is enabled by default** (`tools.exec.security: "full"`). This allows the AI to run scripts and commands on your server. The bot **cannot**:
>
> - ❌ Spawn or hijack other sessions
> - ❌ Access files outside the workspace directory
> - ❌ Access your internal network via browser (SSRF protection)
>
> If you don't need command execution, set `tools.exec.security` to `"deny"` or use `"allowlist"` mode for a safer middle ground. See the [OpenClaw security docs](https://docs.openclaw.ai/gateway/security) for details.

<details>
<summary>🔓 <strong>Relaxing tool restrictions (at your own risk)</strong></summary>

To re-enable specific capabilities, edit `./data/config/openclaw.json`:

**Allow browser automation** (needed for web search/scraping skills):

```json
{
  "browser": {
    "ssrfPolicy": { "dangerouslyAllowPrivateNetwork": false }
  },
  "tools": {
    "profile": "full"
  }
}
```

**Allow command execution** (needed for code/shell skills):

```json
{
  "tools": {
    "exec": {
      "security": "ask",
      "ask": "always"
    }
  }
}
```

**Allow filesystem writes** (needed for file management skills):

```json
{
  "tools": {
    "fs": { "workspaceOnly": true }
  }
}
```

**Allow custom scripts** (needed for email, automation or other custom integrations):

If you want the AI to run your own scripts (e.g. check email, query a database, send notifications), use `allowlist` mode with `safeBins` to restrict execution to trusted commands only.

1. Create a scripts directory:

```bash
mkdir -p ./data/config/scripts
chmod +x ./data/config/scripts/*.sh
```

1. Update `tools` in `./data/config/openclaw.json`:

```json
{
  "tools": {
    "deny": [
      "sessions_spawn",
      "sessions_send"
    ],
    "exec": {
      "security": "allowlist",
      "safeBins": ["bash"],
      "safeBinTrustedDirs": ["/home/node/.openclaw/scripts"]
    },
    "fs": {
      "workspaceOnly": true
    }
  }
}
```

> **What this does:**
>
> | Setting | Effect |
> | --- | --- |
> | `security: "allowlist"` | Only pre-approved commands can run (instead of everything or nothing) |
> | `safeBins: ["bash"]` | Allows `bash` as an interpreter for your scripts |
> | `safeBinTrustedDirs` | Only scripts in this directory can be executed |
> | Removed `group:runtime` from `deny` | Unblocks the exec tool (required for scripts to work) |
> | Removed `profile: "messaging"` | The messaging profile blocks exec entirely — remove it or change to `"full"` |
>
> **Security notes:**
>
> - Only place scripts you trust in the `scripts/` directory — the AI can execute anything in it
> - Keep `sessions_spawn` and `sessions_send` in the deny list to prevent the AI from creating new sessions
> - Keep `fs.workspaceOnly: true` to restrict file access
> - Review your scripts for command injection vulnerabilities (e.g. unsanitized user input passed to shell commands)
> - Use `security: "allowlist"` instead of `"full"` — `"full"` allows the AI to run **any** command on your server

After any change, restart the gateway:

```bash
docker compose restart openclaw-gateway
```

> **Keep `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork: false`** even when relaxing other settings. This prevents the bot's browser from reaching internal services on your network (databases, admin panels, etc.).

</details>

### 🩺 Run security checks

Run these commands regularly and after every update:

```bash
# Detect and fix configuration issues
docker compose exec openclaw-gateway node dist/index.js doctor --repair

# Deep security audit
docker compose exec openclaw-gateway node dist/index.js security audit --deep
```

### 🔑 Rotate your gateway token

Rotate your token periodically and immediately if you suspect it has been compromised:

```bash
# 1. Generate a new token
NEW_TOKEN=$(openssl rand -hex 32)

# 2. Update root .env (used by Docker Compose)
sed -i "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=${NEW_TOKEN}/" .env

# 3. Update data/config/.env (used by OpenClaw for ${GATEWAY_TOKEN} in openclaw.json)
sed -i "s/^GATEWAY_TOKEN=.*/GATEWAY_TOKEN=${NEW_TOKEN}/" ./data/config/.env

# 4. Restart
docker compose restart openclaw-gateway
```

> [!NOTE]
> If your `openclaw.json` uses `"${GATEWAY_TOKEN}"` (recommended), you only need to update the `.env` files — not `openclaw.json` itself. See [Environment Variables](#-environment-variables) for details.

### ⚠️ Skill marketplace safety

> [!WARNING]
> 🦠 **26% of agent skills** on public marketplaces contain at least one vulnerability. Malicious skills have been used to **exfiltrate data and distribute malware** ([Cisco](https://blogs.cisco.com/ai/personal-ai-agents-like-openclaw-are-a-security-nightmare), [Trend Micro](https://www.trendmicro.com/en_us/research/26/b/openclaw-skills-used-to-distribute-atomic-macos-stealer.html)). Never install skills without reviewing the source code first.

- **Never install skills without reviewing their source code**
- Only use skills from trusted authors
- Monitor what skills are installed: check `./data/config/` for unexpected additions
- Disable skills you don't actively use

### 🌍 Remote access best practices

- **Never bind the gateway to a public IP address** — keep it on `127.0.0.1`
- Use **SSH tunnels** or **Tailscale** for remote access
- If using a reverse proxy (Cloudflare Tunnel, nginx, Caddy), always terminate TLS at the proxy
- See [Accessing the Dashboard](#️-accessing-the-dashboard) for reverse proxy configuration

### 📚 Further reading

| Source                                                                                                                      | Topic                                  |
| --------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| [Aikido](https://www.aikido.dev/blog/why-trying-to-secure-openclaw-is-ridiculous)                                              | Security architecture analysis         |
| [Microsoft](https://www.microsoft.com/en-us/security/blog/2026/02/19/running-openclaw-safely-identity-isolation-runtime-risk/) | Identity isolation and runtime risk    |
| [Cisco](https://blogs.cisco.com/ai/personal-ai-agents-like-openclaw-are-a-security-nightmare)                                  | Skill marketplace risks                |
| [Infosecurity Magazine](https://www.infosecurity-magazine.com/news/researchers-six-new-openclaw/)                              | Endor Labs: 6 new vulnerabilities      |
| [Bitsight](https://www.bitsight.com/blog/openclaw-ai-security-risks-exposed-instances)                                         | Exposed instances in sensitive sectors |
| [Trend Micro](https://www.trendmicro.com/en_us/research/26/b/openclaw-skills-used-to-distribute-atomic-macos-stealer.html)     | Atomic macOS Stealer via skills        |
| [University of Toronto](https://security.utoronto.ca/advisories/openclaw-vulnerability-notification/)                          | CVE-2026-25253 advisory                |
| [GBHackers](https://gbhackers.com/openclaw-2026-2-12-released/)                                                                | 40+ security fixes in v2026.2.12       |
| [OpenClaw Docs](https://docs.openclaw.ai/gateway/security)                                                                     | Security configuration reference       |
| [OpenClaw Docs](https://docs.openclaw.ai/gateway/doctor)                                                                       | Built-in config auditing               |
| [OpenClaw Docs](https://docs.openclaw.ai/gateway/remote)                                                                       | Secure remote access                   |

---

## 🔄 Updating

> [!IMPORTANT]
> 🔄 **Keep your OpenClaw instance up to date.** Security patches are released frequently — version 2026.2.12 alone fixed over **40 security issues** ([GBHackers](https://gbhackers.com/openclaw-2026-2-12-released/)).

### Step-by-step update

```bash
# 1. Back up your data
cp -r ./data ./data-backup-$(date +%Y%m%d)

# 2. Pull the latest changes to this repo
git pull origin main

# 3. Rebuild the Docker image (picks up new base image + Dockerfile changes)
docker compose build --no-cache

# 4. Restart with the new image
docker compose down && docker compose up -d

# 5. Run security checks
docker compose exec openclaw-gateway node dist/index.js doctor --repair
docker compose exec openclaw-gateway node dist/index.js security audit --deep

# 6. Verify the gateway is healthy
docker compose logs -f openclaw-gateway
```

<details>
<summary>⚡ <strong>Quick one-liner</strong> (for experienced users)</summary>

```bash
cp -r ./data ./data-backup-$(date +%Y%m%d) && git pull origin main && docker compose build --no-cache && docker compose down && docker compose up -d && docker compose exec openclaw-gateway node dist/index.js doctor --repair
```

</details>

### 📡 Staying informed

- **Watch this repository** on GitHub to get notified of new releases
- **Watch the upstream** [OpenClaw repository](https://github.com/openclaw/openclaw) for security advisories
- Check the [OpenClaw changelog](https://docs.openclaw.ai) after each update

---

## 📦 Migrating to Hardened Setup

If you installed OpenClaw using an older version of this repository (before the security hardening), follow these steps to apply the new security features to your existing installation. This guide works whether you used `git clone` or manually uploaded the files.

### What changed

The hardened setup adds:

| Feature                      | Description                                                               |
| ---------------------------- | ------------------------------------------------------------------------- |
| 🔏 Read-only filesystem      | Container files cannot be modified at runtime                             |
| 🚫 Dropped capabilities      | All Linux capabilities removed                                            |
| ⬆️ No privilege escalation | Processes cannot gain new privileges                                      |
| 📊 Resource limits           | Memory, CPU, and PID caps                                                 |
| 💓 Health checks             | Auto-detect and restart unhealthy containers                              |
| 🌐 Isolated network          | Dedicated Docker bridge network                                           |
| 🎯 Narrower trusted proxies  | Dynamically detected Docker bridge subnet (defaults to `172.17.0.0/16`) |
| 🛡️ Auth rate limiting      | Brute-force protection                                                    |
| 🩺 Auto security auditing    | `doctor` and `audit` run during setup                                 |
| 👤 Session isolation         | Each sender gets isolated context (`per-channel-peer`)                  |
| 🔒 Tool restrictions         | Messaging-only profile, exec denied, filesystem restricted                |
| 🌐 SSRF protection           | Browser blocked from private networks                                     |
| 📝 Log redaction             | Tokens and secrets hidden from logs                                       |
| 📡 mDNS disabled             | No network broadcast of hostname/path                                     |

### Files changed

These files were modified or added in the hardened setup. If you uploaded files manually (without git), you need to update each of these:

| File | Change |
| --- | --- |
| `docker-compose.yaml` | Added read-only FS, dropped capabilities, resource limits, healthcheck, isolated network, tmpfs mounts |
| `Dockerfile` | Added `curl` (required for container health checks) |
| `.dockerignore` | **New file** — prevents `.env` and `data/` from leaking into the Docker build |
| `setup.sh` | Added token generation, config patching, security auditing |
| `.env.example` | Added `OPENCLAW_ALLOW_INSECURE_AUTH` option |

> [!TIP]
> The easiest way to get all file changes at once — even if you didn't use `git clone` originally — is to initialize git in your existing directory. See step 2 (Option B) below.

### Migration steps

```bash
# 1. Back up your data first
cp -r ./data ./data-backup-$(date +%Y%m%d)

# 2. Get the latest files
#    Option A: If you used git clone
git pull origin main

#    Option B: If you uploaded files manually, initialize git first:
#    git init && git remote add origin https://github.com/MadeByAdem/openClaw-Docker.git
#    git fetch origin
#    mv Dockerfile docker-compose.yaml setup.sh /tmp/openclaw-backup/
#    git checkout -b main origin/main

# 3. Restrict .env file permissions
chmod 600 .env

# 4. (Recommended) Rotate your gateway token
NEW_TOKEN=$(openssl rand -hex 32)
sed -i "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=${NEW_TOKEN}/" .env
DOCKER_SUBNET=$(docker network inspect bridge --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null || echo "172.17.0.0/16")
OC_NEW_TOKEN="$NEW_TOKEN" OC_DOCKER_SUBNET="$DOCKER_SUBNET" python3 -c "
import json, os
token = os.environ['OC_NEW_TOKEN']
docker_subnet = os.environ['OC_DOCKER_SUBNET']
with open('./data/config/openclaw.json') as f: cfg = json.load(f)

# Gateway auth + networking
cfg['gateway']['auth']['token'] = token
cfg['gateway']['auth']['rateLimit'] = {'maxAttempts': 10, 'windowMs': 60000, 'lockoutMs': 300000}
cfg['gateway']['trustedProxies'] = [docker_subnet]

# Session isolation
cfg.setdefault('session', {})['dmScope'] = 'per-channel-peer'

# Tool restrictions (messaging-only, no exec, workspace-only fs)
tools = cfg.setdefault('tools', {})
tools['profile'] = 'messaging'
tools['deny'] = ['group:automation', 'group:runtime', 'sessions_spawn', 'sessions_send']
tools.setdefault('exec', {})['security'] = 'deny'
tools.setdefault('fs', {})['workspaceOnly'] = True

# SSRF protection + logging + mDNS
cfg.setdefault('browser', {}).setdefault('ssrfPolicy', {})['dangerouslyAllowPrivateNetwork'] = False
cfg.setdefault('logging', {})['redactSensitive'] = 'tools'
cfg.setdefault('discovery', {}).setdefault('mdns', {})['mode'] = 'off'

with open('./data/config/openclaw.json', 'w') as f: json.dump(cfg, f, indent=2)
"

# 5. Rebuild the Docker image
docker compose build --no-cache

# 6. Restart with hardened configuration
docker compose down && docker compose up -d

# 7. Run security checks
docker compose exec openclaw-gateway node dist/index.js doctor --repair
docker compose exec openclaw-gateway node dist/index.js security audit --deep

# 8. Verify the container is healthy
docker inspect --format='{{.State.Health.Status}}' openclaw-gateway
```

<details>
<summary>⚡ <strong>Migration one-liner</strong></summary>

```bash
cp -r ./data ./data-backup-$(date +%Y%m%d) && git pull origin main && chmod 600 .env && docker compose build --no-cache && docker compose down && docker compose up -d && docker compose exec openclaw-gateway node dist/index.js doctor --repair
```

</details>

<details>
<summary>🔧 <strong>Troubleshooting the migration</strong></summary>

**Container won't start after migration** — The read-only filesystem may conflict with directories that need write access. The `tmpfs` mounts in `docker-compose.yaml` should handle this, but if you see permission errors, check that the `data/` directory is owned by uid 1000:

```bash
sudo chown -R 1000:1000 ./data
```

**"Health check failed"** — The health check expects the gateway to respond on port 18789. Give it up to 60 seconds after starting (the `start_period`). Check logs with `docker compose logs openclaw-gateway`.

**Skills not working** — Some skills may need write access to directories not covered by `tmpfs`. If a specific skill fails, check its error logs and consider adding the required path as a `tmpfs` mount in `docker-compose.yaml`.

</details>

---

## 🤖 Choosing a Model

Your choice of AI model has a direct impact on the quality of responses and your API costs.

### Model comparison

| Model                           | Strengths                                   | Cost   |
| ------------------------------- | ------------------------------------------- | ------ |
| `anthropic/claude-haiku-4-5`  | ⚡ Fast, lightweight, good for simple tasks | 💰     |
| `anthropic/claude-sonnet-4-5` | ⚖️ Balanced: capable and cost-effective   | 💰💰   |
| `anthropic/claude-opus-4-5`   | 🧠 Most capable, best for complex reasoning | 💰💰💰 |

### Recommendations

- **Start with Sonnet.** It offers the best balance between capability and cost for most use cases. This is a solid default for everyday conversations and tasks.
- **Use Haiku for high-volume, simple tasks.** If your bot handles many short interactions (quick Q&A, simple lookups), Haiku keeps costs low while still delivering good results.
- **Reserve Opus for complex work.** Opus excels at multi-step reasoning, detailed analysis and creative tasks — but it costs significantly more per message. Only use it when you genuinely need the extra capability.

<details>
<summary>🔀 <strong>Advanced: use different models per task type</strong></summary>

You can significantly reduce costs by routing tasks to the right model automatically. Instead of using a single model for everything, configure your assistant to:

- **Use Haiku for routine tasks** — emails, calendar queries, simple Q&A, summaries and other straightforward interactions.
- **Use Sonnet for complex tasks** — code generation, debugging, technical analysis and multi-step reasoning.

This "model routing" approach can reduce your per-session costs by **60–70%**, because the majority of everyday interactions don't need the most capable (and most expensive) model.

You can set this up by defining task categories and model assignments in your OpenClaw configuration or via an `AGENTS.md` file in your workspace.

</details>

<details>
<summary>💻 <strong>Advanced: use Claude Code CLI for code tasks</strong></summary>

If you frequently ask your assistant to analyze or generate code, consider offloading those tasks to [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Anthropic's CLI tool). Claude Code is optimized for coding workflows and can be more efficient than running code tasks through the chat interface, because it:

- Sends only the relevant code context instead of the full conversation history
- Uses targeted file reads instead of loading entire documents
- Avoids unnecessary overhead from chat-based interaction

You can configure OpenClaw to prioritize Claude Code CLI for code-related skills.

</details>

<details>
<summary>🔓 <strong>OpenAI OAuth (use your paid subscription instead of API credits)</strong></summary>

If you have a paid OpenAI account (ChatGPT Plus, Pro, or Team), you can connect via **OAuth** instead of an API key. This means usage is deducted from your subscription allowance rather than billed separately through the API — which can be significantly cheaper or even free depending on your plan.

During onboarding, select **OpenAI** as your provider and choose the **OAuth** login method. OpenClaw will open a browser-based login flow. Once authenticated, your OpenAI models (like `gpt-4o`) will use your subscription quota.

> **Note:** OpenAI is currently the only provider tested with OAuth. Other providers use API keys.
>
> **Tip:** You can combine providers — for example, use OpenAI OAuth for GPT models and a separate API key for Claude or Gemini models. Configure fallback models in `./data/config/openclaw.json` under `agents.defaults.model`.

</details>

### 💸 Keeping costs under control

- **Monitor your API usage** through your provider's dashboard (e.g. [OpenAI Platform](https://platform.openai.com/), [Anthropic Console](https://console.anthropic.com/), [Google AI Studio](https://aistudio.google.com/)). Set spending alerts and budget limits before going live.
- **Set a monthly budget limit** with your API provider to avoid surprises.
- **Minimize context size.** Only load documents and files when they're actually needed.
- **Longer conversations cost more.** Each message includes the full history — consider restarting conversations when the topic changes.
- **Use text-to-speech sparingly.** Configure it to only generate audio when the user sends a voice message.
- **Skills and tools add cost.** Browser automation and other skills generate extra API calls.
- **Test in low-traffic environments first.** Test with one or two users before connecting a busy group chat.

### Changing your model

```bash
docker compose exec openclaw-gateway node dist/index.js configure
```

Or edit the configuration file directly at `./data/config/openclaw.json`.

---

## 🔍 Add-ons

Optional guides for extending your OpenClaw instance with additional services:

| Add-on | Description |
| --- | --- |
| 🔎 [SearXNG Setup](docs/SEARXNG-SETUP.md) | Add private, self-hosted web search (70+ engines including Google, Bing, DuckDuckGo) with optional darkweb search via Tor |

---

## 📁 File Overview

| File                    | Description                                                          |
| ----------------------- | -------------------------------------------------------------------- |
| `docker-compose.yaml` | 🐳 Defines the gateway and CLI services with security hardening      |
| `Dockerfile`          | 📦 Extends the official OpenClaw image with Chromium browser support |
| `.env.example`        | 🔑 Template for environment variables                                |
| `setup.sh`            | 🚀 Automated setup script with security auditing (run once)          |
| `personalize.sh`      | 🎨 Agent personalization wizard (run after setup)                     |
| `.dockerignore`       | 🚫 Prevents secrets from leaking into the Docker build               |
| `docs/`               | 📖 Additional guides (SearXNG setup, security policy, personalization) |

---

## 💾 Data & Backups

All persistent data is stored in the `./data/` directory:

```
data/
├── config/       # OpenClaw configuration, API keys, memory
├── config-cli/   # Minimal config for the CLI container (auto-created by setup.sh)
└── workspace/    # Files created by the AI assistant
```

**To back up your instance**, simply copy the entire `data/` directory:

```bash
cp -r ./data ./data-backup-$(date +%Y%m%d)
```

**To restore**, stop the server, replace the `data/` directory with your backup, and start again.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) — free to use, modify and distribute.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/MadeByAdem">MadeByAdem</a>
</p>
