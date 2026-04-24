// OpenAIClient Test (H4)
import { describe, it, expect } from '@ohos.hapjs';
import OpenAIClient from '../services/OpenAIClient';

describe('OpenAIClient', () => {
  it('constructor_default', 0, () => {
    const client = new OpenAIClient();
    expect(client !== null).assertTrue();
  });

  it('constructor_with_config', 0, () => {
    const client = new OpenAIClient({
      baseURL: 'http://test:8080',
      apiKey: 'test-key',
    });
    expect(client !== null).assertTrue();
  });

  it('reply_method_exists', 0, () => {
    const client = new OpenAIClient();
    expect(typeof client.reply).assertEqual('function');
  });

  it('replyStream_method_exists', 0, () => {
    const client = new OpenAIClient();
    expect(typeof client.replyStream).assertEqual('function');
  });
});
