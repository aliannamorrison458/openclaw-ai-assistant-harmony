// SettingsPage.ets — 设置页面（含深色模式切换）
import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { i18n } from '@kit.LocalizationKit';
import { preferences } from '@kit.ArkData';
import { DarkModeSetting, tc, setDarkModeSetting, getDarkModeSetting } from '../common/DarkModeManager';

const LANG_PREF_KEY = 'app_language';
const PREF_NAME = 'ai_assistant_prefs';
const SYSTEM_PROMPT_KEY = 'system_prompt';
const MAX_PROMPT_LENGTH = 2000;

// 预设模板
const PROMPT_TEMPLATES: Record<string, string> = {
  'professional': '你是一位专业的AI助手，擅长分析问题并提供准确、有条理的回答。请用简洁专业的语言回复。',
  'translator': '你是一位精通多语言的翻译专家。请准确翻译用户输入的内容，保持原文的语气和风格。如果原文有歧义，请提供最可能的翻译并在括号中注明备选翻译。',
  'coder': '你是一位资深软件工程师，精通多种编程语言和技术栈。请提供高质量的代码解决方案，包含必要的注释。优先考虑代码的可读性、性能和安全性。',
  'writer': '你是一位经验丰富的写作助手，擅长各类文体的创作和润色。请帮助用户优化文字表达，提升文章的逻辑性和可读性，同时保持用户的个人风格。'
};

@Entry
@Component
struct SettingsPage {
  @State baseURL: string = 'https://api.openai.com/v1';
  @State apiKey: string = '';
  @State useMock: boolean = true;
  @State model: string = 'gpt-3.5-turbo';
  @State saved: boolean = false;
  @State selectedLanguage: string = 'follow_system';
  @StorageProp('darkModeSetting') darkMode: DarkModeSetting = 'system';

  @State systemPrompt: string = '';
  @State selectedTemplate: string = '';

  private viewModel: ChatViewModel | null = null;

  aboutToAppear() {
    this.viewModel = (globalThis as any).chatViewModel as ChatViewModel;
    if (this.viewModel) {
      this.viewModel.loadSettings().then((settings) => {
        this.baseURL = settings.baseURL;
        this.apiKey = settings.apiKey;
        this.useMock = settings.useMock;
        this.model = settings.model;
      });
      this.viewModel.getSystemPrompt().then((prompt) => {
        this.systemPrompt = prompt;
      });
    }
    this.loadLanguagePreference();
  }

  private async loadLanguagePreference(): Promise<void> {
    try {
      const prefStore = await preferences.getPreferences(globalThis.context, PREF_NAME);
      this.selectedLanguage = await prefStore.get(LANG_PREF_KEY, 'follow_system') as string;
    } catch (e) {
      console.error('[SettingsPage] load language pref error:', JSON.stringify(e));
    }
  }

  private async applyLanguage(lang: string): Promise<void> {
    this.selectedLanguage = lang;
    try {
      const prefStore = await preferences.getPreferences(globalThis.context, PREF_NAME);
      await prefStore.put(LANG_PREF_KEY, lang);
      await prefStore.flush();

      // Apply locale using i18n API
      if (lang === 'follow_system') {
        // Reset to system locale
        i18n.System.setSystemLocale(i18n.System.getSystemLocale());
      } else {
        const locale = new i18n.Locale(lang);
        i18n.System.setSystemLocale(lang);
      }
    } catch (e) {
      console.error('[SettingsPage] save language error:', JSON.stringify(e));
    }
  }

  private getLanguageLabel(lang: string): string {
    switch (lang) {
      case 'follow_system': return $r('app.string.settings_language_follow_system').toString();
      case 'zh_CN': return $r('app.string.settings_language_zh_cn').toString();
      case 'en_US': return $r('app.string.settings_language_en_us').toString();
      case 'ja_JP': return $r('app.string.settings_language_ja_jp').toString();
      default: return lang;
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text($r('app.string.btn_back'))
          .fontSize(16)
          .fontColor(tc('color_accent'))
          .onClick(() => router.back())

        Blank()

        Text($r('app.string.settings_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(tc('color_text_primary'))

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(tc('color_surface'))

      Scroll() {
        Column({ space: 16 }) {
          // === 深色模式设置 ===
          Text('外观')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(tc('color_text_primary'))
            .width('100%')
            .margin({ top: 16 })

          Column({ space: 8 }) {
            Text('深色模式')
              .fontSize(15)
              .fontColor(tc('color_text_primary'))

            Row({ space: 12 }) {
              // 跟随系统
              Button('跟随系统')
                .fontSize(13)
                .height(36)
                .fontColor(this.darkMode === 'system' ? tc('color_text_on_accent') : tc('color_text_secondary'))
                .backgroundColor(this.darkMode === 'system' ? tc('color_accent') : tc('color_surface_alt'))
                .borderRadius(18)
                .onClick(() => {
                  setDarkModeSetting('system');
                })

              // 强制亮色
              Button('亮色')
                .fontSize(13)
                .height(36)
                .fontColor(this.darkMode === 'light' ? tc('color_text_on_accent') : tc('color_text_secondary'))
                .backgroundColor(this.darkMode === 'light' ? tc('color_accent') : tc('color_surface_alt'))
                .borderRadius(18)
                .onClick(() => {
                  setDarkModeSetting('light');
                })

              // 强制暗色
              Button('暗色')
                .fontSize(13)
                .height(36)
                .fontColor(this.darkMode === 'dark' ? tc('color_text_on_accent') : tc('color_text_secondary'))
                .backgroundColor(this.darkMode === 'dark' ? tc('color_accent') : tc('color_surface_alt'))
                .borderRadius(18)
                .onClick(() => {
                  setDarkModeSetting('dark');
                })
            }
            .width('100%')
          }

          Divider()
            .color(tc('color_divider'))
            .margin({ top: 8, bottom: 8 })

          // Language Section
          Text($r('app.string.settings_language'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(tc('color_text_primary'))
            .width('100%')

          // Language selector
          Column({ space: 8 }) {
            this.buildLanguageOption('follow_system', $r('app.string.settings_language_follow_system').toString())
            Divider().color(tc('color_divider'))
            this.buildLanguageOption('zh_CN', $r('app.string.settings_language_zh_cn').toString())
            Divider().color(tc('color_divider'))
            this.buildLanguageOption('en_US', $r('app.string.settings_language_en_us').toString())
            Divider().color(tc('color_divider'))
            this.buildLanguageOption('ja_JP', $r('app.string.settings_language_ja_jp').toString())
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .backgroundColor(tc('color_surface'))
          .borderRadius(8)

          Divider()
            .color(tc('color_divider'))
            .margin({ top: 8, bottom: 8 })

          // === 系统 Prompt 设置 ===
          Text('系统 Prompt')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(tc('color_text_primary'))
            .width('100%')

          // 预设模板选择
          Text('预设模板')
            .fontSize(13)
            .fontColor(tc('color_text_secondary'))
            .width('100%')

          Row({ space: 8 }) {
            this.buildTemplateButton('professional', '专业助手')
            this.buildTemplateButton('translator', '翻译')
            this.buildTemplateButton('coder', '编程')
            this.buildTemplateButton('writer', '写作')
          }
          .width('100%')
          .flexWrap(FlexWrap.Wrap)

          // TextArea 编辑
          TextArea({ text: this.systemPrompt, placeholder: '输入自定义系统 Prompt，定义 AI 助手的行为和风格...' })
            .width('100%')
            .height(160)
            .fontSize(14)
            .fontColor(tc('color_text_primary'))
            .placeholderColor(tc('color_text_placeholder'))
            .backgroundColor(tc('color_surface_alt'))
            .borderRadius(8)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .maxLength(MAX_PROMPT_LENGTH)
            .onChange((value: string) => {
              this.systemPrompt = value;
              this.selectedTemplate = '';
            })

          // 字数计数器
          Row() {
            if (this.systemPrompt.length > MAX_PROMPT_LENGTH) {
              Text(`⚠️ 已超出 ${this.systemPrompt.length - MAX_PROMPT_LENGTH} 字`)
                .fontSize(12)
                .fontColor('#E53935')
            } else {
              Text(`${this.systemPrompt.length} / ${MAX_PROMPT_LENGTH}`)
                .fontSize(12)
                .fontColor(this.systemPrompt.length > MAX_PROMPT_LENGTH * 0.9 ? '#FF9800' : tc('color_text_tertiary'))
            }
            Blank()
            Button('重置')
              .fontSize(12)
              .height(28)
              .padding({ left: 12, right: 12 })
              .fontColor(tc('color_text_secondary'))
              .backgroundColor(tc('color_surface_alt'))
              .borderRadius(14)
              .onClick(() => {
                this.systemPrompt = '';
                this.selectedTemplate = '';
                if (this.viewModel) {
                  this.viewModel.saveSystemPrompt('');
                }
              })
          }
          .width('100%')

          Divider()
            .color(tc('color_divider'))
            .margin({ top: 8, bottom: 8 })

          // API Configuration Section
          Text($r('app.string.settings_api_config'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(tc('color_text_primary'))
            .width('100%')

          // Base URL
          Column({ space: 4 }) {
            Text($r('app.string.settings_api_base_url'))
              .fontSize(13)
              .fontColor(tc('color_text_secondary'))
            TextInput({ text: this.baseURL, placeholder: 'https://api.openai.com/v1' })
              .width('100%')
              .height(40)
              .fontSize(14)
              .fontColor(tc('color_text_primary'))
              .placeholderColor(tc('color_text_placeholder'))
              .padding({ left: 12, right: 12 })
              .backgroundColor(tc('color_surface_alt'))
              .borderRadius(8)
              .onChange((v: string) => this.baseURL = v)
          }

          // API Key
          Column({ space: 4 }) {
            Text($r('app.string.settings_api_key'))
              .fontSize(13)
              .fontColor(tc('color_text_secondary'))
            TextInput({ text: this.apiKey, placeholder: 'sk-...' })
              .width('100%')
              .height(40)
              .fontSize(14)
              .fontColor(tc('color_text_primary'))
              .placeholderColor(tc('color_text_placeholder'))
              .type(InputType.Password)
              .padding({ left: 12, right: 12 })
              .backgroundColor(tc('color_surface_alt'))
              .borderRadius(8)
              .onChange((v: string) => this.apiKey = v)
          }

          // Model
          Column({ space: 4 }) {
            Text($r('app.string.settings_model'))
              .fontSize(13)
              .fontColor(tc('color_text_secondary'))
            TextInput({ text: this.model, placeholder: 'gpt-3.5-turbo' })
              .width('100%')
              .height(40)
              .fontSize(14)
              .fontColor(tc('color_text_primary'))
              .placeholderColor(tc('color_text_placeholder'))
              .padding({ left: 12, right: 12 })
              .backgroundColor(tc('color_surface_alt'))
              .borderRadius(8)
              .onChange((v: string) => this.model = v)
          }

          // Use Mock toggle
          Row() {
            Text($r('app.string.settings_mock_mode'))
              .fontSize(15)
              .fontColor(tc('color_text_primary'))
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.useMock })
              .onChange((isOn: boolean) => this.useMock = isOn)
          }
          .width('100%')

          Text($r('app.string.settings_mock_desc'))
            .fontSize(12)
            .fontColor(tc('color_text_tertiary'))
            .width('100%')

          Divider()
            .color(tc('color_divider'))
            .margin({ top: 8, bottom: 8 })

          // Save button
          Button($r('app.string.settings_save'))
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontColor(tc('color_text_on_accent'))
            .backgroundColor(tc('color_accent'))
            .borderRadius(8)
            .onClick(() => this.saveSettings())

          if (this.saved) {
            Text($r('app.string.settings_saved'))
              .fontSize(14)
              .fontColor(tc('color_success'))
              .textAlign(TextAlign.Center)
              .width('100%')
          }

          Divider()
            .color(tc('color_divider'))
            .margin({ top: 8, bottom: 8 })

          // App info
          Text($r('app.string.settings_app_info'))
            .fontSize(13)
            .fontColor(tc('color_text_tertiary'))
            .textAlign(TextAlign.Center)
            .width('100%')

          Text($r('app.string.settings_platform'))
            .fontSize(12)
            .fontColor(tc('color_text_placeholder'))
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 40 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(tc('color_background'))
  }

  @Builder
  buildLanguageOption(lang: string, label: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.selectedLanguage === lang ? tc('color_accent') : tc('color_text_primary'))
        .fontWeight(this.selectedLanguage === lang ? FontWeight.Bold : FontWeight.Normal)
      Blank()
      if (this.selectedLanguage === lang) {
        Text('✓')
          .fontSize(16)
          .fontColor(tc('color_accent'))
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(() => {
      this.applyLanguage(lang);
    })
  }

  private saveSettings(): void {
    if (this.viewModel) {
      this.viewModel.saveSettings(this.baseURL, this.apiKey, this.useMock, this.model);
      this.viewModel.saveSystemPrompt(this.systemPrompt);
    }
    this.saved = true;
    setTimeout(() => {
      this.saved = false;
    }, 2000);
  }

  @Builder
  buildTemplateButton(key: string, label: string) {
    Button(label)
      .fontSize(12)
      .height(32)
      .padding({ left: 12, right: 12 })
      .fontColor(this.selectedTemplate === key ? tc('color_text_on_accent') : tc('color_text_secondary'))
      .backgroundColor(this.selectedTemplate === key ? tc('color_accent') : tc('color_surface_alt'))
      .borderRadius(16)
      .onClick(() => {
        this.selectedTemplate = key;
        this.systemPrompt = PROMPT_TEMPLATES[key] || '';
      })
  }
}
