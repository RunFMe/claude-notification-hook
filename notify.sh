#!/usr/bin/env bash
# Claude Code notification hook — sends OSC 9 terminal notifications
# when Claude is idle or requesting permission.
#
# Equivalent of opencode-notification-plugin for Claude Code.

set -euo pipefail

MIN_NOTIFY_INTERVAL_MS=5000
STATE_FILE="${TMPDIR:-/tmp}/claude-notify-last"

# --- Rate-limit ---------------------------------------------------------------

now_ms() {
  date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))'
}

should_throttle() {
  local now last
  now=$(now_ms)
  last=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
  if (( now - last < MIN_NOTIFY_INTERVAL_MS )); then
    return 0  # throttle
  fi
  echo "$now" > "$STATE_FILE"
  return 1  # allow
}

# --- Notification -------------------------------------------------------------

send_notification() {
  local message="${1:-Claude Code}"
  local esc=$'\033'
  local bell=$'\007'
  local osc9="${esc}]9;${message}${bell}"

  # Write directly to the terminal, not stdout (which hooks may capture).
  local tty
  tty=$(tty 2>/dev/null) || tty="/dev/tty"

  if [[ -n "${TMUX:-}" ]]; then
    printf '%s' "${esc}Ptmux;${esc}${osc9}${esc}\\" > "$tty"
  else
    printf '%s' "$osc9" > "$tty"
  fi
}

# --- Main ---------------------------------------------------------------------

main() {
  if should_throttle; then
    exit 0
  fi

  # Read the hook input from stdin (JSON with notification details).
  local input
  input=$(cat)

  local message=""

  # Try to extract a human-readable message from the hook payload.
  if command -v jq &>/dev/null; then
    message=$(echo "$input" | jq -r '
      .title // .message // .notification // .reason // empty
    ' 2>/dev/null || true)
  fi

  if [[ -z "$message" ]]; then
    message="Claude Code needs attention"
  fi

  send_notification "$message"
}

main "$@"
