#!/usr/bin/env bash
set -euo pipefail

# ============================================
# OpenClaw Docker Setup
# ============================================

echo "=== OpenClaw Docker Setup ==="
echo ""

# --- Check Docker is available ---
if ! command -v docker &>/dev/null; then
  echo "ERROR: Docker is not installed."
  echo "Install Docker first: https://docs.docker.com/engine/install/"
  exit 1
fi

if ! docker compose version &>/dev/null; then
  echo "ERROR: Docker Compose v2 is not available."
  echo "Install Docker Compose: https://docs.docker.com/compose/install/"
  exit 1
fi

echo "[OK] Docker and Docker Compose found"

# --- Create data directories ---
mkdir -p ./data/config
mkdir -p ./data/workspace
mkdir -p ./data/workspace/skills
mkdir -p ./data/workspace/secrets
mkdir -p ./data/workspace/memory
mkdir -p ./data/workspace/files
mkdir -p ./data/workspace/tmp
mkdir -p ./data/workspace/docs

# AI CLI and developer tool directories (persist sessions across container restarts)
mkdir -p ./data/claude-cli
mkdir -p ./data/gemini-cli
mkdir -p ./data/github-cli
mkdir -p ./data/workspace/projects
touch ./data/gitconfig

# Install default skill templates (audio TTS/STT, etc.)
if [ -d "./templates/skills" ]; then
  for skill_dir in ./templates/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    [ "$skill_name" = "_template" ] && continue
    if [ ! -d "./data/workspace/skills/$skill_name" ]; then
      cp -r "$skill_dir" "./data/workspace/skills/$skill_name"
      echo "[OK] Installed skill: $skill_name"
    fi
  done
fi

# Protect secrets directory — ensure .env files are never committed
if [ ! -f "./data/workspace/secrets/.gitignore" ]; then
  printf '# Never commit secrets\n*.env\n!.gitignore\n' > ./data/workspace/secrets/.gitignore
fi

# Ensure the node user (uid 1000) has write permissions
chown -R 1000:1000 ./data 2>/dev/null || {
  echo "[!]  Could not change ownership to uid 1000."
  echo "     Run this script as root, or manually run:"
  echo "     sudo chown -R 1000:1000 ./data"
}

echo "[OK] Data directories created (config, workspace, skills, secrets, memory, files, tmp, docs)"

# --- Create .env from template if it doesn't exist ---
ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  if [ -f ".env.example" ]; then
    cp .env.example "$ENV_FILE"
    echo "[OK] Created .env from .env.example"
  else
    echo "ERROR: No .env or .env.example found."
    exit 1
  fi
fi

# Restrict .env permissions — only the file owner can read/write
chmod 600 "$ENV_FILE"

CURRENT_TOKEN=$(grep -oP '(?<=OPENCLAW_GATEWAY_TOKEN=).+' "$ENV_FILE" 2>/dev/null || true)

if [ -z "$CURRENT_TOKEN" ]; then
  TOKEN=$(openssl rand -hex 32 2>/dev/null || python3 -c "import secrets; print(secrets.token_hex(32))")
  sed -i "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=${TOKEN}/" "$ENV_FILE"
  echo "[OK] Gateway token generated and stored in .env"
else
  TOKEN="$CURRENT_TOKEN"
  echo "[OK] Gateway token already exists"
fi

# --- Create data/config/.env for OpenClaw env var substitution ---
# OpenClaw reads ~/.openclaw/.env inside the container, which maps to ./data/config/.env
CONFIG_ENV_FILE="${OPENCLAW_CONFIG_DIR:-./data/config}/.env"

if [ ! -f "$CONFIG_ENV_FILE" ]; then
  cat > "$CONFIG_ENV_FILE" << EOF
# OpenClaw environment variables
# Referenced as \${VAR_NAME} in openclaw.json
GATEWAY_TOKEN=${TOKEN}
EOF
  echo "[OK] Created $CONFIG_ENV_FILE with gateway token"
else
  # Ensure the gateway token is synced
  if grep -q "^GATEWAY_TOKEN=" "$CONFIG_ENV_FILE" 2>/dev/null; then
    sed -i "s/^GATEWAY_TOKEN=.*/GATEWAY_TOKEN=${TOKEN}/" "$CONFIG_ENV_FILE"
  else
    echo "GATEWAY_TOKEN=${TOKEN}" >> "$CONFIG_ENV_FILE"
  fi
  echo "[OK] $CONFIG_ENV_FILE already exists — gateway token synced"
fi

# Always enforce correct ownership and permissions
# The node user (uid 1000) inside the container must be able to read this file
chown 1000:1000 "$CONFIG_ENV_FILE" 2>/dev/null || {
  echo "[!]  Could not change ownership of $CONFIG_ENV_FILE to uid 1000."
  echo "     Run: sudo chown 1000:1000 $CONFIG_ENV_FILE"
}
chmod 600 "$CONFIG_ENV_FILE"

# --- Create CLI config directory ---
# The CLI container uses a separate minimal config to avoid bind/networking conflicts
CLI_CONFIG_DIR="./data/config-cli"
mkdir -p "$CLI_CONFIG_DIR"
if [ ! -f "$CLI_CONFIG_DIR/openclaw.json" ]; then
  cat > "$CLI_CONFIG_DIR/openclaw.json" << 'CLIEOF'
{
  "gateway": {
    "port": 18789,
    "mode": "local"
  }
}
CLIEOF
  chown 1000:1000 "$CLI_CONFIG_DIR/openclaw.json" 2>/dev/null || true
  echo "[OK] Created CLI config at $CLI_CONFIG_DIR/openclaw.json"
else
  echo "[OK] CLI config already exists"
fi
chown -R 1000:1000 "$CLI_CONFIG_DIR" 2>/dev/null || true

# --- Build custom image ---
echo ""
echo "Building custom image..."
docker compose build
echo "[OK] Image built"

# --- Onboarding ---
echo ""
echo "Starting onboarding..."
echo "(Follow the steps to configure your AI provider and channels)"
echo ""
docker compose run --rm openclaw-cli onboard

# --- Patch openclaw.json for Docker networking + dashboard access ---
CONFIG_FILE="${OPENCLAW_CONFIG_DIR:-./data/config}/openclaw.json"
GATEWAY_TOKEN=$(grep -oP '(?<=OPENCLAW_GATEWAY_TOKEN=).+' "$ENV_FILE")

if [ -f "$CONFIG_FILE" ]; then
  # Detect Docker subnets dynamically (bridge + compose network)
  DOCKER_BRIDGE_SUBNET=$(docker network inspect bridge --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null || echo "172.17.0.0/16")
  COMPOSE_NET_SUBNET=$(docker network inspect openclaw_openclaw-net --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null \
    || docker network inspect openclaw-net --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null \
    || echo "")

  # Pass variables via environment to avoid shell-in-Python injection
  OC_CONFIG_FILE="$CONFIG_FILE" \
  OC_GATEWAY_TOKEN="$GATEWAY_TOKEN" \
  OC_DOCKER_BRIDGE_SUBNET="$DOCKER_BRIDGE_SUBNET" \
  OC_COMPOSE_NET_SUBNET="$COMPOSE_NET_SUBNET" \
  OC_ALLOW_INSECURE_AUTH="${OPENCLAW_ALLOW_INSECURE_AUTH:-false}" \
  python3 -c "
import json, os

config_file = os.environ['OC_CONFIG_FILE']
gateway_token = os.environ['OC_GATEWAY_TOKEN']
bridge_subnet = os.environ['OC_DOCKER_BRIDGE_SUBNET']
compose_subnet = os.environ.get('OC_COMPOSE_NET_SUBNET', '')

with open(config_file) as f:
    cfg = json.load(f)

gw = cfg.setdefault('gateway', {})

# Bind to LAN so Docker port-forwarding works (loopback blocks it)
gw['bind'] = 'lan'

# Mode must be 'local' — gateway refuses to start without it
gw['mode'] = 'local'

# Replace plaintext token with env var reference
# The actual value is stored in data/config/.env and resolved at startup
gw.setdefault('auth', {})['token'] = '\${GATEWAY_TOKEN}'

# Trust Docker networks (bridge + compose network, detected dynamically)
trusted = [bridge_subnet]
if compose_subnet:
    trusted.append(compose_subnet)
gw['trustedProxies'] = trusted

# Dashboard auth over HTTP — disabled by default for security.
# Only enable via OPENCLAW_ALLOW_INSECURE_AUTH=true if behind a TLS-terminating reverse proxy.
allow_insecure = os.environ.get('OC_ALLOW_INSECURE_AUTH', 'false').lower() == 'true'
gw['controlUi'] = {'allowInsecureAuth': allow_insecure}

# Disable mDNS broadcast (not needed in Docker, leaks info)
cfg.setdefault('discovery', {}).setdefault('mdns', {})['mode'] = 'off'

# --- Session isolation ---
# Each sender gets their own isolated session (prevents cross-user context leakage)
cfg.setdefault('session', {})['dmScope'] = 'per-channel-peer'

# --- Tool restrictions ---
tools = cfg.setdefault('tools', {})

# Block session hijacking tools
tools['deny'] = ['sessions_spawn', 'sessions_send']

# Allow command execution (for custom scripts in ~/.openclaw/scripts/)
tools.setdefault('exec', {})['security'] = 'full'

# Restrict filesystem access to workspace only
tools.setdefault('fs', {})['workspaceOnly'] = True

# --- SSRF protection ---
# Block browser access to private/internal networks
cfg.setdefault('browser', {}).setdefault('ssrfPolicy', {})['dangerouslyAllowPrivateNetwork'] = False

# --- Logging ---
# Redact sensitive data (tokens, keys) from logs
cfg.setdefault('logging', {})['redactSensitive'] = 'tools'

with open(config_file, 'w') as f:
    json.dump(cfg, f, indent=2)
" && echo "[OK] Gateway config patched (networking, auth, session isolation, tool restrictions, SSRF protection)" \
  || echo "[!]  Could not patch gateway config. You may need to edit openclaw.json manually."
else
  echo "[!]  Config file not found at $CONFIG_FILE — skipping gateway patch."
  echo "     The onboarding wizard may not have created it yet."
fi

# --- Start the gateway ---
echo ""
echo "Starting gateway..."
docker compose up -d openclaw-gateway

# --- Run security checks ---
echo ""
echo "Running security checks..."
echo "Waiting for gateway to start..."
sleep 10

docker compose exec openclaw-gateway node dist/index.js doctor --repair 2>/dev/null \
  && echo "[OK] Doctor check passed" \
  || echo "[!]  Doctor check encountered issues — review the output above"

docker compose exec openclaw-gateway node dist/index.js security audit --deep 2>/dev/null \
  && echo "[OK] Security audit passed" \
  || echo "[!]  Security audit found issues — review the output above"

echo ""
echo "============================================"
echo " OpenClaw is running on 127.0.0.1:18789"
echo "============================================"
echo ""
echo " Your gateway token is stored in .env"
echo " Open the dashboard:  http://127.0.0.1:18789"
echo " (append /#token=YOUR_TOKEN — find the token in your .env file)"
echo ""
echo "--------------------------------------------"
echo " NEXT STEPS"
echo "--------------------------------------------"
echo ""
echo " 1. Personalize your agent (give it a name, personality, and context):"
echo "    chmod +x personalize.sh && ./personalize.sh"
echo ""
echo " 2. Set up agent personas (developer, assistant, marketeer):"
echo "    chmod +x agents.sh && ./agents.sh init"
echo "    Your agent will switch roles automatically based on the task."
echo "    See docs/AGENTS-GUIDE.md for details."
echo ""
echo " 3. Add a messaging channel:"
echo "    docker compose exec openclaw-gateway node dist/index.js plugins enable whatsapp"
echo "    docker compose exec openclaw-gateway node dist/index.js channels login --channel whatsapp"
echo ""
echo "--------------------------------------------"
echo " USEFUL COMMANDS"
echo "--------------------------------------------"
echo ""
echo "   docker compose logs -f openclaw-gateway    # View logs"
echo "   docker compose down                        # Stop"
echo "   docker compose up -d                       # Start"
echo "   docker compose restart openclaw-gateway    # Restart after config changes"
echo ""
echo " Run CLI commands (gateway must be running):"
echo "   docker compose exec openclaw-gateway node dist/index.js <command>"
echo ""
echo " Channels:"
echo "   docker compose exec openclaw-gateway node dist/index.js channels login --channel whatsapp           # WhatsApp (scan QR)"
echo "   docker compose exec openclaw-gateway node dist/index.js channels add --channel telegram --token T   # Telegram"
echo "   docker compose exec openclaw-gateway node dist/index.js channels add --channel discord --token T    # Discord"
echo ""
echo " Security:"
echo "   docker compose exec openclaw-gateway node dist/index.js doctor --repair          # Check & fix config issues"
echo "   docker compose exec openclaw-gateway node dist/index.js security audit --deep    # Deep security audit"
echo ""
echo " Token rotation (recommended periodically):"
echo "   1. Generate a new token:  openssl rand -hex 32"
echo "   2. Update .env with the new token"
echo "   3. Update data/config/.env with the new token"
echo "   4. Restart:  docker compose restart openclaw-gateway"
echo ""
echo " Documentation:"
echo "   docs/WORKSPACE-ARCHITECTURE.md   # How workspace files work"
echo "   docs/SKILL-DEVELOPMENT.md        # Create custom skills"
echo "   docs/AGENTS-GUIDE.md             # Multi-agent personas"
echo "   docs/SECURITY.md                 # Security hardening"
echo ""
echo " Remote dashboard (via reverse proxy):"
echo "   See README.md for reverse proxy and security setup."
echo "============================================"
