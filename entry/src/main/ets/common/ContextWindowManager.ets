// ContextWindowManager - Token budget management
interface TrimResult {
  messages: Array<{ role: string; content: string }>;
  droppedCount: number;
  estimatedTokens: number;
}

class ContextWindowManager {
  private static ESTIMATED_TOKENS_PER_CHAR = 0.25;

  static trimMessages(
    messages: Array<{ role: string; content: string }>,
    maxTokens: number
  ): TrimResult {
    if (messages.length === 0) {
      return { messages: [], droppedCount: 0, estimatedTokens: 0 };
    }

    const truncated = messages.slice(-20); // Keep last 20 messages
    let totalChars = 0;
    for (const msg of truncated) {
      totalChars += msg.content.length;
    }
    const estimatedTokens = Math.floor(totalChars * ContextWindowManager.ESTIMATED_TOKENS_PER_CHAR);

    return {
      messages: truncated,
      droppedCount: Math.max(0, messages.length - truncated.length),
      estimatedTokens: estimatedTokens,
    };
  }
}

export default ContextWindowManager;
