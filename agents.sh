#!/usr/bin/env bash
set -euo pipefail

# ============================================
# OpenClaw Agent Persona Manager
# ============================================
# Manage agent personas in your workspace.
# Personas are markdown files that define specialized roles.

WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-./data/workspace}"
AGENTS_DIR="$WORKSPACE_DIR/agents"
TEMPLATES_DIR="./templates/agents"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

usage() {
  echo "Usage: ./agents.sh <command> [args]"
  echo ""
  echo "Commands:"
  echo "  init              Copy all template personas to your workspace"
  echo "  list              Show installed agent personas"
  echo "  add <name> [tpl]  Create a new persona (from blank or named template)"
  echo "  remove <name>     Remove a persona"
  echo "  templates         Show available templates"
  echo ""
  echo "Examples:"
  echo "  ./agents.sh init                    # Install default personas"
  echo "  ./agents.sh add researcher          # New persona from blank template"
  echo "  ./agents.sh add support assistant   # New persona based on assistant template"
  echo "  ./agents.sh remove marketeer        # Remove a persona"
}

cmd_init() {
  if [ ! -d "$TEMPLATES_DIR" ]; then
    echo -e "${YELLOW}[!]${NC} Templates directory not found at $TEMPLATES_DIR"
    exit 1
  fi

  mkdir -p "$AGENTS_DIR"

  local count=0
  for tpl in "$TEMPLATES_DIR"/*.md; do
    [ -f "$tpl" ] || continue
    local name
    name=$(basename "$tpl")

    # Skip blank template — it's only for creating new personas
    if [ "$name" = "blank.md" ]; then
      continue
    fi

    if [ -f "$AGENTS_DIR/$name" ]; then
      echo -e "  ${DIM}skip${NC}  $name (already exists)"
    else
      cp "$tpl" "$AGENTS_DIR/$name"
      echo -e "  ${GREEN}✓${NC}     $name"
      count=$((count + 1))
    fi
  done

  if [ "$count" -eq 0 ]; then
    echo -e "${DIM}No new personas to install — all templates already present.${NC}"
  else
    echo ""
    echo -e "${GREEN}[OK]${NC} $count persona(s) installed to $AGENTS_DIR/"
    echo -e "${DIM}Edit them to match your needs, then restart: docker compose restart openclaw-gateway${NC}"
  fi
}

cmd_list() {
  if [ ! -d "$AGENTS_DIR" ] || [ -z "$(ls -A "$AGENTS_DIR" 2>/dev/null)" ]; then
    echo "No agent personas installed."
    echo "Run ./agents.sh init to install templates, or ./agents.sh add <name> to create one."
    return
  fi

  echo -e "${BOLD}Installed personas:${NC}"
  echo ""
  for f in "$AGENTS_DIR"/*.md; do
    [ -f "$f" ] || continue
    local name
    name=$(basename "$f" .md)
    # Extract the first "## Role" content as description
    local desc
    desc=$(sed -n '/^## Role$/,/^##/{/^## Role$/d;/^##/d;/^$/d;p;}' "$f" | head -1 | sed 's/^[[:space:]]*//')
    if [ -n "$desc" ]; then
      echo -e "  ${CYAN}${name}${NC} — $desc"
    else
      echo -e "  ${CYAN}${name}${NC}"
    fi
  done
}

cmd_add() {
  local name="${1:-}"
  local template="${2:-blank}"

  if [ -z "$name" ]; then
    echo "Usage: ./agents.sh add <name> [template]"
    echo "Available templates: $(cmd_templates_names)"
    exit 1
  fi

  mkdir -p "$AGENTS_DIR"

  local target="$AGENTS_DIR/${name}.md"
  if [ -f "$target" ]; then
    echo -e "${YELLOW}[!]${NC} $name.md already exists in $AGENTS_DIR/"
    echo "    Edit it directly or remove it first: ./agents.sh remove $name"
    exit 1
  fi

  local source="$TEMPLATES_DIR/${template}.md"
  if [ ! -f "$source" ]; then
    echo -e "${YELLOW}[!]${NC} Template '$template' not found."
    echo "Available templates: $(cmd_templates_names)"
    exit 1
  fi

  cp "$source" "$target"
  # Replace "Agent Name" in blank template with the actual name
  sed -i "s/^# Agent Name$/# ${name^} Agent/" "$target"

  echo -e "${GREEN}[OK]${NC} Created $target (from $template template)"
  echo -e "${DIM}Edit it to define the role, then restart: docker compose restart openclaw-gateway${NC}"
}

cmd_remove() {
  local name="${1:-}"

  if [ -z "$name" ]; then
    echo "Usage: ./agents.sh remove <name>"
    exit 1
  fi

  local target="$AGENTS_DIR/${name}.md"
  if [ ! -f "$target" ]; then
    echo -e "${YELLOW}[!]${NC} $name.md not found in $AGENTS_DIR/"
    exit 1
  fi

  rm "$target"
  echo -e "${GREEN}[OK]${NC} Removed $name persona"
  echo -e "${DIM}Restart to apply: docker compose restart openclaw-gateway${NC}"
}

cmd_templates() {
  echo -e "${BOLD}Available templates:${NC}"
  echo ""
  for tpl in "$TEMPLATES_DIR"/*.md; do
    [ -f "$tpl" ] || continue
    local name
    name=$(basename "$tpl" .md)
    local desc
    desc=$(sed -n '/^## Role$/,/^##/{/^## Role$/d;/^##/d;/^$/d;p;}' "$tpl" | head -1 | sed 's/^[[:space:]]*//')
    if [ -n "$desc" ]; then
      echo -e "  ${CYAN}${name}${NC} — $desc"
    else
      echo -e "  ${CYAN}${name}${NC}"
    fi
  done
}

cmd_templates_names() {
  for tpl in "$TEMPLATES_DIR"/*.md; do
    [ -f "$tpl" ] || continue
    basename "$tpl" .md
  done | tr '\n' ', ' | sed 's/,$//'
}

# --- Main ---
case "${1:-}" in
  init)      cmd_init ;;
  list)      cmd_list ;;
  add)       shift; cmd_add "$@" ;;
  remove)    shift; cmd_remove "$@" ;;
  templates) cmd_templates ;;
  help|-h|--help) usage ;;
  *)
    usage
    exit 1
    ;;
esac
