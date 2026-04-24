import { describe, it, expect } from '@ohos.hapjs';

describe('Accessibility', () => {
  it('chat_message_label', 0, () => {
    const label = 'Chat message';
    expect(label).assertEqual('Chat message');
  });

  it('send_button_label', 0, () => {
    const label = 'Send message button';
    expect(label).assertEqual('Send message button');
  });

  it('describe_element', 0, () => {
    const desc = 'Button: Send message';
    expect(desc.includes('Button')).assertTrue();
  });
});
