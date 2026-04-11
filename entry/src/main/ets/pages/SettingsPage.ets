// SettingsPage.ets — 设置页面
import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { i18n } from '@kit.LocalizationKit';
import { preferences } from '@kit.ArkData';

const LANG_PREF_KEY = 'app_language';
const PREF_NAME = 'ai_assistant_prefs';

@Entry
@Component
struct SettingsPage {
  @State baseURL: string = 'https://api.openai.com/v1';
  @State apiKey: string = '';
  @State useMock: boolean = true;
  @State model: string = 'gpt-3.5-turbo';
  @State saved: boolean = false;
  @State selectedLanguage: string = 'follow_system';

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
          .fontColor('#4A90D9')
          .onClick(() => router.back())

        Blank()

        Text($r('app.string.settings_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 16 }) {
          // Language Section
          Text($r('app.string.settings_language'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 16 })

          // Language selector
          Column({ space: 8 }) {
            this.buildLanguageOption('follow_system', $r('app.string.settings_language_follow_system').toString())
            Divider()
            this.buildLanguageOption('zh_CN', $r('app.string.settings_language_zh_cn').toString())
            Divider()
            this.buildLanguageOption('en_US', $r('app.string.settings_language_en_us').toString())
            Divider()
            this.buildLanguageOption('ja_JP', $r('app.string.settings_language_ja_jp').toString())
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .backgroundColor('#FFFFFF')
          .borderRadius(8)

          Divider()
            .margin({ top: 8, bottom: 8 })

          // API Configuration Section
          Text($r('app.string.settings_api_config'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          // Base URL
          Column({ space: 4 }) {
            Text($r('app.string.settings_api_base_url'))
              .fontSize(13)
              .fontColor('#666666')
            TextInput({ text: this.baseURL, placeholder: 'https://api.openai.com/v1' })
              .width('100%')
              .height(40)
              .fontSize(14)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .onChange((v: string) => this.baseURL = v)
          }

          // API Key
          Column({ space: 4 }) {
            Text($r('app.string.settings_api_key'))
              .fontSize(13)
              .fontColor('#666666')
            TextInput({ text: this.apiKey, placeholder: 'sk-...' })
              .width('100%')
              .height(40)
              .fontSize(14)
              .type(InputType.Password)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .onChange((v: string) => this.apiKey = v)
          }

          // Model
          Column({ space: 4 }) {
            Text($r('app.string.settings_model'))
              .fontSize(13)
              .fontColor('#666666')
            TextInput({ text: this.model, placeholder: 'gpt-3.5-turbo' })
              .width('100%')
              .height(40)
              .fontSize(14)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .onChange((v: string) => this.model = v)
          }

          // Use Mock toggle
          Row() {
            Text($r('app.string.settings_mock_mode'))
              .fontSize(15)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.useMock })
              .onChange((isOn: boolean) => this.useMock = isOn)
          }
          .width('100%')

          Text($r('app.string.settings_mock_desc'))
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')

          Divider()
            .margin({ top: 8, bottom: 8 })

          // Save button
          Button($r('app.string.settings_save'))
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#4A90D9')
            .borderRadius(8)
            .onClick(() => this.saveSettings())

          if (this.saved) {
            Text($r('app.string.settings_saved'))
              .fontSize(14)
              .fontColor('#4CAF50')
              .textAlign(TextAlign.Center)
              .width('100%')
          }

          Divider()
            .margin({ top: 8, bottom: 8 })

          // App info
          Text($r('app.string.settings_app_info'))
            .fontSize(13)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .width('100%')

          Text($r('app.string.settings_platform'))
            .fontSize(12)
            .fontColor('#BBBBBB')
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
    .backgroundColor('#FAFAFA')
  }

  @Builder
  buildLanguageOption(lang: string, label: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.selectedLanguage === lang ? '#4A90D9' : '#1A1A1A')
        .fontWeight(this.selectedLanguage === lang ? FontWeight.Bold : FontWeight.Normal)
      Blank()
      if (this.selectedLanguage === lang) {
        Text('✓')
          .fontSize(16)
          .fontColor('#4A90D9')
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
    }
    this.saved = true;
    setTimeout(() => {
      this.saved = false;
    }, 2000);
  }
}
