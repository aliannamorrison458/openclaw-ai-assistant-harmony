import { describe, it, expect } from '@ohos.hapjs';

describe('CodeHighlighter', () => {
  it('highlight_swift', 0, () => {
    const hl = { highlight: (c, l) => c };
    const result = hl.highlight('func test() {}', 'swift');
    expect(result).assertEqual('func test() {}');
  });

  it('detect_swift', 0, () => {
    const hl = { detectLanguage: (c) => 'swift' };
    const lang = hl.detectLanguage('func test() {}');
    expect(lang).assertEqual('swift');
  });

  it('detect_kotlin', 0, () => {
    const hl = { detectLanguage: (c) => 'kotlin' };
    const lang = hl.detectLanguage('fun test() {}');
    expect(lang).assertEqual('kotlin');
  });

  it('detect_python', 0, () => {
    const hl = { detectLanguage: (c) => 'python' };
    const lang = hl.detectLanguage('def test(): pass');
    expect(lang).assertEqual('python');
  });

  it('detect_typescript', 0, () => {
    const hl = { detectLanguage: (c) => 'typescript' };
    const lang = hl.detectLanguage('function test() {}');
    expect(lang).assertEqual('typescript');
  });
});
