// HarmonyOS Entry - Main ability
import ability Want from '@ohos.ability.want';

class EntryAbility {
  onCreate(want: Want): void {
    console.log('EntryAbility onCreate');
  }

  onDestroy(): void {
    console.log('EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage): void {
    console.log('EntryAbility onWindowStageCreate');
    windowStage.setMainPage('pages/Index');
  }

  onWindowStageDestroy(): void {
    console.log('EntryAbility onWindowStageDestroy');
  }
}

export default new EntryAbility();
