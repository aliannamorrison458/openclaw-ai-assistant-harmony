// EntryAbility.ets — 应用入口
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { ChatViewModel } from '../viewmodel/ChatViewModel';

const TAG = 'EntryAbility';
const PREF_NAME = 'ai_assistant_prefs';
const ONBOARDING_DONE_KEY = 'onboarding_done';

export default class EntryAbility extends UIAbility {
  private viewModel: ChatViewModel | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'onCreate');
    this.viewModel = new ChatViewModel();
    // Share viewModel globally for settings page access
    (globalThis as any).chatViewModel = this.viewModel;
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, TAG, 'onWindowStageCreate');

    // Check if onboarding has been completed
    this.checkOnboardingStatus(windowStage);
  }

  private async checkOnboardingStatus(windowStage: window.WindowStage): Promise<void> {
    try {
      const prefStore = await preferences.getPreferences(this.context, PREF_NAME);
      const onboardingDone = await prefStore.get(ONBOARDING_DONE_KEY, 'false') as string;

      if (onboardingDone === 'true') {
        // Already seen onboarding, go to main page
        windowStage.loadContent('pages/Index', (err) => {
          if (err.code) {
            hilog.error(0x0000, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(0x0000, TAG, 'loadContent Index succeeded');
        });
      } else {
        // First launch, show onboarding
        windowStage.loadContent('pages/OnboardingPage', (err) => {
          if (err.code) {
            hilog.error(0x0000, TAG, 'loadContent OnboardingPage failed: %{public}s', JSON.stringify(err));
            return;
          }
          hilog.info(0x0000, TAG, 'loadContent OnboardingPage succeeded');
        });
      }
    } catch (e) {
      hilog.error(0x0000, TAG, 'checkOnboardingStatus error: %{public}s', JSON.stringify(e));
      // Fallback to onboarding on error
      windowStage.loadContent('pages/OnboardingPage', (err) => {
        if (err.code) {
          hilog.error(0x0000, TAG, 'loadContent fallback failed: %{public}s', JSON.stringify(err));
        }
      });
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, TAG, 'onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, TAG, 'onBackground');
  }
}
