#!/bin/bash
# Wrapper that captures stdin from Claude Code hook, then backgrounds the reminder
# This script receives JSON on stdin with session_id, transcript_path, etc.

DELAY=${1:-120}
BASE_MESSAGE=${2:-"Claude Code is waiting for your input"}

# Read JSON from stdin
INPUT=$(cat)

# Extract session info
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Try to find session name from sessions-index.json
SESSION_NAME=""
if [ -n "$CWD" ] && [ -n "$SESSION_ID" ]; then
  # Convert CWD to Claude's project path format (replace / with -)
  PROJECT_PATH=$(echo "$CWD" | sed 's|^/||; s|/|-|g')
  INDEX_FILE="$HOME/.claude/projects/-${PROJECT_PATH}/sessions-index.json"

  if [ -f "$INDEX_FILE" ]; then
    # Look up session summary by sessionId
    SESSION_NAME=$(jq -r --arg sid "$SESSION_ID" '.entries[] | select(.sessionId == $sid) | .summary // empty' "$INDEX_FILE" 2>/dev/null)
  fi
fi

# Build the message with session context
if [ -n "$SESSION_NAME" ]; then
  FULL_MESSAGE="[$SESSION_NAME] $BASE_MESSAGE"
else
  FULL_MESSAGE="$BASE_MESSAGE"
fi

# Now background the actual reminder script with the session-aware message
nohup /Users/admin/dev/claude-telegram-alerts/idle-reminder.sh "$DELAY" "$FULL_MESSAGE" >/dev/null 2>&1 &
