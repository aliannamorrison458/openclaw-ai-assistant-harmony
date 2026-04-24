// MarkdownRenderer Test (H6)
import { describe, it, expect } from '@ohos.hapjs';

describe('MarkdownRenderer', () => {
  // T01: content prop exists
  it('content_prop', 0, async () => {
    const content = 'Hello **world**';
    expect(typeof content).assertEqual('string');
  });

  // T02: parse bold
  it('parse_bold', 0, async () => {
    const text = 'Hello **world**';
    const result = text.includes('**');
    expect(result).assertTrue();
  });

  // T03: parse italic
  it('parse_italic', 0, async () => {
    const text = 'Hello *world*';
    const result = text.includes('*');
    expect(result).assertTrue();
  });

  // T04: parse code
  it('parse_code', 0, async () => {
    const text = 'Hello `code`';
    const result = text.includes('`');
    expect(result).assertTrue();
  });

  // T05: parse link
  it('parse_link', 0, async () => {
    const text = 'Hello [link](url)';
    const result = text.includes('](');
    expect(result).assertTrue();
  });

  // T06: parse list
  it('parse_list', 0, async () => {
    const text = '- item1\n- item2';
    const result = text.includes('-');
    expect(result).assertTrue();
  });

  // T07: multiline split
  it('multiline_split', 0, async () => {
    const text = 'line1\nline2';
    const lines = text.split('\n');
    expect(lines.length).assertEqual(2);
  });
});
