#!/bin/bash
# Delayed Telegram alert for Claude Code idle notifications
# Only sends ONE reminder until user responds
# Usage: idle-reminder.sh [delay_seconds] [message]

DELAY=${1:-60}
MESSAGE=${2:-"Claude Code is waiting for your input"}
PID_FILE="/tmp/claude-idle-reminder.pid"
SENT_FILE="/tmp/claude-idle-reminder.sent"
CLAUDE_CONFIG="$HOME/.claude.json"

# If we already sent a reminder and user hasn't responded, don't send another
if [ -f "$SENT_FILE" ]; then
  exit 0
fi

# Kill any existing pending reminder
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  kill "$OLD_PID" 2>/dev/null
  rm -f "$PID_FILE"
fi

# Store our PID
echo $$ > "$PID_FILE"

# Read credentials from Claude config
if [ -f "$CLAUDE_CONFIG" ] && command -v jq &> /dev/null; then
  TELEGRAM_BOT_TOKEN=$(jq -r '.mcpServers."telegram-alerts".env.TELEGRAM_BOT_TOKEN // empty' "$CLAUDE_CONFIG")
  TELEGRAM_CHAT_ID=$(jq -r '.mcpServers."telegram-alerts".env.TELEGRAM_CHAT_ID // empty' "$CLAUDE_CONFIG")
fi

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  rm -f "$PID_FILE"
  exit 1
fi

# Wait for the delay period
sleep "$DELAY"

# If we're still running (not killed), send the alert
if [ -f "$PID_FILE" ] && [ "$(cat "$PID_FILE")" = "$$" ]; then
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=Markdown" > /dev/null

  # Mark that we've sent a reminder - don't send again until user responds
  touch "$SENT_FILE"
  rm -f "$PID_FILE"
fi
