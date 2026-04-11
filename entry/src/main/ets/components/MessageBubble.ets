// MessageBubble.ets — 消息气泡组件（集成语音播报按钮 + 深色模式）
import { ChatMessage, SendStatus } from '../common/ChatTypes';
import { tc } from '../common/DarkModeManager';

@Component
export struct MessageBubble {
  message: ChatMessage = {} as ChatMessage;
  onRetry: () => void = () => {};
  onLongPress: (msg: ChatMessage) => void = () => {};
  onSpeak: (text: string) => void = () => {};
  quoteAssistantLabel: string = '回复助手';
  quoteYouLabel: string = '回复你';
  retryLabel: string = '重试';
  offlineLabel: string = '离线';

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  private getStatusIcon(): string {
    if (!this.message.isUser) return '';
    switch (this.message.sendStatus) {
      case SendStatus.SENDING: return '⏳';
      case SendStatus.SENT: return '✓';
      case SendStatus.FAILED: return '❌';
      default: return '';
    }
  }

  build() {
    Column() {
      // Quoted message preview
      if (this.message.quotedText) {
        Row() {
          Rectangle()
            .width(3)
            .height('100%')
            .color(tc('color_quote_bar'))
          Text(this.message.quotedText)
            .fontSize(12)
            .fontColor(tc('color_quote_text'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ left: 8 })
        }
        .width('80%')
        .height(36)
        .margin({ bottom: 4 })
        .padding({ left: 4 })
      }

      Row() {
        if (this.message.isUser) {
          Blank()
        }

        Column() {
          // Quoted label
          if (this.message.quotedText) {
            Text(this.message.isUser ? this.quoteAssistantLabel : this.quoteYouLabel)
              .fontSize(11)
              .fontColor(tc('color_accent'))
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 2 })
          }

          Text(this.message.text)
            .fontSize(15)
            .fontColor(this.message.isUser ? tc('color_bubble_user_text') : tc('color_bubble_assistant_text'))
            .padding({ top: 8, bottom: 8, left: 12, right: 12 })

          // Timestamp + status + voice button
          Row() {
            Text(this.formatTime(this.message.createdAt))
              .fontSize(11)
              .fontColor(this.message.isUser ? tc('color_bubble_user_time') : tc('color_bubble_assistant_time'))

            if (this.message.sendStatus !== SendStatus.NONE) {
              Text(this.getStatusIcon())
                .fontSize(11)
                .margin({ left: 4 })

              // Retry button for failed messages
              if (this.message.sendStatus === SendStatus.FAILED) {
                Text(this.retryLabel)
                  .fontSize(11)
                  .fontColor(tc('color_error'))
                  .margin({ left: 8 })
                  .onClick(() => this.onRetry())
              }
            }

            if (this.message.isDegraded) {
              Text(this.offlineLabel)
                .fontSize(10)
                .fontColor(tc('color_warning'))
                .margin({ left: 4 })
            }

            Blank()

            // Voice playback button for assistant messages
            if (!this.message.isUser && this.message.sendStatus === SendStatus.NONE) {
              Text('🔊')
                .fontSize(14)
                .margin({ right: 4 })
                .onClick(() => this.onSpeak(this.message.text))
            }
          }
          .margin({ top: 4 })
          .width('100%')
        }
        .width('70%')
        .backgroundColor(this.message.isUser ? tc('color_bubble_user') : tc('color_bubble_assistant'))
        .borderRadius(16)
        .margin({
          left: this.message.isUser ? 40 : 0,
          right: this.message.isUser ? 0 : 40
        })
        .gesture(
          LongPressGesture({ repeat: false })
            .onAction(() => this.onLongPress(this.message))
        )

        if (!this.message.isUser) {
          Blank()
        }
      }
      .width('100%')

      // System message styling override
      if (!this.message.isUser && this.message.sendStatus === SendStatus.NONE && this.message.text.startsWith('⚠️') || this.message.text.startsWith('错误')) {
        Text(this.message.text)
          .fontSize(13)
          .fontColor(tc('color_warning'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 4, bottom: 4 })
      }
    }
    .width('100%')
    .margin({ bottom: 4 })
  }
}
