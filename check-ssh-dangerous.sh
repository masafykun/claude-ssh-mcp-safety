#!/bin/bash
# Hook script for Claude Code: blocks dangerous commands executed via SSH MCP (ssh_exec).
# Place this file in ~/.claude/hooks/ and configure settings.json (see settings-example.json).

cmd=$(jq -r '.tool_input.command // ""')

# File deletion
if echo "$cmd" | grep -qE '(^|[[:space:];|&`])(rm|shred)[[:space:]]'; then
  echo '{"continue": false, "stopReason": "[File Deletion] rm or shred detected. To proceed intentionally, explicitly say \"I confirm the deletion\"."}'
  exit 0
fi

# Process termination
if echo "$cmd" | grep -qE '(^|[[:space:];|&`])(kill|killall|pkill)[[:space:]]'; then
  echo '{"continue": false, "stopReason": "[Process Kill] kill/killall/pkill detected. To proceed intentionally, explicitly say \"I confirm the process termination\"."}'
  exit 0
fi

# System shutdown / reboot
if echo "$cmd" | grep -qE '(^|[[:space:];|&`])(shutdown|reboot|halt|poweroff)([[:space:]]|$)'; then
  echo '{"continue": false, "stopReason": "[System Control] shutdown/reboot/halt/poweroff detected. To proceed intentionally, explicitly say \"I confirm the system operation\"."}'
  exit 0
fi

# Disk / partition operations
if echo "$cmd" | grep -qE '(^|[[:space:];|&`])(mkfs[.[:space:]]|fdisk[[:space:]]|parted[[:space:]]|wipefs[[:space:]])'; then
  echo '{"continue": false, "stopReason": "[Disk Operation] mkfs/fdisk/parted/wipefs detected. To proceed intentionally, explicitly say \"I confirm the disk operation\"."}'
  exit 0
fi

# dd writing directly to a device
if echo "$cmd" | grep -qE '(^|[[:space:];|&`])dd[[:space:]]' && echo "$cmd" | grep -qE 'of=/dev/'; then
  echo '{"continue": false, "stopReason": "[Dangerous] dd with of=/dev/ detected. To proceed intentionally, explicitly say \"I confirm the dd write\"."}'
  exit 0
fi

# Firewall flush / disable
if echo "$cmd" | grep -qE '(^|[[:space:];|&`])(ufw[[:space:]]+disable|iptables[[:space:]]+-F|iptables[[:space:]]+-X|nft[[:space:]]+flush)'; then
  echo '{"continue": false, "stopReason": "[Firewall] Firewall disable or flush detected. To proceed intentionally, explicitly say \"I confirm the firewall operation\"."}'
  exit 0
fi

# User / password management
if echo "$cmd" | grep -qE '(^|[[:space:];|&`])(passwd|userdel|usermod)[[:space:]]'; then
  echo '{"continue": false, "stopReason": "[Account] passwd/userdel/usermod detected. To proceed intentionally, explicitly say \"I confirm the account operation\"."}'
  exit 0
fi

# Service stop / disable
if echo "$cmd" | grep -qE '(^|[[:space:];|&`])systemctl[[:space:]]+(stop|disable|mask)[[:space:]]'; then
  echo '{"continue": false, "stopReason": "[Service] systemctl stop/disable/mask detected. To proceed intentionally, explicitly say \"I confirm the service operation\"."}'
  exit 0
fi

# Crontab wipe
if echo "$cmd" | grep -qE '(^|[[:space:];|&`])crontab[[:space:]]+-r([[:space:]]|$)'; then
  echo '{"continue": false, "stopReason": "[Cron] crontab -r detected. To proceed intentionally, explicitly say \"I confirm the cron deletion\"."}'
  exit 0
fi

# Destructive DB operations via CLI
if echo "$cmd" | grep -qiE '(mysql|psql|mongo)[^|]*DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)'; then
  echo '{"continue": false, "stopReason": "[Database] DROP TABLE/DATABASE/SCHEMA detected. To proceed intentionally, explicitly say \"I confirm the DB deletion\"."}'
  exit 0
fi

# Redirect overwrite of system files (/etc/, /boot/, /usr/, /bin/, /sbin/, /lib/)
if echo "$cmd" | grep -qE '>[[:space:]]*/?(etc|boot|usr|bin|sbin|lib)/'; then
  echo '{"continue": false, "stopReason": "[System File] Redirect overwrite of a system path detected. To proceed intentionally, explicitly say \"I confirm the file overwrite\"."}'
  exit 0
fi
