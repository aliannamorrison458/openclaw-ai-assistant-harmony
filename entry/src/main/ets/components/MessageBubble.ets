// MessageBubble.ets — 消息气泡组件（集成语音播报按钮）
import { ChatMessage, SendStatus } from '../common/ChatTypes';

@Component
export struct MessageBubble {
  message: ChatMessage = {} as ChatMessage;
  onRetry: () => void = () => {};
  onLongPress: (msg: ChatMessage) => void = () => {};
  onSpeak: (text: string) => void = () => {};

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
            .color('#4A90D9')
          Text(this.message.quotedText)
            .fontSize(12)
            .fontColor('#888888')
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
            Text(this.message.isUser ? '回复助手' : '回复你')
              .fontSize(11)
              .fontColor('#4A90D9')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 2 })
          }

          Text(this.message.text)
            .fontSize(15)
            .fontColor(this.message.isUser ? '#FFFFFF' : '#1A1A1A')
            .padding({ top: 8, bottom: 8, left: 12, right: 12 })

          // Timestamp + status + voice button
          Row() {
            Text(this.formatTime(this.message.createdAt))
              .fontSize(11)
              .fontColor(this.message.isUser ? 'rgba(255,255,255,0.7)' : '#999999')

            if (this.message.sendStatus !== SendStatus.NONE) {
              Text(this.getStatusIcon())
                .fontSize(11)
                .margin({ left: 4 })

              // Retry button for failed messages
              if (this.message.sendStatus === SendStatus.FAILED) {
                Text('重试')
                  .fontSize(11)
                  .fontColor('#FF4444')
                  .margin({ left: 8 })
                  .onClick(() => this.onRetry())
              }
            }

            if (this.message.isDegraded) {
              Text('离线')
                .fontSize(10)
                .fontColor('#FF9800')
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
        .backgroundColor(this.message.isUser ? '#4A90D9' : '#F0F0F0')
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
          .fontColor('#FF9800')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 4, bottom: 4 })
      }
    }
    .width('100%')
    .margin({ bottom: 4 })
  }
}
