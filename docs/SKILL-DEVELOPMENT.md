# Skill Development Guide

How to create, structure, and maintain skills for your openClaw workspace.

## Quick Start

1. Copy the template: `cp -r templates/skills/_template/ data/workspace/skills/<your-skill>/`
2. Edit `SKILL.md` — fill in all sections
3. Add credentials to `data/workspace/secrets/<your-skill>.env`
4. Add trigger words to both `SKILL.md` frontmatter AND `AGENTS.md` Skill Routing section
5. Restart: `docker compose restart openclaw-gateway`

## Skill Folder Structure

```text
skills/<skill-name>/
├── SKILL.md             # The contract — everything the agent needs
├── scripts/             # Standalone executable scripts
│   └── <script>.sh      # Loads own config, does own HTTP calls
└── references/          # (optional) Deep docs, runbooks, API specs
    └── api-docs.md      # Large files — agent loads specific sections only
```

## SKILL.md Is the Contract

After reading SKILL.md, the agent must know EVERYTHING needed to use the skill. No implicit knowledge. No "read the runbook first." SKILL.md is the entry point — reference documents are for depth.

### Required Frontmatter

```yaml
---
name: my-skill
description: |
  What this skill does, including trigger words for matching.
  Example: "Home automation — lights, temperature, sensors, switches, scenes."
user-invocable: true
---
```

The `description` field is what OpenClaw's skill system uses for matching. Include all relevant trigger words.

### Required Sections

| Section | Purpose |
|---------|---------|
| **Role Activation** | What the agent does IMMEDIATELY when the skill loads |
| **Credentials & Auth** | Where credentials are, how to authenticate, required headers |
| **HTTP Method** | Which tool to use — explicitly state "ALWAYS curl via Bash" |
| **Request Templates** | Copy-paste ready curl examples for GET, POST, PUT, DELETE |
| **Error Handling** | Table: HTTP status → meaning → action |
| **Common Tasks** | Quick-reference table: task → first API call |
| **Safety Rules** | Summary of key constraints |
| **Escalation** | When to stop + format for escalation message |

### Optional Sections

| Section | When to include |
|---------|----------------|
| **Inline Knowledge** | Data needed on EVERY call (e.g., shop name mapping, required headers) |
| **Reference Navigation** | When you have large reference docs in `references/` |
| **Problem -> What to Load** | Mapping of common problems to specific reference sections |

## Scripts Must Be Standalone

A skill script does its own work. No thin wrappers that delegate to container-side scripts.

**Wrong:**
```bash
# Thin wrapper — breaks if container-side script changes
exec /home/node/.openclaw/scripts/ha.sh "$@"
```

**Right:**
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="${SCRIPT_DIR}/../../secrets/my-skill.env"

# Load credentials with fallback to env vars
if [[ -f "$SECRETS_FILE" ]]; then
  set -a; source "$SECRETS_FILE"; set +a
fi
: "${API_TOKEN:?API_TOKEN not set — create secrets/my-skill.env}"
: "${BASE_URL:?BASE_URL not set — add to secrets/my-skill.env}"

# Actual work
curl -sf -X GET "${BASE_URL}/api/items" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json"
```

### Script Rules

1. **Load own config** — source from `secrets/<skill>.env` with fallback to env vars
2. **Validate input** — check required args exist
3. **Make HTTP call** — use curl, not python urllib
4. **Format output** — return clean, parseable output
5. **No business logic** — text normalization, decision logic, context interpretation belong in SKILL.md instructions

## Secrets

One `.env` file per skill in `workspace/secrets/`:

```bash
# secrets/my-skill.env
API_TOKEN='your-token-here'
BASE_URL='https://api.example.com'
```

**Important:**
- Use single quotes in bash — API keys often contain `%`, `*`, `&`, `@`
- Never hardcode in scripts
- Never echo credentials in chat messages
- Never commit to git (`secrets/.gitignore` handles this)
- Scripts must handle missing credentials gracefully:

```bash
: "${API_TOKEN:?API_TOKEN not set — create secrets/my-skill.env}"
```

## Triggers: Dual Anchoring

Skill triggers live in TWO places — both must be consistent:

1. **SKILL.md frontmatter `description`** — what OpenClaw's skill system sees for matching
2. **AGENTS.md Skill Routing section** — what the agent reads as a decision rule

Example in AGENTS.md:
```markdown
| Trigger | Skill | Action |
|---------|-------|--------|
| "licht", "lamp", "thermostat", "sensor" | Home Assistant | Load `skills/ha/SKILL.md` |
```

Example in SKILL.md frontmatter:
```yaml
description: |
  Home automation — lights, lamps, temperature, thermostat, sensors, switches, scenes.
```

## Reference Documents

Large docs (runbooks, API specs, OpenAPI specs) go in `references/`. The SKILL.md contains a navigation table so the agent loads ONLY the relevant section:

```markdown
### Runbook sections (references/runbook.md — 2330 lines)

| Section | Lines | When to load |
|---------|-------|--------------|
| Safety & Autonomy | 7-167 | First time in session |
| Decision Trees | 1316-1622 | Troubleshooting flows |
| Standard Lookups | 1882-2330 | Data retrieval |
```

**Maintenance note:** When the reference document changes, update the line numbers in SKILL.md.

## No Bundled Binaries

Do not bundle binaries (jq, yq, etc.) in skill folders. Use what's available in the container:

- `curl` for HTTP
- `python3` for JSON parsing and validation
- `node` for complex logic

**Wrong:** `skills/ha/jq` (2.3 MB ELF binary)
**Right:** `python3 -c 'import json,sys; data=json.load(sys.stdin); print(data["result"])'`

## Force the Right HTTP Tool

SKILL.md must EXPLICITLY state which tool to use. Without this, the model sometimes picks Python urllib or WebFetch, causing issues with:

- Special characters in headers/credentials
- Cloudflare bot detection (User-Agent blocking)
- POST/PUT requests (WebFetch is GET-only)

Always include:
```markdown
## HTTP Method
Use **ALWAYS `curl` via Bash** for all API calls.
Use NEVER Python `urllib`, `requests`, or WebFetch.
```

## New Skill Checklist

- [ ] SKILL.md has frontmatter with `name`, `description` (including triggers), `user-invocable`
- [ ] SKILL.md has role activation instructions (what to do IMMEDIATELY)
- [ ] SKILL.md specifies HTTP method (curl/python/node — explicitly)
- [ ] SKILL.md has copy-paste ready request templates
- [ ] SKILL.md has error handling table
- [ ] SKILL.md has credentials location and required headers
- [ ] SKILL.md has navigation table for reference docs (if they exist)
- [ ] SKILL.md has "Problem -> What to Load" mapping (optional, recommended for complex skills)
- [ ] SKILL.md has inline knowledge needed on EVERY interaction (optional, if applicable)
- [ ] Triggers are in BOTH SKILL.md frontmatter AND AGENTS.md
- [ ] Scripts are standalone (no thin wrappers)
- [ ] Scripts load own secrets with fallback
- [ ] No bundled binaries
- [ ] Secrets are in `secrets/<skill>.env`, not in scripts
- [ ] Reference documents are in `references/`, not in SKILL.md body

## Examples

### Weather Skill (recommended starting point)

See `templates/skills/weather-example/` for a complete, working skill that demonstrates all conventions:

- **SKILL.md** — Full contract with frontmatter, curl templates, inline knowledge (coordinates, WMO codes), error handling
- **scripts/weather.sh** — Standalone script that fetches from Open-Meteo API and formats output with python3
- **No API key needed** — anyone can test this immediately

Test it:
```bash
bash templates/skills/weather-example/scripts/weather.sh 52.37 4.89           # current weather
bash templates/skills/weather-example/scripts/weather.sh 52.37 4.89 forecast  # 7-day forecast
```

To use it in your workspace:
```bash
cp -r templates/skills/weather-example/ data/workspace/skills/weather/
```

### Audio Skill

See `templates/skills/audio/SKILL.md` for a skill that uses local tools (no HTTP APIs). Useful as a reference for skills that wrap container-side utilities rather than external services.
