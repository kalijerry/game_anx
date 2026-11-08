#!/usr/bin/env bash
# AI playtest: a bot plays every level in Chinese and English, then hammers each level with
# random input. Writes build/playtest/report.md (and report.json, and screenshots with --shots).
# Fails if the bot hits a problem or Godot prints a script error.
#
#   tools/playtest.sh                 # headless and fast (what CI runs)
#   tools/playtest.sh --shots         # renders under xvfb and saves screenshots in build/playtest/shots
#   tools/playtest.sh -- --lang=zh    # extra options for tests/playtest/playtest.gd
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
OUT=build/playtest
mode=(--headless)
if [[ "${1:-}" == "--shots" ]]; then
  shift
  mode=(--rendering-driver opengl3)
  if [[ -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null; then
    mode=(--rendering-driver opengl3)
    wrap=(xvfb-run -a -s "-screen 0 1280x720x24")
  fi
fi
[[ "${1:-}" == "--" ]] && shift
rm -rf "$OUT" && mkdir -p "$OUT"
${wrap[@]+"${wrap[@]}"} "$GODOT" "${mode[@]}" --fixed-fps 60 --path . -s tests/playtest/playtest.gd -- "$@" 2>&1 | tee "$OUT/godot.log"
status=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|Parse Error" "$OUT/godot.log"; then
  echo "playtest: Godot printed script errors (see $OUT/godot.log)" >&2
  status=1
fi
exit "$status"
