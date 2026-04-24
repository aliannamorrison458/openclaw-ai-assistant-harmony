// CodeHighlighter - Code syntax highlighting (H)
class CodeHighlighter {
  private static keywords: Map<string, string[]> = new Map([
    ['swift', ['func', 'var', 'let', 'class', 'struct', 'import', 'return', 'if', 'else', 'for', 'while', 'guard', 'switch', 'case', 'default', 'break', 'continue', 'throws', 'async', 'await', 'public', 'private', 'internal', 'static', 'final', 'override', 'init', 'deinit', 'self', 'super', 'nil', 'true', 'false']],
    ['kotlin', ['fun', 'val', 'var', 'class', 'object', 'import', 'return', 'if', 'else', 'for', 'while', 'when', 'sealed', 'data', 'companion', 'object', 'suspend', 'inline', 'crossinline', 'noinline', 'private', 'public', 'internal', 'protected', 'override', 'constructor', 'this', 'super', 'null', 'true', 'false', 'is', 'as', 'in', 'out']],
    ['python', ['def', 'class', 'import', 'from', 'return', 'if', 'elif', 'else', 'for', 'while', 'try', 'except', 'finally', 'with', 'as', 'pass', 'break', 'continue', 'raise', 'lambda', 'yield', 'global', 'nonlocal', 'True', 'False', 'None', 'and', 'or', 'not', 'in', 'is', 'async', 'await', 'await']],
    ['typescript', ['function', 'const', 'let', 'var', 'class', 'interface', 'type', 'enum', 'import', 'export', 'return', 'if', 'else', 'for', 'while', 'switch', 'case', 'default', 'break', 'continue', 'try', 'catch', 'finally', 'throw', 'async', 'await', 'public', 'private', 'protected', 'static', 'abstract', 'implements', 'extends', 'new', 'this', 'super', 'true', 'false', 'null', 'undefined', 'typeof', 'instanceof', 'in', 'of']],
    ['json', ['true', 'false', 'null']],
  ]);

  highlight(code: string, language: string): string {
    const keywords = CodeHighlighter.keywords.get(language) || [];
    let result = code;
    
    // Basic highlighting: bold keywords
    for (const kw of keywords) {
      const regex = new RegExp(`\\b(${kw})\\b`, 'g');
      result = result.replace(regex, '**$1**');
    }
    
    return result;
  }

  detectLanguage(code: string): string {
    if (code.includes('func ') || code.includes('let ') || code.includes('var ')) {
      return 'swift';
    }
    if (code.includes('fun ') || code.includes('val ') || code.includes('var ')) {
      return 'kotlin';
    }
    if (code.includes('def ') || code.includes('import ') && !code.includes('{') && !code.includes('}') && !code.includes('fun ')) {
      return 'python';
    }
    if (code.includes('function ') || code.includes('const ') || code.includes('interface ')) {
      return 'typescript';
    }
    if (code.startsWith('{') || code.startsWith('[')) {
      return 'json';
    }
    return 'plaintext';
  }
}

export default new CodeHighlighter();
