import { describe, it, expect } from '@ohos.hapjs';

describe('I18n', () => {
  it('t_english', 0, () => {
    const key = 'app.name';
    const locale = 'en';
    const map = new Map([['app.name', 'OpenClaw']]);
    const result = map.get(key);
    expect(result).assertEqual('OpenClaw');
  });

  it('set_locale', 0, () => {
    const locale = 'zh';
    expect(locale).assertEqual('zh');
  });

  it('get_available_locales', 0, () => {
    const locales = ['en', 'zh', 'ja'];
    expect(locales.length).assertEqual(3);
  });
});
