# 🎨 Personalization

Make your AI agent *yours*. Run `personalize.sh` after setup to configure your agent's identity, personality, and behavior through a series of workspace files.

```bash
./personalize.sh
```

---

## 📁 The Files

### 🪪 `IDENTITY.md` — Who your agent is

Name, emoji, roles, primary language, and self-introduction. This is the first thing your agent reads to understand *what* it is.

### 💠 `SOUL.md` — How your agent thinks

Core values and communication style. Shapes the personality — casual or formal, sarcastic or supportive, opinionated or neutral. This is the *character* behind the responses.

### 👤 `USER.md` — Who you are

Your name, timezone, language, and communication preferences. The more context you give, the better your agent can adapt. Add family members, colleagues, or anyone else the agent should know about.

### 🤖 `AGENTS.md` — How your agent behaves

Operational rules — skill routing triggers, memory scope, audio/media rules, group chat behavior, and heartbeat protocol. Ships with sensible defaults — customize what matters to you.

### 📐 `CONVENTIONS.md` — Your project standards

Terminology, coding standards, git workflow, and branch naming conventions. Primarily useful if your agent helps with development work. Skip if you don't code.

### 🔧 `TOOLS.md` — Your local cheat sheet

Workspace structure map, available tools, TTS/audio rules, platform formatting notes, and per-skill quick reference (base URLs, credentials location, scripts path).

### 💓 `HEARTBEAT.md` — Periodic tasks

Define what your agent should check during heartbeat polls: unread emails, upcoming calendar events, weather, notifications. Leave empty to disable.

### 🧠 `MEMORY.md` — Long-term memory

Starts empty. Your agent fills this over time with things worth remembering across sessions. You can seed it with context you want the agent to always have.

---

## ⚙️ How the script works

For each file, you choose:

- **Edit** — opens your text editor (`$EDITOR`, or `nano`/`vim` fallback)
- **View example** — shows a working example based on a real agent config
- **Skip** — keeps the default template — edit later if you want

Files that need basic info (IDENTITY, SOUL, USER) ask a few quick questions first, then generate a template you can fine-tune in your editor.

After all files are configured, the script restarts OpenClaw automatically.

---

## ✍️ Editing later

All files live in `./data/workspace/`. Edit them anytime:

```bash
nano ./data/workspace/SOUL.md
docker compose restart openclaw-gateway
```

OpenClaw auto-injects these files into the agent's system prompt — changes take effect on the next conversation.

---

## 📂 Workspace Directories

The setup script also creates these directories in your workspace:

| Directory | Purpose |
| --- | --- |
| `skills/` | Custom skills — each skill has its own folder with a `SKILL.md` contract |
| `secrets/` | Credentials per skill (`.env` files, never committed to git) |
| `memory/` | Daily session logs (`YYYY-MM-DD.md`, written by the agent) |
| `files/` | Reference library (PDFs, exports) |
| `docs/` | Large documents (loaded only on request) |
| `tmp/` | Working files, intermediate results |

For the full workspace architecture and file conventions, see [Workspace Architecture](WORKSPACE-ARCHITECTURE.md). For creating custom skills, see [Skill Development](SKILL-DEVELOPMENT.md).
