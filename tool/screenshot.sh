#!/usr/bin/env bash
# Captures the screen of the booted iOS simulator (or the single connected
# Android device) into build/screens/<timestamp>-<name>.png and prints the path.
# Usage: tool/screenshot.sh [name] [ios|android]
set -euo pipefail

cd "$(dirname "$0")/.."
name="${1:-screen}"
platform="${2:-ios}"
out_dir="build/screens"
mkdir -p "$out_dir"
out="$out_dir/$(date '+%Y%m%d-%H%M%S')-$name.png"

case "$platform" in
  ios)
    if ! xcrun simctl list devices booted | grep -q Booted; then
      echo "No hay ningún simulador iOS arrancado." >&2
      exit 1
    fi
    xcrun simctl io booted screenshot "$out" >/dev/null 2>&1
    ;;
  android)
    adb exec-out screencap -p >"$out"
    ;;
  *)
    echo "Plataforma desconocida: $platform (usa ios o android)" >&2
    exit 1
    ;;
esac

echo "$out"
