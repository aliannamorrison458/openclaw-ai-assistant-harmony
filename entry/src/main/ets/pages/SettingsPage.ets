// SettingsPage.ets — 设置页面
import { ChatViewModel } from '../viewmodel/ChatViewModel';

@Entry
@Component
struct SettingsPage {
  @State baseURL: string = 'https://api.openai.com/v1';
  @State apiKey: string = '';
  @State useMock: boolean = true;
  @State model: string = 'gpt-3.5-turbo';
  @State saved: boolean = false;

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
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('← 返回')
          .fontSize(16)
          .fontColor('#4A90D9')
          .onClick(() => router.back())

        Blank()

        Text('设置')
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
          // API Configuration Section
          Text('API 配置')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 16 })

          // Base URL
          Column({ space: 4 }) {
            Text('API Base URL')
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
            Text('API Key')
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
            Text('模型')
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
            Text('离线模拟模式')
              .fontSize(15)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.useMock })
              .onChange((isOn: boolean) => this.useMock = isOn)
          }
          .width('100%')

          Text('开启后使用本地模拟回复，不调用远程 API')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')

          Divider()
            .margin({ top: 8, bottom: 8 })

          // Save button
          Button('保存设置')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#4A90D9')
            .borderRadius(8)
            .onClick(() => this.saveSettings())

          if (this.saved) {
            Text('✓ 已保存')
              .fontSize(14)
              .fontColor('#4CAF50')
              .textAlign(TextAlign.Center)
              .width('100%')
          }

          Divider()
            .margin({ top: 8, bottom: 8 })

          // App info
          Text('AI 助手 v1.0.0')
            .fontSize(13)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .width('100%')

          Text('HarmonyOS NEXT')
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
