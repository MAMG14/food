#!/usr/bin/env bash
# preToolUse: deny edits under lib/ while no spec is approved.
source "$(dirname "$0")/lib.sh"

input="$(cat)"
log_payload preToolUse "$input"

path="$(relative_path "$(edited_path "$input")")"
case "$path" in
  lib/*) ;;
  *) echo '{"permission":"allow"}'; exit 0 ;;
esac

if grep -lqE '^Estado:[[:space:]]*aprobada' specs/*/spec.md 2>/dev/null; then
  echo '{"permission":"allow"}'
  exit 0
fi

jq -n --arg p "$path" '{
  permission: "deny",
  user_message: "Bloqueado: no hay ninguna spec en estado aprobada.",
  agent_message: ("No puedes editar " + $p + ": ninguna spec en specs/ tiene \"Estado: aprobada\". La spec manda: redacta o actualiza la spec y pide aprobación al usuario antes de tocar lib/.")
}'
