# Claude Telegram Alerts

An MCP server that sends Telegram alerts for Claude Code status updates. Get notified on your phone when:

- Claude needs your input or approval
- Long-running tasks complete
- Builds finish or tests pass/fail
- Any custom status update you configure

## Features

- **`alert`** - Send status alerts to your Telegram (normal or urgent priority)
- **`get_chat_id`** - Helper tool to retrieve your Telegram chat ID during setup

## Quick Start

### 1. Create a Telegram Bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Copy your bot token (e.g., `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Message Your Bot

Search for your new bot in Telegram and send it any message (e.g., "hi"). This enables the bot to message you back.

### 3. Install

```bash
git clone https://github.com/anthony-potts/claude-telegram-alerts.git
cd claude-telegram-alerts
npm install
npm run build
```

### 4. Configure Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "telegram-alerts": {
      "command": "node",
      "args": ["/path/to/claude-telegram-alerts/build/index.js"],
      "env": {
        "TELEGRAM_BOT_TOKEN": "your-bot-token",
        "TELEGRAM_CHAT_ID": ""
      }
    }
  }
}
```

### 5. Get Your Chat ID

Restart Claude Code, then ask:

> "Use the get_chat_id tool to find my Telegram chat ID"

Update your config with the returned chat ID, then restart Claude Code.

## Usage Examples

### Manual Alerts

```
"Send me a Telegram alert that the deployment is complete"

"Send an urgent alert that I need to approve the PR"
```

### Automated Workflows

```
"Run the test suite and alert me on Telegram when done"

"Deploy to staging and send me a Telegram alert with the result"

"When you need my input, send me a Telegram alert"
```

### Status Updates

```
"Alert me via Telegram: Build failed - missing dependency in package.json"

"Send Telegram alert: Waiting for approval to delete 50 files"
```

## Tools

### `alert`

Send a status alert to your Telegram.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | string | Yes | The alert message |
| `priority` | `"normal"` \| `"urgent"` | No | `urgent` = notification sound. Default: `normal` (silent) |

### `get_chat_id`

Retrieve your chat ID after messaging the bot. No parameters.

## Troubleshooting

| Error | Solution |
|-------|----------|
| "TELEGRAM_BOT_TOKEN required" | Add your bot token to the MCP server env config |
| "TELEGRAM_CHAT_ID required" | Run `get_chat_id` tool and add the result to config |
| "No messages found" | Send a message to your bot in Telegram first |
| Alerts not arriving | Check Telegram notifications aren't muted for the bot |

## Development

```bash
npm install      # Install dependencies
npm run build    # Compile TypeScript
npm run dev      # Watch mode
```

## License

MIT
