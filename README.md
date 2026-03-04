# claude-notification-hook

Terminal notification hook for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Sends **OSC 9** bell notifications when Claude is idle or requesting permission — so you never miss a prompt while multitasking.

Port of [opencode-notification-plugin](https://github.com) for the Claude Code hooks system.

## Features

- OSC 9 terminal notifications (supported by most modern terminals)
- Tmux passthrough support
- Rate-limited (5 s minimum between notifications)
- Fires on **idle** (Claude waiting for input 60 s+) and **permission** requests

## Requirements

- `jq` — for JSON parsing and settings installation
- A terminal that supports OSC 9 notifications (iTerm2, WezTerm, Windows Terminal, foot, etc.)

## Install

```bash
git clone https://github.com/<you>/claude-notification-hook.git
cd claude-notification-hook
bash install.sh
```

This adds `Notification` hooks to `~/.claude/settings.json`. Existing settings are preserved.

## Uninstall

```bash
bash uninstall.sh
```

## How it works

Claude Code fires `Notification` hooks with matchers:

| Matcher | When |
|---------|------|
| `idle_prompt` | Claude has been waiting for input for 60+ seconds |
| `permission_prompt` | Claude needs permission to use a tool |

The hook script reads the notification payload from stdin, extracts a message, and writes an OSC 9 escape sequence to stdout. If running inside tmux, the sequence is wrapped in a DCS passthrough.

## License

MIT
