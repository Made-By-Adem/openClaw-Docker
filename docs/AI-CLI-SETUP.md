# AI CLI Setup — Authenticate Without an API Key

Instead of entering an API key during onboarding, you can authenticate using the **Claude Code CLI** (Anthropic) or **Gemini CLI** (Google). The CLI tools reuse your existing login session, so you don't need to create or manage separate API keys.

> **When to use this:** You already have a Claude or Gemini account and want to skip API key management. During onboarding, you select your provider and choose **"Reuse a local CLI login"** as the auth method (see screenshot below).

---

## Supported CLIs

| CLI | Provider | Models | npm Package |
| --- | --- | --- | --- |
| Claude Code CLI | Anthropic | `anthropic/claude-opus-4-5`, `anthropic/claude-sonnet-4-5`, `anthropic/claude-haiku-4-5` | `@anthropic-ai/claude-code` |
| Gemini CLI | Google | `google/gemini-2.5-pro`, `google/gemini-2.5-flash`, etc. | `@google/gemini-cli` |

---

## Step 1 — Enable AI CLI in the Docker image

The CLI tools are not installed by default. Enable them by setting `INSTALL_AI_CLI=true` in your `.env` file before building.

**New installation (before running `setup.sh`):**

```bash
# Edit .env.example or create .env
echo "INSTALL_AI_CLI=true" >> .env
```

Then run `setup.sh` as normal — it will build the image with the CLI tools included.

**Existing installation:**

```bash
# 1. Add the flag to your .env
echo "INSTALL_AI_CLI=true" >> .env

# 2. Rebuild the Docker image
docker compose build --no-cache

# 3. Restart
docker compose down && docker compose up -d
```

---

## Step 2 — Authenticate with Claude Code CLI

Run the Claude CLI inside the container to start the login flow:

```bash
docker compose exec openclaw-gateway claude auth login
```

This opens a browser-based authentication flow. Follow the prompts to log in with your Anthropic account.

> **Headless server?** If you don't have a browser on the server, the CLI will print a URL. Open it on any device, complete the login, and paste the code back into the terminal.

Verify the login:

```bash
docker compose exec openclaw-gateway claude auth status
```

---

## Step 3 — Authenticate with Gemini CLI

Run the Gemini CLI inside the container:

```bash
docker compose exec openclaw-gateway gemini auth login
```

Follow the browser-based login flow to authenticate with your Google account.

Verify the login:

```bash
docker compose exec openclaw-gateway gemini auth status
```

---

## Step 4 — Select CLI auth during onboarding or configuration

### New installation

During the onboarding wizard, when asked for your AI provider:

1. Select your provider (e.g. **Anthropic** or **Google**)
2. Choose **"Reuse a local CLI login"** (or **"Anthropic Claude CLI"** / **"Gemini CLI"**) as the auth method
3. The wizard will verify the CLI login and proceed

### Existing installation

Re-run the configuration wizard:

```bash
docker compose exec openclaw-gateway node dist/index.js configure
```

Navigate to the model/auth settings and switch to CLI-based authentication.

---

## How it works

When you select CLI auth, OpenClaw delegates authentication to the installed CLI tool instead of using a raw API key. The CLI manages token refresh and session persistence automatically.

```
User message → OpenClaw gateway → CLI auth layer → Provider API (Anthropic/Google)
```

**Auth persistence:** The CLI login sessions are stored in mounted volumes (`./data/claude-cli/` and `./data/gemini-cli/`), so they persist across container restarts. You only need to authenticate once.

---

## Using both providers

You can install and authenticate with both CLIs simultaneously. Configure OpenClaw to use one as the primary model and the other as a fallback:

```json
{
  "agents": {
    "defaults": {
      "model": "anthropic/claude-sonnet-4-5"
    }
  }
}
```

Switch between providers by changing the model in `./data/config/openclaw.json` or via the configuration wizard.

---

## Troubleshooting

### "Command not found: claude" or "Command not found: gemini"

The CLI tools are not installed. Make sure `INSTALL_AI_CLI=true` is set in your `.env` file and rebuild:

```bash
docker compose build --no-cache
docker compose down && docker compose up -d
```

### "Not authenticated" during onboarding

Run the CLI auth command first (Step 2 or 3 above), then re-run onboarding or configure.

### Auth session expired

Re-run the login command:

```bash
# Claude
docker compose exec openclaw-gateway claude auth login

# Gemini
docker compose exec openclaw-gateway gemini auth login
```

### Permission errors on auth directories

The CLI auth directories must be owned by uid 1000 (the `node` user inside the container):

```bash
sudo chown -R 1000:1000 ./data/claude-cli ./data/gemini-cli
```

---

## Security notes

- CLI auth tokens are stored in `./data/claude-cli/` and `./data/gemini-cli/`. Treat these directories like API keys — restrict access and never commit them to git.
- The `.dockerignore` file already excludes `data/` from the Docker build context.
- Rotate CLI sessions periodically by re-running the login commands.
- If you suspect a session is compromised, revoke it from your provider's account settings ([Anthropic Console](https://console.anthropic.com/), [Google Account](https://myaccount.google.com/permissions)) and re-authenticate.
