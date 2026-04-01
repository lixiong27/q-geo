#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="$(basename "$SCRIPT_DIR")"
SELECTED_AGENTS=()
INSTALLED_AGENTS=()

info() {
  printf '[install] %s\n' "$1"
}

warn() {
  printf '[skip] %s\n' "$1"
}

usage() {
  cat <<'EOF'
Usage: bash install.sh [--agents claude,codex,cursor]

Options:
  --agents   Limit installation to a comma-separated agent list.
  -h, --help Show this help.
EOF
}

normalize_agent() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

agent_root() {
  case "$1" in
    claude) echo "$HOME/.claude" ;;
    codex) echo "$HOME/.codex" ;;
    cursor) echo "$HOME/.cursor" ;;
    *) return 1 ;;
  esac
}

append_agent() {
  local agent="$1"
  local existing=""

  for existing in "${SELECTED_AGENTS[@]:-}"; do
    if [ "$existing" = "$agent" ]; then
      return 0
    fi
  done

  SELECTED_AGENTS+=("$agent")
}

select_agents() {
  local agents_arg="${1:-}"
  local token=""
  local agent=""

  if [ -n "$agents_arg" ]; then
    local old_ifs="$IFS"
    IFS=','
    for token in $agents_arg; do
      agent="$(normalize_agent "$token")"
      case "$agent" in
        claude|codex|cursor)
          append_agent "$agent"
          ;;
        "")
          ;;
        *)
          printf 'Unsupported agent: %s\n' "$agent" >&2
          exit 1
          ;;
      esac
    done
    IFS="$old_ifs"
    return 0
  fi

  for agent in claude codex cursor; do
    if [ -d "$(agent_root "$agent")" ]; then
      append_agent "$agent"
    fi
  done
}

copy_entry_if_exists() {
  local source="$1"
  local target="$2"

  if [ -e "$source" ]; then
    cp -R "$source" "$target"
  fi
}

install_for_agent() {
  local agent="$1"
  local root_dir=""
  local skills_dir=""
  local target_dir=""
  local source_real=""
  local target_real=""

  root_dir="$(agent_root "$agent")"
  if [ ! -d "$root_dir" ]; then
    warn "$agent agent dir not found: $root_dir"
    return 0
  fi

  skills_dir="$root_dir/skills"
  target_dir="$skills_dir/$SKILL_NAME"
  mkdir -p "$skills_dir"

  source_real="$(cd "$SCRIPT_DIR" && pwd -P)"
  if [ -e "$target_dir" ]; then
    target_real="$(cd "$target_dir" && pwd -P)"
    if [ "$source_real" = "$target_real" ]; then
      warn "$agent target already points to current skill: $target_dir"
      return 0
    fi
    rm -rf "$target_dir"
  fi

  mkdir -p "$target_dir"
  copy_entry_if_exists "$SCRIPT_DIR/SKILL.md" "$target_dir/"
  copy_entry_if_exists "$SCRIPT_DIR/agents" "$target_dir/"
  copy_entry_if_exists "$SCRIPT_DIR/references" "$target_dir/"
  copy_entry_if_exists "$SCRIPT_DIR/scripts" "$target_dir/"
  copy_entry_if_exists "$SCRIPT_DIR/install.sh" "$target_dir/"

  INSTALLED_AGENTS+=("$agent")
  info "installed $SKILL_NAME to $target_dir"
}

if [ ! -f "$SCRIPT_DIR/SKILL.md" ]; then
  printf 'SKILL.md not found in %s\n' "$SCRIPT_DIR" >&2
  exit 1
fi

AGENTS_ARG=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --agents)
      shift
      [ "$#" -gt 0 ] || {
        printf '%s\n' '--agents requires a value' >&2
        exit 1
      }
      AGENTS_ARG="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

select_agents "$AGENTS_ARG"

if [ "${#SELECTED_AGENTS[@]}" -eq 0 ]; then
  warn "no supported agent directory found under \$HOME"
  exit 0
fi

for agent in "${SELECTED_AGENTS[@]}"; do
  install_for_agent "$agent"
done

if [ "${#INSTALLED_AGENTS[@]}" -eq 0 ]; then
  warn "nothing installed"
  exit 0
fi

info "done: ${INSTALLED_AGENTS[*]}"

