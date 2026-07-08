#!/usr/bin/env bash
# AgentSync skill installer / updater
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --agents grok,claude
#   curl -fsSL .../install.sh | bash -s -- --check

set -euo pipefail

REPO="FeiZhuLulu/AgentSync"
BRANCH="main"
SKILL_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/agentsync/SKILL.md"
AGENTS=""
CHECK_ONLY=0

usage() {
  cat <<'EOF'
AgentSync skill installer / updater

Usage:
  install.sh [--agents LIST] [--check] [--branch BRANCH]

Options:
  --agents LIST   Comma-separated: claude,grok,cursor,opencode (default: auto-detect)
  --check         Show installed vs latest version, then exit
  --branch BRANCH Git branch to pull from (default: main)
  -h, --help      Show this help

Examples:
  curl -fsSL https://raw.githubusercontent.com/FeiZhuLulu/AgentSync/main/agentsync/install.sh | bash
  curl -fsSL .../install.sh | bash -s -- --agents grok,claude,cursor
  curl -fsSL .../install.sh | bash -s -- --check
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agents) AGENTS="${2:-}"; shift 2 ;;
    --check) CHECK_ONLY=1; shift ;;
    --branch) BRANCH="${2:-}"; SKILL_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/agentsync/SKILL.md"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

skill_dir() {
  case "$1" in
    claude)  echo "${HOME}/.claude/skills/agentsync" ;;
    grok)    echo "${HOME}/.grok/skills/agentsync" ;;
    cursor)  echo "${HOME}/.cursor/skills/agentsync" ;;
    opencode) echo "${HOME}/.config/opencode/skills/agentsync" ;;
    *) echo "" ;;
  esac
}

detect_agents() {
  local found=()
  for a in claude grok cursor opencode; do
    local d
    d="$(skill_dir "$a")"
    if [[ -n "$d" && ( -d "$(dirname "$d")" || -f "${d}/SKILL.md" ) ]]; then
      found+=("$a")
    fi
  done
  if [[ ${#found[@]} -eq 0 ]]; then
    found=(claude grok cursor)
  fi
  printf '%s\n' "${found[@]}"
}

parse_version() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "not installed"
    return
  fi
  grep -m1 '^  version:' "$file" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' || echo "unknown"
}

fetch_remote_version() {
  curl -fsSL "$SKILL_URL" | grep -m1 '^  version:' | sed 's/.*"\(.*\)".*/\1/' || echo "unknown"
}

if [[ -z "$AGENTS" ]]; then
  mapfile -t TARGETS < <(detect_agents)
else
  IFS=',' read -ra TARGETS <<< "$AGENTS"
fi

REMOTE_VER="$(fetch_remote_version)"

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  echo "Latest: v${REMOTE_VER} (${BRANCH})"
  for a in "${TARGETS[@]}"; do
    a="${a// /}"
    d="$(skill_dir "$a")"
    if [[ -z "$d" ]]; then
      echo "  ${a}: unsupported agent name"
      continue
    fi
    local_ver="$(parse_version "${d}/SKILL.md")"
    echo "  ${a}: ${local_ver} → ${d}/SKILL.md"
  done
  exit 0
fi

echo "Installing AgentSync v${REMOTE_VER} to: ${TARGETS[*]}"

for a in "${TARGETS[@]}"; do
  a="${a// /}"
  d="$(skill_dir "$a")"
  if [[ -z "$d" ]]; then
    echo "Skip unsupported agent: $a" >&2
    continue
  fi
  mkdir -p "$d"
  curl -fsSL "$SKILL_URL" -o "${d}/SKILL.md"
  echo "  ✓ ${a} → ${d}/SKILL.md"
done

echo "Done. Run /agentsync in your agent to use it."