#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="$(basename "$SCRIPT_DIR")"
SELECTED_AGENTS=()

info() {
  printf '[uninstall] %s\n' "$1"
}

warn() {
  printf '[skip] %s\n' "$1"
}

usage() {
  cat <<'EOF'
Usage: bash uninstall.sh [--agents claude,codex,cursor]

Options:
  --agents   Limit uninstall to a comma-separated agent list.
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

uninstall_for_agent() {
  local agent="$1"
  local root_dir=""
  local target_dir=""

  root_dir="$(agent_root "$agent")"
  if [ ! -d "$root_dir" ]; then
    warn "$agent agent dir not found: $root_dir"
    return 0
  fi

  target_dir="$root_dir/skills/$SKILL_NAME"
  if [ ! -e "$target_dir" ]; then
    warn "$agent skill not installed: $target_dir"
    return 0
  fi

  rm -rf "$target_dir"
  info "removed $SKILL_NAME from $target_dir"
}

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
  uninstall_for_agent "$agent"
done

info "done"
