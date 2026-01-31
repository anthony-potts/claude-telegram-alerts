/**
 * Configuration management for Telegram MCP server
 */

export interface Config {
  botToken: string;
  chatId: string;
}

export function loadConfig(): Config {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;

  if (!botToken) {
    throw new Error(
      'TELEGRAM_BOT_TOKEN environment variable is required. ' +
      'Get a token from @BotFather on Telegram.'
    );
  }

  return {
    botToken,
    chatId: chatId || '', // Chat ID can be empty for get_chat_id tool
  };
}

export function validateChatId(config: Config): void {
  if (!config.chatId) {
    throw new Error(
      'TELEGRAM_CHAT_ID environment variable is required. ' +
      'Use the get_chat_id tool to retrieve your chat ID after messaging your bot.'
    );
  }
}
