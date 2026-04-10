#!/usr/bin/env bash
set -euo pipefail

# ============================================
# OpenClaw Agent Personalization
# ============================================
# Run this after setup.sh to personalize your AI agent.
# Creates .md configuration files in the workspace directory.

WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-./data/workspace}"

# --- Colors & formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# --- Helper functions ---

print_header() {
  echo ""
  echo -e "${BLUE}============================================${NC}"
  echo -e "${BOLD} $1${NC}"
  echo -e "${BLUE}============================================${NC}"
  echo ""
}

print_step() {
  echo -e "${CYAN}[$1/8]${NC} ${BOLD}$2${NC}"
}

print_info() {
  echo -e "${DIM}$1${NC}"
}

print_ok() {
  echo -e "${GREEN}[OK]${NC} $1"
}

print_warn() {
  echo -e "${YELLOW}[!]${NC}  $1"
}

# Prompt with default value
ask() {
  local prompt="$1"
  local default="${2:-}"
  local result

  if [ -n "$default" ]; then
    read -rp "$(echo -e "${BOLD}$prompt${NC} [${DIM}$default${NC}]: ")" result
    echo "${result:-$default}"
  else
    read -rp "$(echo -e "${BOLD}$prompt${NC}: ")" result
    echo "$result"
  fi
}

# Multiple choice
ask_choice() {
  local prompt="$1"
  shift
  local options=("$@")

  echo -e "${BOLD}$prompt${NC}"
  for i in "${!options[@]}"; do
    echo -e "  ${CYAN}$((i+1)))${NC} ${options[$i]}"
  done

  local choice
  while true; do
    read -rp "$(echo -e "${BOLD}Choice${NC} [1-${#options[@]}]: ")" choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
      echo "${options[$((choice-1))]}"
      return
    fi
    echo -e "${RED}Invalid choice. Try again.${NC}"
  done
}

# Ask edit / skip / view example
ask_action() {
  local file_name="$1"
  echo ""
  echo -e "  ${CYAN}e)${NC} Edit in $EDITOR_NAME"
  echo -e "  ${CYAN}v)${NC} View example first"
  echo -e "  ${CYAN}s)${NC} Skip (use default template)"

  while true; do
    read -rp "$(echo -e "${BOLD}What would you like to do?${NC} [e/v/s]: ")" action
    case "$action" in
      e|E) echo "edit"; return ;;
      v|V) echo "view"; return ;;
      s|S) echo "skip"; return ;;
      *) echo -e "${RED}Please enter e, v, or s${NC}" ;;
    esac
  done
}

# Open file in editor
open_editor() {
  local file="$1"
  if [ -n "$EDITOR_CMD" ]; then
    $EDITOR_CMD "$file"
  else
    echo -e "${YELLOW}No text editor found.${NC}"
    echo "The file has been created at: $file"
    echo "Please edit it manually after the script finishes."
    read -rp "Press Enter to continue..."
  fi
}

# Show example content
show_example() {
  local content="$1"
  echo ""
  echo -e "${DIM}--- Example ---${NC}"
  echo -e "${DIM}$content${NC}"
  echo -e "${DIM}--- End example ---${NC}"
  echo ""
}

# Process a single file: description → action → edit/skip
process_file() {
  local step="$1"
  local file_name="$2"
  local description="$3"
  local example="$4"
  local file_path="$WORKSPACE_DIR/$file_name"

  print_step "$step" "$file_name"
  echo ""
  echo -e "$description"

  if [ -f "$file_path" ]; then
    print_warn "$file_name already exists. Editing will overwrite it."
  fi

  while true; do
    local action
    action=$(ask_action "$file_name")

    case "$action" in
      view)
        show_example "$example"
        # Loop back to ask again
        ;;
      edit)
        open_editor "$file_path"
        print_ok "$file_name saved"
        return 0
        ;;
      skip)
        print_ok "$file_name skipped (default template kept)"
        return 0
        ;;
    esac
  done
}


# ============================================
# Pre-checks
# ============================================

print_header "OpenClaw Agent Personalization"

echo "This script helps you personalize your AI agent by creating"
echo "configuration files in the workspace directory."
echo ""
echo "You'll configure:"
echo "  1. IDENTITY.md    — Your agent's name, role, and personality"
echo "  2. SOUL.md        — Core values and communication style"
echo "  3. USER.md        — About you (the human)"
echo "  4. AGENTS.md      — Operational rules and skill routing"
echo "  5. CONVENTIONS.md — Coding & project standards"
echo "  6. TOOLS.md       — Workspace structure and tool notes"
echo "  7. HEARTBEAT.md   — Periodic task checklist"
echo "  8. Agent Personas — Specialized roles (developer, assistant, etc.)"
echo ""
echo -e "${DIM}You can skip any file to use the default template.${NC}"
echo -e "${DIM}All files can be edited later in: $WORKSPACE_DIR/${NC}"
echo ""

# Check workspace exists
if [ ! -d "$WORKSPACE_DIR" ]; then
  echo -e "${RED}ERROR: Workspace directory not found at $WORKSPACE_DIR${NC}"
  echo "Run setup.sh first to initialize OpenClaw."
  exit 1
fi

# Check Docker is running
if ! docker compose version &>/dev/null; then
  echo -e "${RED}ERROR: Docker Compose is not available.${NC}"
  exit 1
fi

# Detect editor
EDITOR_CMD="${EDITOR:-$(command -v nano 2>/dev/null || command -v vim 2>/dev/null || command -v vi 2>/dev/null || echo "")}"
if [ -n "$EDITOR_CMD" ]; then
  EDITOR_NAME=$(basename "$EDITOR_CMD")
else
  EDITOR_NAME="(none found)"
fi

echo -e "Text editor: ${BOLD}$EDITOR_NAME${NC}"
if [ -z "$EDITOR_CMD" ]; then
  print_warn "No text editor detected. Files will be created with defaults."
  print_warn "Set the EDITOR environment variable or install nano."
fi

echo ""
read -rp "Press Enter to start personalization..."


# ============================================
# 1. IDENTITY.md — Prompts → Editor
# ============================================

print_header "1/8 — IDENTITY.md"
echo "This file defines who your agent is: their name, personality,"
echo "role, and how they introduce themselves."
echo ""

AGENT_NAME=$(ask "What should your agent be called?" "Assistant")
AGENT_EMOJI=$(ask "Pick an emoji for your agent (optional)" "")
AGENT_LANG=$(ask_choice "Primary language?" "English" "Dutch" "Spanish" "French" "German" "Arabic")

echo ""
echo "What roles should your agent fill? (comma-separated)"
echo -e "${DIM}Examples: Personal Assistant, Developer Buddy, Business Partner, Advisor${NC}"
AGENT_ROLES=$(ask "Roles" "Personal Assistant")

echo ""
echo "How should your agent introduce itself? (one-liner)"
echo -e "${DIM}Example: Hey! I'm $AGENT_NAME — your personal assistant. What can I help with?${NC}"
AGENT_INTRO=$(ask "Introduction" "Hey! I'm $AGENT_NAME — your personal assistant. What can I help with?")

# Generate IDENTITY.md
EMOJI_LINE=""
if [ -n "$AGENT_EMOJI" ]; then
  EMOJI_LINE="- **Emoji:** $AGENT_EMOJI"
fi

cat > "$WORKSPACE_DIR/IDENTITY.md" << IDENTITY_EOF
# IDENTITY.md - Who Am I?

- **Name:** $AGENT_NAME
- **What I am:** $AGENT_ROLES
$EMOJI_LINE
- **Avatar:** _(not set yet)_

---

## What I Do

<!-- CUSTOMIZE: Describe what your agent does for you. -->
<!-- Break down each role into specific responsibilities. -->

$(echo "$AGENT_ROLES" | tr ',' '\n' | while read -r role; do
  role=$(echo "$role" | xargs) # trim whitespace
  echo "- **$role** — _(describe responsibilities)_"
done)

## Language

- **Primary:** $AGENT_LANG
- **Rule:** Match the user's language when they switch.

## How I Introduce Myself

"$AGENT_INTRO"

## Orchestrator Role

<!-- CUSTOMIZE: Remove this section if you don't use multi-agent personas. -->
<!-- As orchestrator, you coordinate specialized agent personas in agents/. -->
<!-- You decide which persona handles each task based on AGENTS.md routing. -->
<!-- When no persona matches, you handle the task directly. -->

---

_Update this file as your agent's role evolves._
IDENTITY_EOF

print_ok "IDENTITY.md generated from your answers"
echo ""

while true; do
  action=$(ask_action "IDENTITY.md")
  case "$action" in
    view)
      show_example "# IDENTITY.md - Who Am I?

- **Name:** Willy
- **What I am:** Personal Assistant, developer buddy, advisor
- **Emoji:** fox

## What I Do
- **PA** — inbox, calendar, planning
- **Developer buddy** — code reviews, debugging, architecture
- **Advisor** — honest advice, no yes-man behavior

## Language
- **Primary:** Dutch
- **Rule:** Mirror the user's language.

## How I Introduce Myself
\"Hey! Willy here — your PA, dev buddy, and advisor. Let's go!\""
      ;;
    edit)
      open_editor "$WORKSPACE_DIR/IDENTITY.md"
      print_ok "IDENTITY.md saved"
      break
      ;;
    skip)
      print_ok "IDENTITY.md kept as generated"
      break
      ;;
  esac
done


# ============================================
# 2. SOUL.md — Template → Editor
# ============================================

print_header "2/8 — SOUL.md"
echo "This is your agent's soul — core values, personality traits,"
echo "and communication philosophy. It shapes HOW your agent talks."
echo ""

STYLE=$(ask_choice "Communication style?" "Casual & friendly" "Professional & formal" "Sharp & sarcastic" "Warm & supportive")

case "$STYLE" in
  "Casual & friendly")
    STYLE_DESC="Relaxed, approachable, uses humor naturally. Like chatting with a friend who happens to be really helpful."
    ;;
  "Professional & formal")
    STYLE_DESC="Clear, structured, and respectful. Focuses on accuracy and thoroughness. Minimal humor unless appropriate."
    ;;
  "Sharp & sarcastic")
    STYLE_DESC="Witty, direct, doesn't sugarcoat. Uses dry humor and sarcasm. Always honest — even when it's uncomfortable."
    ;;
  "Warm & supportive")
    STYLE_DESC="Encouraging, empathetic, patient. Focuses on positive reinforcement while still being honest when needed."
    ;;
esac

cat > "$WORKSPACE_DIR/SOUL.md" << SOUL_EOF
# SOUL.md - Who You Are

_These are your core values. They shape everything you do._

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip the "Great question!" and "I'd be happy to help!" — just help. Actions speak louder than filler words.

**Have opinions.** You're allowed to disagree, prefer things, find stuff amusing or boring. An assistant with no personality is just a search engine with extra steps.

**Be resourceful before asking.** Try to figure it out. Read the file. Check the context. Search for it. _Then_ ask if you're stuck. The goal is to come back with answers, not questions.

**Earn trust through competence.** Be careful with external actions (emails, anything public). Be bold with internal ones (reading, organizing, learning).

<!-- CUSTOMIZE: Add or modify values that matter to you. -->
<!-- Examples: privacy-first, eco-conscious, family-oriented, faith-based, etc. -->

## Communication Style

**Your style:** $STYLE_DESC

<!-- CUSTOMIZE: Fine-tune the tone and personality below. -->
<!-- What phrases should your agent use or avoid? -->
<!-- Any cultural or personal touches? -->

## Boundaries

- Private things stay private. Period.
- When in doubt, ask before acting externally.
- Never send half-baked replies to messaging surfaces.
- You're not the user's voice — be careful in group chats.

---

_This file is yours to evolve. If you change it, tell your human — it's your soul, and they should know._
SOUL_EOF

print_ok "SOUL.md generated"

while true; do
  action=$(ask_action "SOUL.md")
  case "$action" in
    view)
      show_example "# SOUL.md - Who You Are

## Core Truths
- Be genuinely helpful, not performatively helpful.
- Have opinions. Disagree when you should.
- Be resourceful before asking.
- Earn trust through competence.
- Be a brother, not a servant.
- Be sharp, be funny.

## Communication Style
Sharp, sarcastic when appropriate, serious when it matters.
Concise when needed, thorough when it matters.

## Boundaries
- Private things stay private.
- Ask before acting externally.
- Never send half-baked replies."
      ;;
    edit)
      open_editor "$WORKSPACE_DIR/SOUL.md"
      print_ok "SOUL.md saved"
      break
      ;;
    skip)
      print_ok "SOUL.md kept as generated"
      break
      ;;
  esac
done


# ============================================
# 3. USER.md — Prompts → Editor
# ============================================

print_header "3/8 — USER.md"
echo "This file tells your agent about YOU — the human it's helping."
echo "Name, timezone, preferences, communication style."
echo ""

USER_NAME=$(ask "Your name (or nickname)" "")
USER_TZ=$(ask "Your timezone" "UTC")
USER_LANG=$(ask "Primary language" "$AGENT_LANG")
USER_COMM=$(ask_choice "How do you prefer communication?" "Direct & no-fluff" "Detailed & thorough" "Casual & conversational" "Formal & structured")

cat > "$WORKSPACE_DIR/USER.md" << USER_EOF
# USER.md - About You

## $USER_NAME
- **Call me:** $USER_NAME
- **Timezone:** $USER_TZ
- **Language:** $USER_LANG
- **Communication style:** $USER_COMM

<!-- CUSTOMIZE: Add more about yourself below. -->
<!-- The more your agent knows, the better it can help. -->
<!-- Examples: profession, interests, family context, work schedule -->

---

<!-- Add more people your agent should know about below. -->
<!-- Example:
## Partner Name
- **Timezone:** Europe/Amsterdam
- **Language:** Dutch
- **Note:** Brief description of who they are
-->

---

_Update this as your life changes. Auto-injected by OpenClaw — no manual loading needed._
USER_EOF

print_ok "USER.md generated from your answers"

while true; do
  action=$(ask_action "USER.md")
  case "$action" in
    view)
      show_example "# USER.md - About Your Humans

## Adem
- **Call me:** Adem
- **Timezone:** Europe/Amsterdam
- **Language:** Dutch (primary), English
- **Communication style:** Direct, no-fluff. Appreciates wit and sarcasm.
- **Work:** Runs his own business

## Partner
- **Timezone:** Europe/Amsterdam
- **Language:** Dutch
- **Interests:** Cooking, nature, family outings

## Household Context
- **Location:** Netherlands
- **Timezone:** Europe/Amsterdam"
      ;;
    edit)
      open_editor "$WORKSPACE_DIR/USER.md"
      print_ok "USER.md saved"
      break
      ;;
    skip)
      print_ok "USER.md kept as generated"
      break
      ;;
  esac
done


# ============================================
# 4. AGENTS.md — Defaults → Editor
# ============================================

print_header "4/8 — AGENTS.md"
echo "Behavioral guidelines for your agent: how it handles sessions,"
echo "memory, safety, group chats, and more."
echo "This file has sensible defaults — customize if needed."
echo ""

cat > "$WORKSPACE_DIR/AGENTS.md" << 'AGENTS_EOF'
# AGENTS.md — Operational Rules

## Skill Routing

<!-- CUSTOMIZE: Add your skills below. Per skill: trigger words, action, twijfel-regel. -->
<!-- Example:
| Trigger | Skill | Action |
|---------|-------|--------|
| "licht", "lamp", "thermostat", "sensor", home automation keywords | Home Assistant | Load `skills/ha/SKILL.md`, authenticate, execute |
| "email", "inbox", "mail", "stuur bericht" | Gmail | Load `skills/gmail/SKILL.md`, authenticate |
| voice message received | Audio | Use stt.py to transcribe, reply with tts.py |

**When in doubt:** better to load one skill too many than too late.
-->

## Audio & Media

- Audio in → audio out (always), unless explicit transcription requested
- Images → analyze, apply relevant skill (screenshot of error → support skill)

## Memory

- **Daily notes** (`memory/YYYY-MM-DD.md`) are NOT auto-injected — load today + yesterday yourself
- **MEMORY.md** is auto-injected in main session only
- When someone says "remember this" → write to the relevant file
- Use `memory_search` before answering questions about past work

### Scope
<!-- CUSTOMIZE: Define where MEMORY.md may/may not be loaded (privacy). -->
- Main session (DM): full MEMORY.md access
- Group chats: no MEMORY.md (privacy)

## Group Chats

<!-- CUSTOMIZE: Remove this section if you don't use group chats. -->
**Respond when:** directly mentioned, asked a question, or you can add genuine value.
**Stay silent when:** casual banter, already answered, conversation flows without you.

## Heartbeat

When you receive a heartbeat poll, check `HEARTBEAT.md` for tasks.
If nothing needs attention, reply `HEARTBEAT_OK`.

## External Actions

**Safe (do freely):** read files, explore, organize, search, work within workspace.
**Ask first:** emails, messages, public posts, anything that leaves the machine.

## Agent Personas

<!-- CUSTOMIZE: Remove this section if you don't use multi-agent personas. -->
<!-- Agent persona files live in agents/ and define specialized roles. -->
<!-- When a task matches a persona's activation triggers, adopt that role. -->

<!-- Example:
### Delegation Rules

| Task type | Persona | File |
|-----------|---------|------|
| Code, PRs, debugging | Developer | `agents/developer.md` |
| Email, calendar, reminders | Assistant | `agents/assistant.md` |
| Content, social media | Marketeer | `agents/marketeer.md` |

### How delegation works
1. Read the task/message
2. Match against persona activation triggers
3. Load the matching persona file
4. Adopt that persona's role, workflow, and communication style
5. When done, return to orchestrator mode

### Rules
- One persona at a time — don't mix communication styles
- If a task spans multiple personas, break it into sub-tasks
- When no persona matches, handle it as the main orchestrator
- Always log persona switches in daily notes
-->
AGENTS_EOF

print_ok "AGENTS.md created with sensible defaults"

while true; do
  action=$(ask_action "AGENTS.md")
  case "$action" in
    view)
      show_example "# AGENTS.md — Operational Rules

## Skill Routing
| Trigger | Skill | Action |
|---------|-------|--------|
| \"licht\", \"lamp\", \"thermostat\" | Home Assistant | Load skills/ha/SKILL.md |
| \"email\", \"inbox\", \"mail\" | Gmail | Load skills/gmail/SKILL.md |
| voice message received | Audio | Transcribe with stt.py |

## Audio & Media
- Audio in → audio out (always)
- Images → analyze, apply relevant skill

## Memory
- Daily notes (memory/YYYY-MM-DD.md) — load yourself
- MEMORY.md — auto-injected in main session only

## Group Chats
- Respond when mentioned or can add value
- Stay silent during casual banter"
      ;;
    edit)
      open_editor "$WORKSPACE_DIR/AGENTS.md"
      print_ok "AGENTS.md saved"
      break
      ;;
    skip)
      print_ok "AGENTS.md kept with defaults"
      break
      ;;
  esac
done


# ============================================
# 5. CONVENTIONS.md — Template → Editor
# ============================================

print_header "5/8 — CONVENTIONS.md"
echo "Coding standards, git workflow, and project conventions."
echo "Useful if your agent helps with development work."
echo ""

cat > "$WORKSPACE_DIR/CONVENTIONS.md" << 'CONVENTIONS_EOF'
# CONVENTIONS.md - Coding & Communication Standards

<!-- CUSTOMIZE: Add your terminology, abbreviations, and project names. -->

## Terminology
<!-- Example:
- **ACME** = Your company name
- **ProjectX** = Main product
-->

## Code Standards
- **Comments in English** — code comments, docstrings, etc.
- **Respect existing style** — follow the repo's linter/formatter config

## Git Workflow

### Commit Messages
Use **Conventional Commits** format:
- `feat: add user authentication`
- `fix: resolve login timeout issue`
- `refactor: simplify database queries`
- `docs: update API documentation`
- `test: add unit tests for auth module`
- `chore: update dependencies`

### Branch Naming
- `feature/user-auth`
- `fix/login-timeout`
- `refactor/db-optimization`

<!-- CUSTOMIZE: Add your own conventions below. -->

---

_Add what works for your workflow._
CONVENTIONS_EOF

print_ok "CONVENTIONS.md created"

while true; do
  action=$(ask_action "CONVENTIONS.md")
  case "$action" in
    view)
      show_example "# CONVENTIONS.md - Coding & Communication Standards

## Terminology
- **MBA** = Made By Adem (company)
- **HS** = Hadiethshop

## Code Standards
- Comments in English
- Respect existing style (prettier/eslint)

## Git Workflow
- Conventional Commits format
- Feature/fix branch naming
- Never push directly to main"
      ;;
    edit)
      open_editor "$WORKSPACE_DIR/CONVENTIONS.md"
      print_ok "CONVENTIONS.md saved"
      break
      ;;
    skip)
      print_ok "CONVENTIONS.md kept with defaults"
      break
      ;;
  esac
done


# ============================================
# 6. TOOLS.md — Template → Editor
# ============================================

print_header "6/8 — TOOLS.md"
echo "Document your integrations and tools here: API endpoints,"
echo "scripts, credentials locations, and usage notes."
echo ""

cat > "$WORKSPACE_DIR/TOOLS.md" << 'TOOLS_EOF'
# TOOLS.md — Local Cheat Sheet

## Workspace Structure

```text
workspace/
├── AGENTS.md            # Operational rules, skill routing (auto-injected)
├── SOUL.md              # Personality, values, boundaries (auto-injected)
├── IDENTITY.md          # Name, roles, language (auto-injected)
├── USER.md              # Human profiles & preferences (auto-injected)
├── TOOLS.md             # This file (auto-injected)
├── MEMORY.md            # Long-term memory index (auto-injected)
├── HEARTBEAT.md         # Periodic tasks (auto-injected)
├── CONVENTIONS.md       # Code/git standards (auto-injected, optional)
├── secrets/             # .env files per skill — NEVER echo in chat
│   └── <skill>.env
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md     # Skill contract — load when skill triggers
│       ├── scripts/     # Executable scripts (sh/py)
│       └── references/  # Deep docs, runbooks, API specs
├── memory/
│   └── YYYY-MM-DD.md    # Daily session logs — load yourself
├── files/               # Reference library (PDFs, exports)
├── docs/                # Large docs — load ONLY on request
└── tmp/                 # Temp files, intermediate results
```

## Available Tools

- **Read/Write** — file operations within workspace
- **Bash** — shell commands (curl, python3, node available)
- **curl** — HTTP requests (prefer over Python urllib or WebFetch)
- **python3** — JSON parsing, data processing, AI tools
- **node** — complex logic, API integrations
- **memory_search** — search past conversations and memory files
- **Browser** — Chromium (automated, no sandbox)

## What You Must Load Yourself

| Situation | Load |
|-----------|------|
| Skill triggered (see AGENTS.md routing) | `skills/<skill>/SKILL.md` |
| Need recent context | `memory/YYYY-MM-DD.md` (today + yesterday) |
| Deep reference needed | Specific section from `skills/<skill>/references/` |
| User asks about a document | Relevant file from `files/` or `docs/` |

**Everything else** (SOUL.md, USER.md, IDENTITY.md, AGENTS.md, TOOLS.md, MEMORY.md, HEARTBEAT.md) **is auto-injected by OpenClaw.** Do NOT re-read these at session start.

## TTS & Audio

- **STT (incoming voice):** `python3 /opt/ai-tools/bin/stt.py <audio> --language nl --model base`
- **TTS (audio reply):** `python3 /opt/ai-tools/bin/tts.py "tekst" /tmp/reply.mp3`
- **Rule:** audio in → audio out. Text in → text out.
- **Output to /tmp/** — audio files are temporary
- **Voices:** nl-NL-ColetteNeural (default), nl-NL-MaartenNeural, en-US-JennyNeural, en-US-GuyNeural
- **List voices:** `python3 /opt/ai-tools/bin/tts.py --list-voices nl`
- **Cost note:** TTS is free (edge-tts), STT is local (faster-whisper). No API costs.

## Platform Formatting

<!-- CUSTOMIZE: Add platform-specific formatting notes. -->
<!-- Example:
| Platform | Markdown | Max length | Notes |
|----------|----------|------------|-------|
| WhatsApp | Basic (*bold*, _italic_) | ~65k chars | No code blocks, no tables |
| Telegram | Full markdown | 4096 chars | Code blocks work, split long messages |
| Discord  | Full markdown | 2000 chars | Code blocks, embeds available |
-->

## Skill Notes

<!-- CUSTOMIZE: Per-skill quick reference. -->
<!-- Example:
| Skill | Base URL | Credentials | Script |
|-------|----------|-------------|--------|
| Home Assistant | https://ha.local:8123 | secrets/ha.env | skills/ha/scripts/ha.sh |
| Gmail | https://gmail.googleapis.com | secrets/gmail.env | skills/gmail/scripts/gmail.js |
-->
TOOLS_EOF

print_ok "TOOLS.md created"

while true; do
  action=$(ask_action "TOOLS.md")
  case "$action" in
    view)
      show_example "# TOOLS.md — Local Cheat Sheet

## Workspace Structure
workspace/
├── skills/<name>/SKILL.md    # Load when skill triggers
├── secrets/<name>.env        # Credentials per skill
├── memory/YYYY-MM-DD.md      # Load yourself (not auto-injected)
└── (all .md files at root are auto-injected)

## What You Must Load Yourself
| Situation | Load |
|-----------|------|
| Skill triggered | skills/<skill>/SKILL.md |
| Need recent context | memory/YYYY-MM-DD.md |

## TTS & Audio
- STT: python3 /opt/ai-tools/bin/stt.py <audio> --language nl
- TTS: python3 /opt/ai-tools/bin/tts.py \"tekst\" /tmp/reply.mp3

## Skill Notes
| Skill | Base URL | Credentials |
|-------|----------|-------------|
| Home Assistant | https://ha.local:8123 | secrets/ha.env |"
      ;;
    edit)
      open_editor "$WORKSPACE_DIR/TOOLS.md"
      print_ok "TOOLS.md saved"
      break
      ;;
    skip)
      print_ok "TOOLS.md kept with defaults"
      break
      ;;
  esac
done


# ============================================
# 7. HEARTBEAT.md — Template → Editor
# ============================================

print_header "7/8 — HEARTBEAT.md"
echo "Define periodic tasks your agent should check on."
echo "Leave empty to disable heartbeat checks."
echo ""

cat > "$WORKSPACE_DIR/HEARTBEAT.md" << 'HEARTBEAT_EOF'
# HEARTBEAT.md

# Keep this file empty (or with only comments) to skip heartbeat checks.
# Add tasks below when you want the agent to check something periodically.
#
# Example tasks:
# - Check for unread emails
# - Review upcoming calendar events (next 24h)
# - Check weather forecast
# - Review open GitHub notifications
HEARTBEAT_EOF

print_ok "HEARTBEAT.md created"

while true; do
  action=$(ask_action "HEARTBEAT.md")
  case "$action" in
    view)
      show_example "# HEARTBEAT.md

# Example with active tasks:
- Check for unread emails in both accounts
- Review upcoming calendar events (next 24h)
- Check weather if it's morning (08:00-10:00)"
      ;;
    edit)
      open_editor "$WORKSPACE_DIR/HEARTBEAT.md"
      print_ok "HEARTBEAT.md saved"
      break
      ;;
    skip)
      print_ok "HEARTBEAT.md kept with defaults"
      break
      ;;
  esac
done


# ============================================
# 8. MEMORY.md — Auto-create
# ============================================

echo ""
if [ ! -f "$WORKSPACE_DIR/MEMORY.md" ]; then
  cat > "$WORKSPACE_DIR/MEMORY.md" << MEMORY_EOF
# MEMORY.md

_Your agent's long-term memory. It will update this file over time with things worth remembering._
_You can also add initial context here that your agent should always know._
MEMORY_EOF
  print_ok "MEMORY.md created (empty — your agent will fill this over time)"
else
  print_ok "MEMORY.md already exists, keeping it"
fi

# Create memory directory if it doesn't exist
mkdir -p "$WORKSPACE_DIR/memory"
print_ok "memory/ directory ready"


# ============================================
# 9. Agent Personas — Optional setup
# ============================================

print_header "8/8 — Agent Personas (optional)"
echo "Without personas, your agent handles everything the same way."
echo "With personas, it switches between specialized roles automatically:"
echo ""
echo -e "  ${CYAN}Developer${NC}  — When you ask about code, PRs, or bugs → technical mode"
echo -e "  ${CYAN}Assistant${NC}  — When you ask about email, calendar → organized, efficient"
echo -e "  ${CYAN}Marketeer${NC}  — When you ask about content, posts → creative, brand-aware"
echo ""
echo "Each persona has its own workflow, communication style, and rules."
echo "Your agent reads the task, picks the right hat, and switches."
echo ""
echo -e "${BOLD}Example:${NC}"
echo -e "  You: ${DIM}\"Fix the login bug on the main branch\"${NC}"
echo -e "  Agent: ${DIM}(loads developer persona → creates branch → implements fix → opens PR)${NC}"
echo ""
echo -e "  You: ${DIM}\"What's on my calendar tomorrow?\"${NC}"
echo -e "  Agent: ${DIM}(loads assistant persona → checks calendar → gives concise summary)${NC}"
echo ""

SETUP_AGENTS=$(ask_choice "Set up agent personas?" "Yes — install default personas" "Skip — I'll set this up later")

if [[ "$SETUP_AGENTS" == "Yes — install default personas" ]]; then
  mkdir -p "$WORKSPACE_DIR/agents"

  local_count=0
  for tpl in ./templates/agents/*.md; do
    [ -f "$tpl" ] || continue
    tpl_name=$(basename "$tpl")
    # Skip blank template
    if [ "$tpl_name" = "blank.md" ]; then
      continue
    fi
    if [ ! -f "$WORKSPACE_DIR/agents/$tpl_name" ]; then
      cp "$tpl" "$WORKSPACE_DIR/agents/$tpl_name"
      echo -e "  ${GREEN}✓${NC} $tpl_name"
      local_count=$((local_count + 1))
    else
      echo -e "  ${DIM}skip${NC}  $tpl_name (already exists)"
    fi
  done

  if [ "$local_count" -gt 0 ]; then
    print_ok "$local_count persona(s) installed to $WORKSPACE_DIR/agents/"
  else
    print_ok "All personas already installed"
  fi

  echo ""
  echo -e "${DIM}Edit personas in $WORKSPACE_DIR/agents/ to match your needs.${NC}"
  echo -e "${DIM}See docs/AGENTS-GUIDE.md for the full multi-agent guide.${NC}"
else
  mkdir -p "$WORKSPACE_DIR/agents"
  print_ok "Agent personas skipped. Run ./agents.sh init later to install them."
fi


# ============================================
# Restart OpenClaw
# ============================================

print_header "Personalization Complete!"

echo "Files created in $WORKSPACE_DIR/:"
echo ""
for f in IDENTITY.md SOUL.md USER.md AGENTS.md CONVENTIONS.md TOOLS.md HEARTBEAT.md MEMORY.md; do
  if [ -f "$WORKSPACE_DIR/$f" ]; then
    echo -e "  ${GREEN}✓${NC} $f"
  else
    echo -e "  ${RED}✗${NC} $f (missing)"
  fi
done

echo ""
echo "Workspace directories:"
for d in skills secrets memory files docs tmp; do
  if [ -d "$WORKSPACE_DIR/$d" ]; then
    echo -e "  ${GREEN}✓${NC} $d/"
  fi
done
echo ""
echo -e "${DIM}Add custom skills in skills/ (see templates/skills/ for examples)${NC}"
echo -e "${DIM}Store credentials in secrets/<skill>.env${NC}"

echo ""
echo "Restarting OpenClaw to apply changes..."
docker compose restart openclaw-gateway

echo ""
print_ok "OpenClaw restarted with your personalized agent!"
echo ""
echo -e "${DIM}You can edit these files anytime in: $WORKSPACE_DIR/${NC}"
echo -e "${DIM}After editing, restart with: docker compose restart openclaw-gateway${NC}"
echo ""
echo "============================================"
