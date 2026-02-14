#!/bin/bash
# Delayed Telegram alert for Claude Code idle notifications
# Only sends ONE reminder until user responds
# Usage: idle-reminder.sh [delay_seconds] [message]
#
# PID management is handled by idle-hook-wrapper.sh (the caller).
# This script just sleeps, verifies it's still the active reminder, and sends.

DELAY=${1:-60}
MESSAGE=${2:-"Claude Code is waiting for your input"}
PID_FILE="/tmp/claude-idle-reminder.pid"
SENT_FILE="/tmp/claude-idle-reminder.sent"
CLAUDE_CONFIG="$HOME/.claude.json"

# Read credentials from Claude config
if [ -f "$CLAUDE_CONFIG" ] && command -v jq &> /dev/null; then
  TELEGRAM_BOT_TOKEN=$(jq -r '.mcpServers."telegram-alerts".env.TELEGRAM_BOT_TOKEN // empty' "$CLAUDE_CONFIG")
  TELEGRAM_CHAT_ID=$(jq -r '.mcpServers."telegram-alerts".env.TELEGRAM_CHAT_ID // empty' "$CLAUDE_CONFIG")
fi

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  exit 1
fi

# Wait for the delay period
sleep "$DELAY"

# Verify we're still the active reminder (PID file matches our PID) and not already sent
if [ -f "$PID_FILE" ] && [ "$(cat "$PID_FILE")" = "$$" ] && [ ! -f "$SENT_FILE" ]; then
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=Markdown" > /dev/null

  # Mark that we've sent a reminder - don't send again until user responds
  touch "$SENT_FILE"
  rm -f "$PID_FILE"
fi
