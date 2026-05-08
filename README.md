# claude-ssh-mcp-safety

A Claude Code hook that blocks dangerous shell commands executed on remote servers via [SSH-MCP](https://github.com/mixelpixx/SSH-MCP).

## Background

When using SSH MCP tools (like `ssh_exec`) in Claude Code, commands run on remote servers **without the same permission prompts** that built-in Bash commands trigger. This hook adds a safety layer by intercepting destructive commands before they execute.

## Blocked Commands

| Category | Commands |
|---|---|
| File deletion | `rm`, `shred` |
| Process termination | `kill`, `killall`, `pkill` |
| System control | `shutdown`, `reboot`, `halt`, `poweroff` |
| Disk operations | `mkfs.*`, `fdisk`, `parted`, `wipefs` |
| Device overwrite | `dd of=/dev/...` |
| Firewall | `ufw disable`, `iptables -F/-X`, `nft flush` |
| Account management | `passwd`, `userdel`, `usermod` |
| Service control | `systemctl stop/disable/mask` |
| Cron wipe | `crontab -r` |
| Database destruction | `DROP TABLE/DATABASE/SCHEMA` via `mysql`/`psql`/`mongo` |
| System file overwrite | Redirect (`>`) to `/etc/`, `/boot/`, `/usr/`, `/bin/`, `/sbin/`, `/lib/` |

Safe commands (read-only operations, writes to `/tmp`, etc.) pass through without any prompt.

## How to override

When a command is blocked and you intended it, explicitly confirm in your message:

> "I confirm the deletion" / "I confirm the reboot" / etc.

Claude will then re-attempt the command.

## Installation

### 1. Install SSH-MCP

```bash
git clone https://github.com/mixelpixx/SSH-MCP.git ~/.claude/SSH-MCP
cd ~/.claude/SSH-MCP
npm install
npm run build
claude mcp add ssh-server node ~/.claude/SSH-MCP/build/index.js -e NODE_NO_WARNINGS=1 --scope user
```

### 2. Install the hook

```bash
mkdir -p ~/.claude/hooks
cp check-ssh-dangerous.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/check-ssh-dangerous.sh
```

### 3. Configure settings.json

Add the hook to `~/.claude/settings.json` (merge with your existing settings):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__ssh-server__ssh_exec",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/check-ssh-dangerous.sh",
            "statusMessage": "Checking for dangerous commands..."
          }
        ]
      }
    ]
  }
}
```

See [settings-example.json](./settings-example.json) for the full hook configuration.

### 4. Restart Claude Code

The hook takes effect after restarting your Claude Code session.

## Limitations

This hook performs **regex-based string matching** on the command string. It can be bypassed by obfuscated commands (variable substitution, base64-encoded payloads, etc.). It is designed to prevent *accidental* destructive operations by Claude, not to be a security boundary against intentional misuse.
