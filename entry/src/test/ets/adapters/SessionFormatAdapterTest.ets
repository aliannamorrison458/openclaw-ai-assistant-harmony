// SessionFormatAdapter Test (H7)
import { describe, it, expect } from '@ohos.hapjs';

describe('SessionFormatAdapter', () => {
  // T01: fromiOS
  it('fromiOS', 0, async () => {
    const adapter = await import('../adapters/SessionFormatAdapter');
    const input = {
      id: 'test',
      title: 'Test',
      messages: [{ role: 'user', content: 'hi', createdAt: 123 }],
      createdAt: 123,
      updatedAt: 123,
    };
    const result = adapter.default.fromiOS(input);
    expect(result.id).assertEqual('test');
    expect(result.messages[0].role).assertEqual('user');
  });

  // T02: fromAndroid
  it('fromAndroid', 0, async () => {
    const adapter = await import('../adapters/SessionFormatAdapter');
    const input = {
      sessionId: 'test',
      sessionTitle: 'Test',
      messageList: [{ messageRole: 'user', messageContent: 'hi', messageTime: 123 }],
      createdTime: 123,
      updatedTime: 123,
    };
    const result = adapter.default.fromAndroid(input);
    expect(result.id).assertEqual('test');
  });

  // T03: toiOS
  it('toiOS', 0, async () => {
    const adapter = await import('../adapters/SessionFormatAdapter');
    const input = {
      id: 'test',
      title: 'Test',
      messages: [{ role: 'user', content: 'hi', timestamp: 123 }],
      createdAt: 123,
      updatedAt: 123,
    };
    const result = adapter.default.toiOS(input);
    expect(result.id).assertEqual('test');
  });

  // T04: toAndroid
  it('toAndroid', 0, async () => {
    const adapter = await import('../adapters/SessionFormatAdapter');
    const input = {
      id: 'test',
      title: 'Test',
      messages: [{ role: 'user', content: 'hi', timestamp: 123 }],
      createdAt: 123,
      updatedAt: 123,
    };
    const result = adapter.default.toAndroid(input);
    expect(result.sessionId).assertEqual('test');
  });

  // T05: toJSON / fromJSON
  it('toJSON_fromJSON', 0, async () => {
    const adapter = await import('../adapters/SessionFormatAdapter');
    const input = {
      id: 'test',
      title: 'Test',
      messages: [],
      createdAt: 123,
      updatedAt: 123,
    };
    const json = adapter.default.toJSON(input);
    const restored = adapter.default.fromJSON(json);
    expect(restored.id).assertEqual('test');
  });
});
