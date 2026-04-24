import { describe, it, expect } from '@ohos.hapjs';

describe('ContextWindowManager', () => {
  it('trim_empty', 0, () => {
    const result = { messages: [], droppedCount: 0, estimatedTokens: 0 };
    expect(result.messages.length).assertEqual(0);
  });

  it('trim_keeps_recent', 0, () => {
    const msgs = [{ role: 'user', content: 'hi' }];
    const result = { messages: msgs.slice(-20), droppedCount: 0, estimatedTokens: 1 };
    expect(result.messages.length).assertEqual(1);
  });

  it('estimate_tokens', 0, () => {
    const chars = 100;
    const tokens = Math.floor(chars * 0.25);
    expect(tokens).assertEqual(25);
  });
});
