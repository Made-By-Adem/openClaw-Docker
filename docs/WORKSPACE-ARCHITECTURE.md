# Workspace Architecture Guide

This guide explains how openClaw workspaces are structured, what each file does, and the conventions to follow. It's written for operators setting up or maintaining an openClaw instance.

## How OpenClaw Uses Workspace Files

OpenClaw automatically injects workspace files into the AI's system prompt in this order:

```
AGENTS.md → SOUL.md → TOOLS.md → IDENTITY.md → USER.md → HEARTBEAT.md → MEMORY.md → CONVENTIONS.md (if present)
```

Each file has a specific role. Overlap between files wastes tokens and creates contradictions.

## File Responsibilities

| File | Contains | Does NOT Contain |
|------|----------|-----------------|
| **AGENTS.md** | Operational rules, skill routing triggers, audio/media rules, memory scope, group chat behavior, heartbeat protocol | Personality, tool details, who the user is |
| **SOUL.md** | Tone, values, boundaries, communication style | What the agent does, operational workflows, roles |
| **IDENTITY.md** | Name, roles (what I am/do), language, emoji, introduction | How I behave, operational rules |
| **USER.md** | Profiles of the humans the agent helps — preferences, context, habits | Agent instructions, tool config |
| **TOOLS.md** | Local tool notes, workspace structure map, platform formatting, TTS rules, what is auto-loaded vs manual | Operational rules, personality |
| **MEMORY.md** | Long-term memory (facts, decisions, lessons) — auto-loaded per scope | Daily logs (those are in `memory/`) |
| **HEARTBEAT.md** | Periodic task checklist — empty = no polling | Fixed config |
| **CONVENTIONS.md** | Code/git/repo standards (optional, only for dev roles) | Operational rules, personality |

## Folder Structure

```text
workspace/
├── AGENTS.md            # Operational rules, skill routing, triggers
├── SOUL.md              # Tone, values, communication style, boundaries
├── IDENTITY.md          # Name, roles, language, emoji, introduction
├── USER.md              # Profiles of the humans the agent helps
├── TOOLS.md             # Tool notes, workspace map, platform formatting, TTS rules
├── MEMORY.md            # Long-term memory index (scope-limited)
├── HEARTBEAT.md         # Periodic tasks (empty = no polling)
├── CONVENTIONS.md       # Code/git/repo standards (optional, dev roles only)
├── secrets/             # .env files per skill, NEVER commit
│   └── <skill>.env
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md     # Contract: metadata + triggers + commands + rules
│       ├── scripts/     # Standalone executable scripts (sh/py)
│       └── references/  # (optional) deep docs, runbooks, API specs
├── memory/
│   ├── YYYY-MM-DD.md    # Daily session logs (NOT auto-injected)
│   └── .dreams/         # Short-term recall scoring (experimental)
├── files/               # Reference library (PDFs, exports)
├── docs/                # Large docs, load ONLY on request
└── tmp/                 # Working files, intermediate results
```

## AGENTS.md Design

AGENTS.md is the operational brain. Keep it compact (<100 lines). It contains:

### 1. Skill Routing (most important — put it first)
Per skill: trigger words, action to take, and a default rule: "load one skill too many rather than too late."

### 2. Audio & Media Rules
- Audio in → audio out (always), unless explicit transcription requested
- Images → analyze, apply relevant skill

### 3. Memory Scope
Define where MEMORY.md may or may not be loaded (privacy).

### 4. Group Chat Behavior
When to respond, when to stay silent.

### 5. Heartbeat Protocol
What to check, when to reach out, when to be quiet.

**What does NOT belong in AGENTS.md:**
- "Every Session" read instructions (OpenClaw does this automatically)
- TTS details, platform formatting (those go in TOOLS.md)
- Personality, tone (goes in SOUL.md)
- Safety/security basics (handled by OpenClaw defaults)

## SOUL.md Design

Short and sharp (<40 lines). Follow the rule: "Short beats long. Sharp beats vague."

**Contains:**
- Core truths — 5-7 behavioral rules in imperative form (no explanations, no examples)
- Values/framework — what shapes the tone
- Boundaries — what the agent does NOT do
- Vibe — one paragraph summarizing communication style

**Strong rules:** "Be concise", "No filler", "Push back when needed"
**Weak rules:** "Maintain professionalism", "Provide comprehensive assistance"

## TOOLS.md Design

The local cheat sheet. Contains:

- **Workspace structure** — directory tree with brief description per item
- **Available tools** — what the agent can use (Read, Bash, curl, python3, etc.)
- **"What you must load yourself"** — table of situation → which file to load. Clarifies that workspace files are auto-injected, but daily notes and SKILL.md files are not.
- **TTS rules** — when audio, when not, voices, cost notes
- **Platform formatting** — per platform (Discord, WhatsApp, Telegram) what works
- **Skill notes** — per skill: base URLs, credentials location, scripts path

## Common Anti-Patterns

| Anti-pattern | Why it's wrong | Fix |
|-------------|----------------|-----|
| "Every Session" read instructions in AGENTS.md | OpenClaw auto-injects workspace files | Remove them |
| Personality in AGENTS.md or operational rules in SOUL.md | Token waste, contradictions | Strict separation |
| Loading entire reference documents | Context window waste, high cost | Navigation table in SKILL.md with line numbers |
| No explicit HTTP tool instruction in SKILL.md | Model may choose urllib/WebFetch → encoding bugs | "ALWAYS curl via Bash" in SKILL.md |
| Bundled binaries in skill folders (jq, yq) | Bloat, platform-dependent | Use python3/node |
| Thin wrapper scripts that exec container-side scripts | Two sources of truth, breaks on updates | Make scripts standalone |
| Skill logic split between workspace and container | Maintenance nightmare | Everything in workspace |

## Workspace File Checklist

- [ ] AGENTS.md < 100 lines, operational only
- [ ] SOUL.md < 40 lines, personality/tone only
- [ ] IDENTITY.md has roles but no operational details
- [ ] TOOLS.md has tool notes, formatting, "what to load yourself" table
- [ ] USER.md has only user profiles and preferences
- [ ] No overlap between files
- [ ] No "Every Session" read instructions (OpenClaw does this automatically)
- [ ] MEMORY.md scope defined in AGENTS.md (where to load, where not)
