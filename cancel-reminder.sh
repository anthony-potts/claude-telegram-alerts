#!/bin/bash
# Cancel pending reminder and reset the "already sent" flag
PID_FILE="/tmp/claude-idle-reminder.pid"
SENT_FILE="/tmp/claude-idle-reminder.sent"

# Kill the tracked reminder
if [ -f "$PID_FILE" ]; then
  kill "$(cat "$PID_FILE")" 2>/dev/null
  rm -f "$PID_FILE"
fi

# Fallback: kill any orphaned reminder processes (e.g. from a previous PID file race)
pkill -f "idle-reminder.sh" 2>/dev/null

# Clear the "already sent" flag so future idle periods can trigger a new reminder
rm -f "$SENT_FILE"
