// I18n - Internationalization
type Translations = Map<string, Map<string, string>>;

class I18n {
  private static TRANSLATIONS: Translations = new Map([
    ['en', new Map([
      ['app.name', 'OpenClaw'],
      ['chat.placeholder', 'Type a message...'],
      ['send', 'Send'],
      ['settings', 'Settings'],
      ['sessions', 'Sessions'],
      ['new.chat', 'New Chat'],
      ['delete', 'Delete'],
      ['rename', 'Rename'],
    ])],
    ['zh', new Map([
      ['app.name', 'OpenClaw'],
      ['chat.placeholder', '��入消息...'],
      ['send', '发送'],
      ['settings', '设置'],
      ['sessions', '会话'],
      ['new.chat', '新对话'],
      ['delete', '删除'],
      ['rename', '重命名'],
    ])],
    ['ja', new Map([
      ['app.name', 'OpenClaw'],
      ['chat.placeholder', 'メッセージを入力...'],
      ['send', '送信'],
      ['settings', '設定'],
      ['sessions', 'セッション'],
      ['new.chat', '新しいチャット'],
      ['delete', '削除'],
      ['rename', '名前変更'],
    ])],
  ]);

  private static currentLocale: string = 'en';

  static setLocale(locale: string) {
    if (I18n.TRANSLATIONS.has(locale)) {
      I18n.currentLocale = locale;
    }
  }

  static t(key: string): string {
    const locale = I18n.TRANSLATIONS.get(I18n.currentLocale);
    if (locale && locale.has(key)) {
      return locale.get(key);
    }
    return key;
  }

  static getAvailableLocales(): string[] {
    return Array.from(I18n.TRANSLATIONS.keys());
  }
}

export default I18n;
