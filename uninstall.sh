#!/usr/bin/env bash
# Removes the notification hooks from ~/.claude/settings.json
set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "No settings file found at $SETTINGS_FILE"
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required." >&2
  exit 1
fi

tmp=$(mktemp)
jq '
  if .hooks.Notification then
    .hooks.Notification = [.hooks.Notification[] | select(.matcher != "idle_prompt" and .matcher != "permission_prompt")]
    | if (.hooks.Notification | length) == 0 then del(.hooks.Notification) else . end
    | if (.hooks | length) == 0 then del(.hooks) else . end
  else . end
' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"

echo "Removed notification hooks from $SETTINGS_FILE"
