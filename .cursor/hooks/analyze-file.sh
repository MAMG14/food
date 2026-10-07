#!/usr/bin/env bash
# postToolUse: run dart analyze on the edited .dart file and report issues.
source "$(dirname "$0")/lib.sh"

input="$(cat)"
log_payload postToolUse "$input"

path="$(relative_path "$(edited_path "$input")")"
case "$path" in
  *.dart) ;;
  *) echo '{}'; exit 0 ;;
esac
[ -f "$path" ] || { echo '{}'; exit 0; }

out="$(dart analyze --no-fatal-warnings "$path" 2>&1)"
issues="$(grep -E '^[[:space:]]*(error|warning|info) - ' <<<"$out" | head -20)"
if [ -z "$issues" ]; then
  echo '{}'
  exit 0
fi

jq -n --arg p "$path" --arg o "$issues" '{
  additional_context: ("dart analyze encontró problemas en " + $p + ":\n" + $o + "\nCorrígelos antes de seguir.")
}'
