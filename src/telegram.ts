/**
 * Telegram Bot API wrapper
 */

import TelegramBot from 'node-telegram-bot-api';

export interface SendMessageOptions {
  disableNotification?: boolean;
  parseMode?: 'Markdown' | 'HTML';
}

export interface ChatUpdate {
  chatId: number;
  username?: string;
  firstName?: string;
  message?: string;
  date: Date;
}

export class TelegramClient {
  private bot: TelegramBot;

  constructor(token: string) {
    // Create bot without polling - we only send messages
    this.bot = new TelegramBot(token, { polling: false });
  }

  /**
   * Send a message to a specific chat
   */
  async sendMessage(
    chatId: string | number,
    text: string,
    options: SendMessageOptions = {}
  ): Promise<{ success: boolean; messageId?: number; error?: string }> {
    try {
      const result = await this.bot.sendMessage(chatId, text, {
        disable_notification: options.disableNotification,
        parse_mode: options.parseMode,
      });

      return {
        success: true,
        messageId: result.message_id,
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      return {
        success: false,
        error: errorMessage,
      };
    }
  }

  /**
   * Get recent updates to find chat IDs from users who messaged the bot
   */
  async getUpdates(): Promise<ChatUpdate[]> {
    try {
      const updates = await this.bot.getUpdates({ limit: 100 });

      const chats: ChatUpdate[] = [];
      const seenChatIds = new Set<number>();

      for (const update of updates) {
        if (update.message?.chat) {
          const chat = update.message.chat;

          // Deduplicate by chat ID
          if (seenChatIds.has(chat.id)) continue;
          seenChatIds.add(chat.id);

          chats.push({
            chatId: chat.id,
            username: chat.username,
            firstName: chat.first_name,
            message: update.message.text,
            date: new Date(update.message.date * 1000),
          });
        }
      }

      return chats;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Failed to get updates: ${errorMessage}`);
    }
  }

  /**
   * Get bot info to verify token is valid
   */
  async getMe(): Promise<{ username: string; firstName: string }> {
    const me = await this.bot.getMe();
    return {
      username: me.username || 'unknown',
      firstName: me.first_name,
    };
  }
}
