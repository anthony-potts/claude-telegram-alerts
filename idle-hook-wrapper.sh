#!/bin/bash
# Wrapper that captures stdin from Claude Code hook, then backgrounds the reminder
# This script receives JSON on stdin with session_id, transcript_path, cwd, etc.
#
# PID management lives HERE (not in idle-reminder.sh) to avoid a race condition:
# the hook runs synchronously, so the PID file is written before Claude continues
# and the user has a chance to respond (which triggers cancel-reminder.sh).

DELAY=${1:-120}
BASE_MESSAGE=${2:-"Claude Code is waiting for your input"}
PID_FILE="/tmp/claude-idle-reminder.pid"
SENT_FILE="/tmp/claude-idle-reminder.sent"
# Find wezterm CLI: use WEZTERM_EXECUTABLE_DIR (set by WezTerm), then PATH
WEZTERM_CLI="${WEZTERM_EXECUTABLE_DIR:+${WEZTERM_EXECUTABLE_DIR}/wezterm}"
if [ -z "$WEZTERM_CLI" ] || [ ! -x "$WEZTERM_CLI" ]; then
  WEZTERM_CLI=$(command -v wezterm 2>/dev/null || true)
fi

# Read JSON from stdin
INPUT=$(cat)

# Optional debug logging
if [ -n "$DEBUG_IDLE_HOOK" ]; then
  {
    echo "=== $(date -Iseconds) ==="
    echo "ARGS: $*"
    echo "STDIN JSON: $INPUT"
    echo "WEZTERM_PANE=$WEZTERM_PANE"
  } >> /tmp/claude-idle-debug.log
fi

# Don't queue another if one was already sent and user hasn't responded
if [ -f "$SENT_FILE" ]; then
  [ -n "$DEBUG_IDLE_HOOK" ] && echo "SENT_FILE exists, skipping" >> /tmp/claude-idle-debug.log
  exit 0
fi

# Extract fields from hook input
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
NOTIF_TITLE=$(echo "$INPUT" | jq -r '.title // empty')

if [ -n "$DEBUG_IDLE_HOOK" ]; then
  echo "CWD=$CWD  TITLE=$NOTIF_TITLE" >> /tmp/claude-idle-debug.log
fi

# Extract project directory name from cwd (last path component)
PROJECT_DIR=""
if [ -n "$CWD" ]; then
  PROJECT_DIR=$(basename "$CWD")
fi

# Try to get session context from WezTerm pane title (set by Claude Code)
PANE_TITLE=""
if [ -n "$WEZTERM_PANE" ] && [ -x "$WEZTERM_CLI" ]; then
  PANE_TITLE=$("$WEZTERM_CLI" cli list --format json 2>/dev/null \
    | jq -r --argjson pid "$WEZTERM_PANE" '.[] | select(.pane_id == $pid) | .title // empty' 2>/dev/null)
  # Strip leading status icons (spinner chars, checkmarks, etc.)
  PANE_TITLE=$(echo "$PANE_TITLE" | sed 's/^[^a-zA-Z0-9]* *//')
fi

# Build context: WezTerm title > notification title > nothing
CONTEXT=""
if [ -n "$PANE_TITLE" ]; then
  CONTEXT="$PANE_TITLE"
elif [ -n "$NOTIF_TITLE" ]; then
  CONTEXT="$NOTIF_TITLE"
fi

if [ -n "$DEBUG_IDLE_HOOK" ]; then
  echo "PROJECT_DIR=$PROJECT_DIR  PANE_TITLE=$PANE_TITLE  NOTIF_TITLE=$NOTIF_TITLE  CONTEXT=$CONTEXT" >> /tmp/claude-idle-debug.log
fi

# Build the message with project/context
if [ -n "$PROJECT_DIR" ] && [ -n "$CONTEXT" ]; then
  FULL_MESSAGE="[$PROJECT_DIR: $CONTEXT] $BASE_MESSAGE"
elif [ -n "$PROJECT_DIR" ]; then
  FULL_MESSAGE="[$PROJECT_DIR] $BASE_MESSAGE"
elif [ -n "$CONTEXT" ]; then
  FULL_MESSAGE="[$CONTEXT] $BASE_MESSAGE"
else
  FULL_MESSAGE="$BASE_MESSAGE"
fi

if [ -n "$DEBUG_IDLE_HOOK" ]; then
  echo "FULL_MESSAGE=$FULL_MESSAGE" >> /tmp/claude-idle-debug.log
  echo "---" >> /tmp/claude-idle-debug.log
fi

# Kill any existing pending reminder before starting a new one
if [ -f "$PID_FILE" ]; then
  kill "$(cat "$PID_FILE")" 2>/dev/null
  rm -f "$PID_FILE"
fi
# Also kill any orphaned reminders not tracked by PID file
pkill -f "idle-reminder.sh" 2>/dev/null

# Background the reminder and IMMEDIATELY record its PID (before returning)
nohup /Users/admin/dev/claude-telegram-alerts/idle-reminder.sh "$DELAY" "$FULL_MESSAGE" >/dev/null 2>&1 &
echo $! > "$PID_FILE"
