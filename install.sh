#!/usr/bin/env bash
# Installs the Claude Code notification hook into ~/.claude/settings.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/notify.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"

chmod +x "$NOTIFY_SCRIPT"

mkdir -p "$(dirname "$SETTINGS_FILE")"

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with: sudo apt install jq" >&2
  exit 1
fi

# Create settings.json if it doesn't exist
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Build the hook entries
idle_hook=$(jq -n --arg cmd "bash $NOTIFY_SCRIPT" '{
  matcher: "idle_prompt",
  hooks: [{ type: "command", command: $cmd }]
}')

permission_hook=$(jq -n --arg cmd "bash $NOTIFY_SCRIPT" '{
  matcher: "permission_prompt",
  hooks: [{ type: "command", command: $cmd }]
}')

# Merge hooks into settings, preserving existing config
tmp=$(mktemp)
jq --argjson idle "$idle_hook" --argjson perm "$permission_hook" '
  .hooks.Notification = (
    [.hooks.Notification // [] | .[] | select(.matcher != "idle_prompt" and .matcher != "permission_prompt")]
    + [$idle, $perm]
  )
' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"

echo "Installed notification hooks into $SETTINGS_FILE"
echo "Hooks will fire on: idle_prompt, permission_prompt"
