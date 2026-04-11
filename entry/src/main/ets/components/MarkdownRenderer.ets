// MarkdownRenderer.ets — 基于正则解析的 Markdown 渲染组件（深色模式适配）
// 支持：标题(#~######)、加粗(**)、斜体(*)、代码块(```)、行内代码(`)、列表(-/*/1.)、链接([text](url))
import { tc } from '../common/DarkModeManager';

interface InlineSegment {
  type: 'text' | 'bold' | 'italic' | 'inlineCode' | 'link';
  content: string;
  url?: string;
}

@Builder
function renderInlineText(segments: InlineSegment[]) {
  Row() {
    ForEach(segments, (seg: InlineSegment) => {
      if (seg.type === 'text') {
        Text(seg.content)
          .fontSize(15)
          .fontColor(tc('color_md_text'))
      } else if (seg.type === 'bold') {
        Text(seg.content)
          .fontSize(15)
          .fontColor(tc('color_md_bold'))
          .fontWeight(FontWeight.Bold)
      } else if (seg.type === 'italic') {
        Text(seg.content)
          .fontSize(15)
          .fontColor(tc('color_md_text'))
          .fontStyle(FontStyle.Italic)
      } else if (seg.type === 'inlineCode') {
        Text(seg.content)
          .fontSize(14)
          .fontColor(tc('color_md_inline_code'))
          .backgroundColor(tc('color_md_inline_code_bg'))
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
      } else if (seg.type === 'link') {
        Text(seg.content)
          .fontSize(15)
          .fontColor(tc('color_md_link'))
          .decoration({ type: TextDecorationType.Underline, color: tc('color_md_link') })
          .onClick(() => {
            if (seg.url) {
              // 链接点击 — 使用 ArkTS openURL
              try {
                import('@kit.ArkUI').then((ui) => {
                  // fallback: just log
                  console.info('[MarkdownRenderer] Link clicked:', seg.url);
                });
              } catch (e) {
                console.info('[MarkdownRenderer] Link:', seg.url);
              }
            }
          })
      }
    }, (seg: InlineSegment, idx: number) => `${idx}-${seg.type}`)
  }
  .flexWrap(FlexWrap.Wrap)
}

// ============== 语法高亮关键词 ==============
const PYTHON_KEYWORDS: string[] = [
  'import', 'from', 'def', 'class', 'return', 'if', 'elif', 'else', 'for', 'while',
  'try', 'except', 'finally', 'with', 'as', 'yield', 'async', 'await', 'break',
  'continue', 'pass', 'raise', 'lambda', 'in', 'is', 'not', 'and', 'or', 'True',
  'False', 'None', 'print', 'self', 'super', 'global', 'nonlocal'
];

const JS_KEYWORDS: string[] = [
  'import', 'export', 'from', 'const', 'let', 'var', 'function', 'return', 'if',
  'else', 'for', 'while', 'do', 'switch', 'case', 'break', 'continue', 'class',
  'extends', 'new', 'this', 'try', 'catch', 'finally', 'throw', 'async', 'await',
  'typeof', 'instanceof', 'null', 'undefined', 'true', 'false', 'yield', 'of', 'in'
];

const KOTLIN_KEYWORDS: string[] = [
  'import', 'package', 'fun', 'val', 'var', 'class', 'object', 'interface', 'when',
  'if', 'else', 'for', 'while', 'do', 'try', 'catch', 'finally', 'throw', 'return',
  'break', 'continue', 'is', 'in', 'as', 'by', 'lazy', 'companion', 'override',
  'open', 'abstract', 'data', 'sealed', 'enum', 'suspend', 'init', 'constructor',
  'true', 'false', 'null', 'this', 'super', 'it', 'Unit', 'Nothing'
];

// 简易语法高亮 token
interface HighlightToken {
  type: 'plain' | 'keyword' | 'string' | 'comment' | 'number' | 'punctuation';
  text: string;
}

function tokenizeCode(code: string, lang: string): HighlightToken[] {
  let keywords: string[] = [];
  if (lang === 'python') keywords = PYTHON_KEYWORDS;
  else if (lang === 'javascript' || lang === 'js' || lang === 'typescript' || lang === 'ts') keywords = JS_KEYWORDS;
  else if (lang === 'kotlin' || lang === 'kt') keywords = KOTLIN_KEYWORDS;
  else keywords = PYTHON_KEYWORDS; // default fallback

  const tokens: HighlightToken[] = [];
  let i = 0;
  while (i < code.length) {
    // 行注释
    if (code[i] === '/' && code[i + 1] === '/') {
      let end = code.indexOf('\n', i);
      if (end === -1) end = code.length;
      tokens.push({ type: 'comment', text: code.substring(i, end) });
      i = end;
      continue;
    }
    // Python 注释
    if (code[i] === '#' && (lang === 'python' || lang === 'python3')) {
      let end = code.indexOf('\n', i);
      if (end === -1) end = code.length;
      tokens.push({ type: 'comment', text: code.substring(i, end) });
      i = end;
      continue;
    }
    // 字符串（双引号 / 单引号 / 三引号）
    if (code[i] === '"' || code[i] === "'") {
      const quote = code[i];
      let end = i + 1;
      while (end < code.length && code[end] !== quote) {
        if (code[end] === '\\') end++; // skip escaped char
        end++;
      }
      end++; // include closing quote
      tokens.push({ type: 'string', text: code.substring(i, end) });
      i = end;
      continue;
    }
    // 数字
    if (/[0-9]/.test(code[i])) {
      let end = i;
      while (end < code.length && /[0-9.]/.test(code[end])) end++;
      tokens.push({ type: 'number', text: code.substring(i, end) });
      i = end;
      continue;
    }
    // 标识符 / 关键字
    if (/[a-zA-Z_]/.test(code[i])) {
      let end = i;
      while (end < code.length && /[a-zA-Z0-9_]/.test(code[end])) end++;
      const word = code.substring(i, end);
      const type = keywords.includes(word) ? 'keyword' : 'plain';
      tokens.push({ type: type, text: word });
      i = end;
      continue;
    }
    // 标点
    if (/[{}()\[\];,.<>:=+\-*\/&|!@%^~?]/.test(code[i])) {
      tokens.push({ type: 'punctuation', text: code[i] });
      i++;
      continue;
    }
    // 其余（空格等）
    tokens.push({ type: 'plain', text: code[i] });
    i++;
  }
  return tokens;
}

function highlightColor(type: string): string {
  switch (type) {
    case 'keyword': return tc('color_code_keyword');
    case 'string': return tc('color_code_string');
    case 'comment': return tc('color_code_comment');
    case 'number': return tc('color_code_number');
    case 'punctuation': return tc('color_code_punctuation');
    default: return tc('color_code_plain');
  }
}

@Builder
function renderHighlightedCode(tokens: HighlightToken[]) {
  Row() {
    ForEach(tokens, (tok: HighlightToken, idx: number) => {
      Text(tok.text)
        .fontSize(13)
        .fontFamily('monospace')
        .fontColor(highlightColor(tok.type))
        .fontWeight(tok.type === 'keyword' ? FontWeight.Bold : FontWeight.Normal)
    }, (tok: HighlightToken, idx: number) => `${idx}`)
  }
  .flexWrap(FlexWrap.Wrap)
}

// ============== 解析逻辑 ==============

// 解析行内元素：加粗、斜体、行内代码、链接
function parseInlineElements(text: string): InlineSegment[] {
  const segments: InlineSegment[] = [];
  // regex: **bold**, *italic*, `code`, [text](url)
  const pattern = /(\*\*(.+?)\*\*)|(\*(.+?)\*)|(`(.+?)`)|(\[(.+?)\]\((.+?)\))/g;
  let lastIndex = 0;
  let match = pattern.exec(text);

  while (match) {
    // 文本段
    if (match.index > lastIndex) {
      segments.push({ type: 'text', content: text.substring(lastIndex, match.index) });
    }
    if (match[1]) {
      // bold **...**
      segments.push({ type: 'bold', content: match[2] });
    } else if (match[3]) {
      // italic *...*
      segments.push({ type: 'italic', content: match[4] });
    } else if (match[5]) {
      // inline code `...`
      segments.push({ type: 'inlineCode', content: match[6] });
    } else if (match[7]) {
      // link [text](url)
      segments.push({ type: 'link', content: match[8], url: match[9] });
    }
    lastIndex = match.index + match[0].length;
    match = pattern.exec(text);
  }
  // 尾部文本
  if (lastIndex < text.length) {
    segments.push({ type: 'text', content: text.substring(lastIndex) });
  }
  return segments;
}

// Markdown 块类型
interface MdBlock {
  type: 'heading' | 'paragraph' | 'code' | 'listItem' | 'emptyLine';
  level?: number;       // heading level 1-6
  content: string;
  lang?: string;        // code block language
  listType?: 'bullet' | 'ordered';
  indent?: number;      // list indent level
}

function parseMarkdownBlocks(text: string): MdBlock[] {
  const lines = text.split('\n');
  const blocks: MdBlock[] = [];
  let inCodeBlock = false;
  let codeLang = '';
  let codeLines: string[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // 代码块开始/结束
    if (line.trimStart().startsWith('```')) {
      if (!inCodeBlock) {
        inCodeBlock = true;
        codeLang = line.trim().replace('```', '').trim().toLowerCase();
        codeLines = [];
      } else {
        inCodeBlock = false;
        blocks.push({ type: 'code', content: codeLines.join('\n'), lang: codeLang });
      }
      continue;
    }
    if (inCodeBlock) {
      codeLines.push(line);
      continue;
    }

    // 空行
    if (line.trim().length === 0) {
      blocks.push({ type: 'emptyLine', content: '' });
      continue;
    }

    // 标题
    const headingMatch = line.match(/^(#{1,6})\s+(.+)/);
    if (headingMatch) {
      blocks.push({ type: 'heading', level: headingMatch[1].length, content: headingMatch[2] });
      continue;
    }

    // 无序列表
    const bulletMatch = line.match(/^(\s*)[-*+]\s+(.+)/);
    if (bulletMatch) {
      const indent = Math.floor(bulletMatch[1].length / 2);
      blocks.push({ type: 'listItem', content: bulletMatch[2], listType: 'bullet', indent: indent });
      continue;
    }

    // 有序列表
    const orderedMatch = line.match(/^(\s*)\d+\.\s+(.+)/);
    if (orderedMatch) {
      const indent = Math.floor(orderedMatch[1].length / 2);
      blocks.push({ type: 'listItem', content: orderedMatch[2], listType: 'ordered', indent: indent });
      continue;
    }

    // 段落
    blocks.push({ type: 'paragraph', content: line });
  }

  // 未关闭的代码块
  if (inCodeBlock) {
    blocks.push({ type: 'code', content: codeLines.join('\n'), lang: codeLang });
  }

  return blocks;
}

// ============== 渲染组件 ==============

@Component
export struct MarkdownRenderer {
  @Prop @Watch('contentChanged') content: string = '';

  private blocks: MdBlock[] = [];

  contentChanged() {
    this.blocks = parseMarkdownBlocks(this.content);
  }

  aboutToAppear() {
    this.blocks = parseMarkdownBlocks(this.content);
  }

  private headingFontSize(level: number): number {
    switch (level) {
      case 1: return 26;
      case 2: return 22;
      case 3: return 20;
      case 4: return 18;
      case 5: return 16;
      case 6: return 15;
      default: return 15;
    }
  }

  private listBulletMarker(indent: number, listType: string | undefined): string {
    if (listType === 'ordered') return '  '.repeat(Math.max(0, indent - 1)) + '• ';
    return '  '.repeat(Math.max(0, indent - 1)) + '• ';
  }

  build() {
    Column() {
      ForEach(this.blocks, (block: MdBlock, blockIdx: number) => {
        if (block.type === 'emptyLine') {
          // 空行间距
          Blank()
            .height(8)
        } else if (block.type === 'heading') {
          Text(block.content)
            .fontSize(this.headingFontSize(block.level))
            .fontWeight(FontWeight.Bold)
            .fontColor(tc('color_md_heading'))
            .margin({ top: 12, bottom: 4 })
        } else if (block.type === 'code') {
          // 代码块带语法高亮
          Column() {
            // 语言标签
            if (block.lang) {
              Row() {
                Text(block.lang)
                  .fontSize(11)
                  .fontColor(tc('color_md_lang_label'))
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .padding({ left: 12, top: 6, bottom: 4 })
            }

            // 代码内容
            Scroll() {
              let tokens = tokenizeCode(block.content, block.lang || '');
              renderHighlightedCode(tokens)
            }
            .scrollable(ScrollDirection.Horizontal)
            .width('100%')
            .padding({ left: 12, right: 12, bottom: 10 })
          }
          .width('100%')
          .backgroundColor(tc('color_md_code_bg'))
          .borderRadius(8)
          .border({ width: 1, color: tc('color_md_code_border') })
          .margin({ top: 4, bottom: 4 })
        } else if (block.type === 'listItem') {
          Row() {
            Text(this.listBulletMarker(block.indent, block.listType))
              .fontSize(15)
              .fontColor(tc('color_md_text'))
            let segs = parseInlineElements(block.content);
            Row() {
              ForEach(segs, (seg: InlineSegment) => {
                if (seg.type === 'text') {
                  Text(seg.content).fontSize(15).fontColor(tc('color_md_text'))
                } else if (seg.type === 'bold') {
                  Text(seg.content).fontSize(15).fontColor(tc('color_md_bold')).fontWeight(FontWeight.Bold)
                } else if (seg.type === 'italic') {
                  Text(seg.content).fontSize(15).fontColor(tc('color_md_text')).fontStyle(FontStyle.Italic)
                } else if (seg.type === 'inlineCode') {
                  Text(seg.content)
                    .fontSize(14).fontColor(tc('color_md_inline_code')).backgroundColor(tc('color_md_inline_code_bg'))
                    .borderRadius(4).padding({ left: 4, right: 4, top: 1, bottom: 1 })
                } else if (seg.type === 'link') {
                  Text(seg.content)
                    .fontSize(15).fontColor(tc('color_md_link'))
                    .decoration({ type: TextDecorationType.Underline, color: tc('color_md_link') })
                    .onClick(() => {
                      if (seg.url) {
                        console.info('[MarkdownRenderer] Link:', seg.url);
                      }
                    })
                }
              }, (seg: InlineSegment, idx: number) => `${blockIdx}-${idx}-${seg.type}`)
            }
            .flexWrap(FlexWrap.Wrap)
            .layoutWeight(1)
          }
          .margin({ left: (block.indent || 0) * 16, top: 2, bottom: 2 })
        } else if (block.type === 'paragraph') {
          let segs = parseInlineElements(block.content);
          Row() {
            ForEach(segs, (seg: InlineSegment) => {
              if (seg.type === 'text') {
                Text(seg.content).fontSize(15).fontColor(tc('color_md_text'))
              } else if (seg.type === 'bold') {
                Text(seg.content).fontSize(15).fontColor(tc('color_md_bold')).fontWeight(FontWeight.Bold)
              } else if (seg.type === 'italic') {
                Text(seg.content).fontSize(15).fontColor(tc('color_md_text')).fontStyle(FontStyle.Italic)
              } else if (seg.type === 'inlineCode') {
                Text(seg.content)
                  .fontSize(14).fontColor(tc('color_md_inline_code')).backgroundColor(tc('color_md_inline_code_bg'))
                  .borderRadius(4).padding({ left: 4, right: 4, top: 1, bottom: 1 })
              } else if (seg.type === 'link') {
                Text(seg.content)
                  .fontSize(15).fontColor(tc('color_md_link'))
                  .decoration({ type: TextDecorationType.Underline, color: tc('color_md_link') })
                  .onClick(() => {
                    if (seg.url) {
                      console.info('[MarkdownRenderer] Link:', seg.url);
                    }
                  })
              }
            }, (seg: InlineSegment, idx: number) => `${blockIdx}-${idx}-${seg.type}`)
          }
          .flexWrap(FlexWrap.Wrap)
          .width('100%')
          .margin({ top: 2, bottom: 2 })
        }
      }, (block: MdBlock, idx: number) => `${idx}-${block.type}`)
    }
    .width('100%')
  }
}
