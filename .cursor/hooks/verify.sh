#!/usr/bin/env bash
# stop: if Dart sources changed since the last green run, run analyze + tests.
source "$(dirname "$0")/lib.sh"

input="$(cat)"
log_payload stop "$input"

status="$(jq -r '.status // empty' <<<"$input")"
[ "$status" = "aborted" ] && { echo '{}'; exit 0; }

fingerprint="$(git ls-files -co --exclude-standard -- lib test integration_test pubspec.yaml \
  | sort | xargs shasum 2>/dev/null | shasum | cut -d' ' -f1)"
last_file="$STATE_DIR/last-green"
if [ -f "$last_file" ] && [ "$(cat "$last_file")" = "$fingerprint" ]; then
  echo '{}'
  exit 0
fi

report=""
if ! out="$(flutter analyze --no-fatal-infos 2>&1)"; then
  report+="flutter analyze falló:\n$(grep -E ' - ' <<<"$out" | head -20)\n"
fi
if ! out="$(flutter test --reporter failures-only 2>&1)"; then
  report+="flutter test falló:\n$(tail -30 <<<"$out")\n"
fi

if [ -z "$report" ]; then
  printf '%s' "$fingerprint" >"$last_file"
  echo '{}'
  exit 0
fi

jq -n --arg r "$(printf '%b' "$report")" '{
  followup_message: ("Verificación automática del hook stop:\n" + $r + "\nCorrige los fallos (o explica al usuario por qué no se puede) antes de cerrar.")
}'
