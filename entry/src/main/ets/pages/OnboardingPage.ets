// OnboardingPage.ets — 首次启动引导页（深色主题）
import { tc } from '../common/DarkModeManager';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'OnboardingPage';
const PREF_NAME = 'ai_assistant_prefs';
const ONBOARDING_DONE_KEY = 'onboarding_done';

interface OnboardingSlide {
  emoji: string;
  title: string;
  description: string;
}

const SLIDES: OnboardingSlide[] = [
  {
    emoji: '💬',
    title: '智能聊天',
    description: '与 AI 助手自由对话，支持 Markdown 渲染、代码高亮、引用回复等丰富功能。'
  },
  {
    emoji: '🎤',
    title: '语音交互',
    description: '支持语音输入和语音播报，解放双手，让交流更自然便捷。'
  },
  {
    emoji: '🌐',
    title: '多语言支持',
    description: '内置中文、英文、日文等多种语言，跟随系统或手动切换。'
  },
  {
    emoji: '🌙',
    title: '深色模式',
    description: '支持亮色、深色及跟随系统主题，呵护你的眼睛。'
  }
];

@Entry
@Component
struct OnboardingPage {
  @State currentIndex: number = 0;
  private swiperController: SwiperController = new SwiperController();

  build() {
    Column() {
      // Skip button
      Row() {
        Blank()
        Text('跳过')
          .fontSize(14)
          .fontColor(tc('color_text_tertiary'))
          .padding({ top: 12, bottom: 12, left: 16, right: 16 })
          .onClick(() => this.finishOnboarding())
      }
      .width('100%')

      // Swiper for slides
      Swiper(this.swiperController) {
        ForEach(SLIDES, (slide: OnboardingSlide, index: number) => {
          Column() {
            Blank()

            // Emoji icon
            Text(slide.emoji)
              .fontSize(72)
              .textAlign(TextAlign.Center)
              .width('100%')

            // Title
            Text(slide.title)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(tc('color_text_primary'))
              .textAlign(TextAlign.Center)
              .width('100%')
              .margin({ top: 24 })

            // Description
            Text(slide.description)
              .fontSize(16)
              .fontColor(tc('color_text_secondary'))
              .textAlign(TextAlign.Center)
              .width('80%')
              .margin({ top: 16 })
              .lineHeight(24)

            Blank()
          }
          .width('100%')
          .height('100%')
        }, (slide: OnboardingSlide) => slide.title)
      }
      .index(this.currentIndex)
      .autoPlay(false)
      .loop(false)
      .indicator(false)
      .duration(300)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .layoutWeight(1)

      // Bottom section: indicator dots + button
      Column() {
        // Dot indicators
        Row({ space: 8 }) {
          ForEach(SLIDES, (slide: OnboardingSlide, index: number) => {
            Circle()
              .width(this.currentIndex === index ? 24 : 8)
              .height(8)
              .fill(this.currentIndex === index ? tc('color_accent') : tc('color_accent_dim'))
              .animation({ duration: 250, curve: Curve.EaseInOut })
          }, (slide: OnboardingSlide) => slide.title)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 32 })

        // Action button
        Button(this.currentIndex === SLIDES.length - 1 ? '开始使用' : '下一步')
          .width('80%')
          .height(48)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(tc('color_text_on_accent'))
          .backgroundColor(tc('color_accent'))
          .borderRadius(24)
          .onClick(() => {
            if (this.currentIndex === SLIDES.length - 1) {
              this.finishOnboarding();
            } else {
              this.currentIndex++;
              this.swiperController.changeIndex(this.currentIndex);
            }
          })
          .margin({ bottom: 48 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(tc('color_background'))
  }

  private async finishOnboarding(): Promise<void> {
    try {
      const prefStore = await preferences.getPreferences(globalThis.context, PREF_NAME);
      await prefStore.put(ONBOARDING_DONE_KEY, 'true');
      await prefStore.flush();
      hilog.info(0x0000, TAG, 'Onboarding marked as done');
    } catch (e) {
      hilog.error(0x0000, TAG, 'Failed to save onboarding flag: %{public}s', JSON.stringify(e));
    }
    router.replaceUrl({ url: 'pages/Index' });
  }
}
