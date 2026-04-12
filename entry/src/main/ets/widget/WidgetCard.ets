/*
 * WidgetCard.ets - AI 助手桌面卡片 (Service Widget)
 *
 * HarmonyOS NEXT FormKit 卡片组件
 * 尺寸: 2*4 (4x2 格子)
 * 功能: 显示 App 名称、快捷输入框、发送按钮
 * 点击打开 App 主界面
 */

// TODO: HarmonyOS NEXT FormKit 的确切导入路径可能需要根据 SDK 版本调整
// 参考文档: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/service-widget-overview
import { formBindingData } from '@kit.FormKit';

@Entry
@Component
struct WidgetCard {
  @State message: string = '';

  build() {
    Column() {
      // App 名称标题栏
      Row() {
        Text('AI 助手')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ left: 12 })

        Blank()

        // 打开应用按钮
        Image($r('app.media.app_icon'))
          .width(24)
          .height(24)
          .borderRadius(6)
          .margin({ right: 12 })
          .onClick(() => {
            // TODO: 使用 FormKit router 跳转到主界面
            // postCardAction 会将卡片所在的卡片方打开为 Ability
            postCardAction(this, {
              'action': 'router',
              'abilityName': 'EntryAbility',
              'params': {
                'targetPage': 'main'
              }
            })
          })
      }
      .width('100%')
      .height(40)
      .backgroundColor('#1a73e8')
      .borderRadius({ topLeft: 16, topRight: 16 })

      // 快捷输入区域
      Row() {
        TextInput({ placeholder: '输入消息...', text: this.message })
          .layoutWeight(1)
          .height(36)
          .backgroundColor('#F5F5F5')
          .borderRadius(18)
          .padding({ left: 16, right: 16 })
          .fontSize(14)
          .fontColor('#333333')
          .placeholderColor('#999999')
          .onChange((value: string) => {
            this.message = value;
          })

        // 发送按钮
        Button('发送')
          .height(36)
          .margin({ left: 8 })
          .backgroundColor('#1a73e8')
          .borderRadius(18)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .onClick(() => {
            if (this.message.trim().length > 0) {
              // TODO: 通过 FormKit 将消息传递给主应用
              postCardAction(this, {
                'action': 'call',
                'abilityName': 'EntryAbility',
                'params': {
                  'method': 'sendMessage',
                  'message': this.message
                }
              });
              this.message = '';
            }
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')

      // 底部提示
      Text('点击发送或图标打开完整对话')
        .fontSize(11)
        .fontColor('#999999')
        .margin({ bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
