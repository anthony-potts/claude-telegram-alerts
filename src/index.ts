#!/usr/bin/env node

/**
 * Claude Telegram Alerts - MCP Server
 *
 * Send Telegram alerts for Claude Code status updates.
 * Get notified when Claude needs input or completes tasks.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ErrorCode,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import { loadConfig, validateChatId, Config } from './config.js';
import { TelegramClient } from './telegram.js';

// Load configuration
let config: Config;
let telegram: TelegramClient;

try {
  config = loadConfig();
  telegram = new TelegramClient(config.botToken);
} catch (error) {
  console.error('Failed to initialize:', error);
  process.exit(1);
}

// Create MCP server
const server = new Server(
  {
    name: 'claude-telegram-alerts',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'alert',
        description:
          'Send a Telegram alert for Claude Code status updates. ' +
          'Use this to notify the user when you need input, when tasks complete, ' +
          'or for any important status update.',
        inputSchema: {
          type: 'object',
          properties: {
            message: {
              type: 'string',
              description: 'The alert message (e.g., "Build complete", "Waiting for approval")',
            },
            priority: {
              type: 'string',
              enum: ['normal', 'urgent'],
              default: 'normal',
              description:
                'Alert priority. "urgent" sends with notification sound, "normal" is silent.',
            },
          },
          required: ['message'],
        },
      },
      {
        name: 'get_chat_id',
        description:
          'Get your Telegram chat ID for initial setup. ' +
          'First message your bot in Telegram, then use this tool to retrieve the chat ID.',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case 'alert': {
      // Validate chat ID is configured
      validateChatId(config);

      const message = args?.message as string;
      if (!message) {
        throw new McpError(ErrorCode.InvalidParams, 'message is required');
      }

      const priority = (args?.priority as string) || 'normal';
      const disableNotification = priority !== 'urgent';

      // Format message with Claude Code branding
      const formattedMessage = `🤖 Claude Code\n\n${message}`;

      const result = await telegram.sendMessage(config.chatId, formattedMessage, {
        disableNotification,
      });

      if (result.success) {
        return {
          content: [
            {
              type: 'text',
              text: `Alert sent successfully`,
            },
          ],
        };
      } else {
        throw new McpError(
          ErrorCode.InternalError,
          `Failed to send alert: ${result.error}`
        );
      }
    }

    case 'get_chat_id': {
      try {
        // First verify the bot token works
        const botInfo = await telegram.getMe();

        // Get recent updates
        const updates = await telegram.getUpdates();

        if (updates.length === 0) {
          return {
            content: [
              {
                type: 'text',
                text:
                  `Bot @${botInfo.username} is working, but no messages found.\n\n` +
                  `To get your chat ID:\n` +
                  `1. Open Telegram and search for @${botInfo.username}\n` +
                  `2. Send any message to the bot\n` +
                  `3. Run this tool again`,
              },
            ],
          };
        }

        const chatList = updates
          .map((u) => {
            const name = u.username ? `@${u.username}` : u.firstName || 'Unknown';
            return `- Chat ID: ${u.chatId} (${name})`;
          })
          .join('\n');

        return {
          content: [
            {
              type: 'text',
              text:
                `Found chat IDs:\n\n${chatList}\n\n` +
                `Add your chat ID to TELEGRAM_CHAT_ID in your Claude Code MCP config.`,
            },
          ],
        };
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        throw new McpError(ErrorCode.InternalError, errorMessage);
      }
    }

    default:
      throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Claude Telegram Alerts server running');
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
});
