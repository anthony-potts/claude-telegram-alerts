#!/bin/bash
# Cancel pending reminder and reset the "already sent" flag
PID_FILE="/tmp/claude-idle-reminder.pid"
SENT_FILE="/tmp/claude-idle-reminder.sent"

# Kill any pending reminder
if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  kill "$PID" 2>/dev/null
  rm -f "$PID_FILE"
fi

# Clear the "already sent" flag so future idle periods can trigger a new reminder
rm -f "$SENT_FILE"
