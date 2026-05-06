# Multi-Agent Guide

## Why Use Personas?

Without personas, your AI agent handles every task the same way — same tone, same approach, same level of detail. That works fine for simple setups, but as you use it more, you'll notice:

- A code review needs a different tone than a calendar reminder
- Writing a social media post requires a different workflow than debugging a server
- Some tasks need strict rules ("never push to main") while others need creativity

Personas solve this. Each persona is a **specialized role** with its own triggers, workflow, communication style, and rules. Your agent reads the task, picks the right persona, and switches automatically.

**Benefits:**

- **Better output quality** — each persona is optimized for its task type
- **Consistent behavior** — the developer persona always follows your git conventions, the assistant always checks your timezone
- **Less repetition** — you don't need to remind the agent "be technical" or "be creative" every time
- **Easy to customize** — personas are just markdown files, edit them anytime

## What Multi-Agent Means

OpenClaw runs as a single instance. Multi-agent is not multiple processes — it's one AI that reads persona definitions from your workspace and switches roles based on the task. Think of it as one person wearing different hats.

```
┌─────────────────────────────────┐
│       OpenClaw Instance         │
│                                 │
│  ┌───────────┐                  │
│  │Orchestrator│ ← main identity │
│  └─────┬─────┘                  │
│        │ delegates to           │
│  ┌─────┴──────────────────┐     │
│  │  agents/               │     │
│  │  ├── developer.md      │     │
│  │  ├── assistant.md      │     │
│  │  └── marketeer.md      │     │
│  └────────────────────────┘     │
└─────────────────────────────────┘
```

The **orchestrator** (defined in IDENTITY.md and AGENTS.md) reads incoming messages, matches them against persona activation triggers, loads the matching persona file, and adopts that role.

## Quick Start

```bash
# 1. Install persona templates
chmod +x agents.sh
./agents.sh init

# 2. (Optional) Create a custom persona
./agents.sh add researcher

# 3. Edit personas to match your needs
nano ./data/workspace/agents/developer.md

# 4. Restart to apply
docker compose restart openclaw-gateway
```

## Included Personas

| Persona | File | Activates when |
|---------|------|----------------|
| **Developer** | `agents/developer.md` | Code, PRs, bugs, debugging, architecture |
| **Assistant** | `agents/assistant.md` | Email, calendar, reminders, research, daily tasks |
| **Marketeer** | `agents/marketeer.md` | Content, social media, copywriting, campaigns |

## Managing Personas

Use the `agents.sh` script:

```bash
./agents.sh init                    # Install default personas from templates
./agents.sh list                    # Show installed personas
./agents.sh add <name> [template]   # Create new persona (from blank or named template)
./agents.sh remove <name>           # Remove a persona
./agents.sh templates               # Show available templates
```

Examples:
```bash
./agents.sh add support assistant   # New "support" persona based on assistant template
./agents.sh add researcher          # New persona from blank template
./agents.sh remove marketeer        # Remove if you don't need it
```

## Creating a Custom Persona

1. Start from the blank template:
   ```bash
   ./agents.sh add my-agent
   ```

2. Edit `./data/workspace/agents/my-agent.md` — fill in:
   - **Role** — what this persona does (1-2 sentences)
   - **When to Activate** — trigger conditions (keywords, topics, situations)
   - **Tools** — what tools this persona uses
   - **Workflow** — step-by-step for typical tasks
   - **Communication Style** — how this persona communicates
   - **Rules** — constraints and guardrails

3. Update `AGENTS.md` — add the persona to the delegation table:
   ```markdown
   | Task type | Persona | File |
   |-----------|---------|------|
   | My task | My Agent | `agents/my-agent.md` |
   ```

4. Restart:
   ```bash
   docker compose restart openclaw-gateway
   ```

## How Personas Work

When the agent receives a message:

1. **Match** — check the task against persona activation triggers (defined in each persona file + AGENTS.md routing table)
2. **Load** — read the matching persona file from `agents/`
3. **Adopt** — use that persona's workflow, communication style, and rules
4. **Execute** — handle the task
5. **Return** — switch back to orchestrator mode when done

### Rules

- **One persona at a time** — don't mix communication styles mid-conversation
- **No match = orchestrator** — if no persona matches, handle it directly
- **Multi-persona tasks** — break into sub-tasks, handle each with the right persona
- **Log switches** — note persona changes in daily memory for continuity

## Developer Agent Setup

The developer persona uses git, GitHub CLI (`gh`), and Claude Code CLI for coding tasks. All tools are installed in the Docker image by default.

Projects live in `./data/projects/` on the host, mounted at `~/projects/` inside the container. You can place project folders there manually or let the agent clone repos.

### 1. Configure git

```bash
docker compose exec openclaw-gateway git config --global user.name "Your Name"
docker compose exec openclaw-gateway git config --global user.email "you@example.com"
```

Your git config is persisted in `./data/gitconfig`.

### 2. Authenticate with GitHub

```bash
docker compose exec openclaw-gateway gh auth login
```

Follow the interactive login flow. Your session is persisted in `./data/github-cli/`.

Verify:
```bash
docker compose exec openclaw-gateway gh auth status
```

### 3. Add projects

Place existing project folders in `./data/projects/`, or let the agent clone them:

```bash
# From the host
cp -r /path/to/my-project ./data/projects/

# Or let the agent clone inside the container
docker compose exec openclaw-gateway sh -c "cd ~/projects && gh repo clone owner/repo"
```

The agent will work in `~/projects/<project-name>/`, create branches, commit, and push via `gh`.

## Voice & Audio Handling

All personas can handle voice messages using the built-in audio skill. The skill is installed automatically during setup at `skills/audio/SKILL.md`.

**How it works:**

1. User sends a voice message → OpenClaw saves the audio file
2. The agent loads `skills/audio/SKILL.md` and transcribes with `stt.py` (faster-whisper, local)
3. The agent processes the transcribed text as normal
4. The agent replies with audio via `tts.py` (edge-tts, local) — **audio in → audio out**

**Key commands:**
```bash
# Transcribe incoming voice
python3 /opt/ai-tools/bin/stt.py <audio_file> --language nl

# Reply with audio
python3 /opt/ai-tools/bin/tts.py "antwoord tekst" /tmp/reply.mp3
```

No external APIs, no costs. Both STT and TTS run entirely inside the container.

> **Important:** The audio skill routing must be active in `AGENTS.md` (not commented out) for this to work. The `personalize.sh` script configures this by default. If voice replies aren't working, check that `AGENTS.md` includes the audio skill in the routing table and that `skills/audio/SKILL.md` exists in the workspace.

## Workspace Structure with Personas

```
workspace/
├── IDENTITY.md          # Orchestrator identity (includes orchestrator role)
├── AGENTS.md            # Delegation rules + skill routing
├── agents/              # Persona definitions
│   ├── developer.md
│   ├── assistant.md
│   └── marketeer.md
├── skills/              # Skills (available to all personas)
│   └── weather/
├── secrets/             # Credentials
└── memory/              # Shared memory across personas
```

Personas and skills are complementary:
- **Personas** define *who* handles a task (role, style, workflow)
- **Skills** define *how* to interact with a service (API calls, scripts, credentials)

A persona can use multiple skills. For example, the assistant persona might use the email skill, calendar skill, and weather skill.

## Tips

- **Start simple** — install the default personas, try them, then customize
- **Keep personas focused** — a persona that does everything is just your main agent with extra steps
- **Persona files are short** — 30-50 lines is enough. The value is in clear triggers and rules, not lengthy descriptions
- **Test with real tasks** — send messages that should trigger each persona and verify the right one activates
