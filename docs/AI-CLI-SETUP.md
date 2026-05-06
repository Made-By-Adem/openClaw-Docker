# CLI Setup — Claude, Gemini & GitHub

This Docker image includes three CLI tools out of the box. Each needs a one-time login — after that, sessions are persisted in mounted volumes and survive container restarts.

| CLI | Purpose | Login persisted in |
| --- | --- | --- |
| **Claude Code CLI** | Anthropic model auth (no API key needed) | `./data/claude-cli/` |
| **Gemini CLI** | Google model auth (no API key needed) | `./data/gemini-cli/` |
| **GitHub CLI** (`gh`) | Push code, create PRs, manage repos | `./data/github-cli/` |

---

## 1. Claude Code CLI (Anthropic)

Allows OpenClaw to use Claude models without an API key — select **"Reuse a local CLI login"** during onboarding.

### Login

```bash
docker compose exec openclaw-gateway claude
```

Claude Code starts interactively. Follow the prompts:

1. You get a URL and a one-time code
2. Open the URL in any browser (phone, laptop — doesn't have to be on the server)
3. Paste the code and confirm
4. Back in the terminal, Claude Code confirms the login
5. Exit with `/exit` or `Ctrl+C`

### Verify

```bash
docker compose exec openclaw-gateway claude --version
```

### Use in OpenClaw

During onboarding or reconfiguration:

```bash
docker compose exec openclaw-gateway node dist/index.js configure
```

Navigate to **Model → Anthropic → Anthropic Claude CLI**.

---

## 2. Gemini CLI (Google)

Allows OpenClaw to use Gemini models without an API key.

### Login

The Gemini CLI has no `auth` subcommand — auth happens on first interactive launch.

```bash
docker compose exec -it openclaw-gateway gemini
```

On first run you get an auth picker:

1. Choose **"Login with Google"**
2. A URL + one-time code is printed
3. Open the URL in any browser, paste the code, approve
4. The REPL confirms you're authenticated
5. Exit with `/quit` (or `Ctrl+C`)

Credentials are stored in `~/.gemini/` inside the container, persisted via the `./data/gemini-cli` volume.

### Verify

Re-launch the REPL — if it skips the auth picker and goes straight to the prompt, you're logged in:

```bash
docker compose exec -it openclaw-gateway gemini
```

To switch auth method later, type `/auth` from inside the REPL.

### Use in OpenClaw

During onboarding or reconfiguration, navigate to **Model → Google → Gemini CLI**.

---

## 3. GitHub CLI (`gh`)

Allows the developer agent to clone repos, push code, and create PRs.

### Login

```bash
docker compose exec openclaw-gateway gh auth login
```

You'll be asked:

1. **Account:** GitHub.com
2. **Protocol:** HTTPS
3. **Authenticate:** Login with a web browser

You'll get a one-time code and a URL. Open the URL on any device, paste the code, and authorize.

**Alternative — token-based (headless servers):**

Create a Personal Access Token at [github.com/settings/tokens](https://github.com/settings/tokens) with scopes `repo` and `workflow`, then:

```bash
docker compose exec openclaw-gateway gh auth login --with-token <<< "ghp_your_token_here"
```

### Configure git

```bash
docker compose exec openclaw-gateway git config --global user.name "Your Name"
docker compose exec openclaw-gateway git config --global user.email "you@example.com"
```

Git config is persisted in `./data/gitconfig`.

### Verify

```bash
docker compose exec openclaw-gateway gh auth status
docker compose exec openclaw-gateway git config --global --list
```

### Working with projects

Projects live in `./data/workspace/projects/` on the host (mounted at `~/.openclaw/workspace/projects/` in the container, alongside the rest of the workspace).

```bash
# Clone a repo via the container
docker compose exec openclaw-gateway sh -c "cd ~/.openclaw/workspace/projects && gh repo clone owner/repo"

# Or copy an existing project from the host
cp -r /path/to/my-project ./data/workspace/projects/
```

The developer agent automatically works in `~/.openclaw/workspace/projects/` — it will create branches, commit, and push via `gh`.

---

## Select CLI auth during onboarding

### New installation

During the onboarding wizard, when asked for your AI provider:

1. Select your provider (e.g. **Anthropic** or **Google**)
2. Choose **"Reuse a local CLI login"** as the auth method
3. The wizard verifies the CLI login and proceeds

### Existing installation

```bash
docker compose exec openclaw-gateway node dist/index.js configure
```

Navigate to the model/auth settings and switch to CLI-based authentication.

---

## Using multiple providers

You can authenticate with both Claude CLI and Gemini CLI. Configure your preferred model in `./data/config/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "model": "anthropic/claude-sonnet-4-5"
    }
  }
}
```

Switch between providers via the configuration wizard or by editing the file directly.

---

## Troubleshooting

### "Command not found: claude", "gemini", or "gh"

The Docker image may be outdated. Rebuild:

```bash
docker compose build --no-cache
docker compose down && docker compose up -d
```

### "Not authenticated" during onboarding

Run the CLI login first (sections 1, 2, or 3 above), then re-run onboarding or configure.

### Auth session expired

Re-run the login command for the affected CLI:

```bash
docker compose exec -it openclaw-gateway claude     # Claude
docker compose exec -it openclaw-gateway gemini     # Gemini (re-runs auth picker if session expired)
docker compose exec openclaw-gateway gh auth login  # GitHub
```

### Permission errors on auth directories

The directories must be owned by uid 1000 (the `node` user inside the container):

```bash
sudo chown -R 1000:1000 ./data/claude-cli ./data/gemini-cli ./data/github-cli ./data/workspace/projects
```

---

## Security notes

- Auth sessions are stored in `./data/claude-cli/`, `./data/gemini-cli/`, and `./data/github-cli/`. Treat these like credentials — restrict access and never commit to git.
- The `.dockerignore` file excludes `data/` from the Docker build context.
- Rotate sessions periodically by re-running the login commands.
- To revoke a compromised session:
  - Claude: [Anthropic Console](https://console.anthropic.com/)
  - Gemini: [Google Account Permissions](https://myaccount.google.com/permissions)
  - GitHub: [GitHub Settings > Applications](https://github.com/settings/applications)
