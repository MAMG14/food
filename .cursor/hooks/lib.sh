#!/usr/bin/env bash
# Shared helpers for Food hooks. Source it; do not run it.

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 0
ROOT="$PWD"
STATE_DIR="$ROOT/.cursor/hooks/.state"
mkdir -p "$STATE_DIR"

log_payload() {
  printf '%s\t%s\t%s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" "$2" >>"$STATE_DIR/payloads.log"
}

# The edited path may come under different keys depending on the tool.
edited_path() {
  jq -r '.tool_input | (.file_path // .path // .target_file // .target_notebook // empty)' <<<"$1" 2>/dev/null
}

relative_path() {
  local p="$1"
  case "$p" in
    "$ROOT"/*) printf '%s' "${p#"$ROOT"/}" ;;
    *) printf '%s' "$p" ;;
  esac
}
