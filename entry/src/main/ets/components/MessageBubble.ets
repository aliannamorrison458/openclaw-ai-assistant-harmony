// MessageBubble.ets — 消息气泡组件（Thinking 展示 + 语音播报 + 深色模式 + 无障碍）
import { ChatMessage, SendStatus } from '../common/ChatTypes';
import { tc } from '../common/DarkModeManager';

@Component
export struct MessageBubble {
  message: ChatMessage = {} as ChatMessage;
  onRetry: () => void = () => {};
  onLongPress: (msg: ChatMessage) => void = () => {};
  onSpeak: (text: string) => void = () => {};
  onRegenerate: () => void = () => {};
  quoteAssistantLabel: string = '回复助手';
  quoteYouLabel: string = '回复你';
  retryLabel: string = '重试';
  offlineLabel: string = '离线';
  isLastAssistant: boolean = false;

  @State thinkingExpanded: boolean = false;

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

  private getAccessibilityLabel(): string {
    const role = this.message.isUser ? '你发送的消息' : '助手的回复';
    const time = this.formatTime(this.message.createdAt);
    return `${role}，时间 ${time}，内容：${this.message.text}`;
  }

  build() {
    Column() {
      // Thinking 推理过程展示（仅 AI 消息且有 thinking 内容）
      if (!this.message.isUser && this.message.thinkingContent && this.message.thinkingContent.length > 0) {
        this.buildThinkingBlock()
      }

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

            // 重新生成按钮（仅最后一条 AI 回复）
            if (this.isLastAssistant && !this.message.isUser && this.message.sendStatus === SendStatus.NONE) {
              Text('🔄')
                .fontSize(14)
                .margin({ right: 8 })
                .accessibilityText('重新生成回复')
                .onClick(() => this.onRegenerate())
            }

            // Voice playback button for assistant messages
            if (!this.message.isUser && this.message.sendStatus === SendStatus.NONE) {
              Text('🔊')
                .fontSize(14)
                .margin({ right: 4 })
                .accessibilityText('语音播报')
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
        .accessibilityText(this.getAccessibilityLabel())
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

  @Builder
  buildThinkingBlock() {
    Column() {
      // 折叠/展开标题栏
      Row() {
        Text(this.thinkingExpanded ? '▼' : '▶')
          .fontSize(12)
          .fontColor(tc('color_text_tertiary'))
          .margin({ right: 6 })

        Text('Thinking')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(tc('color_text_tertiary'))

        Blank()

        if (!this.thinkingExpanded && this.message.thinkingContent) {
          Text(this.message.thinkingContent.length > 50
            ? this.message.thinkingContent.substring(0, 50) + '...'
            : this.message.thinkingContent)
            .fontSize(12)
            .fontColor(tc('color_text_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
      }
      .width('100%')
      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
      .onClick(() => {
        this.thinkingExpanded = !this.thinkingExpanded;
      })
      .accessibilityText(this.thinkingExpanded ? '收起思考过程' : '展开查看思考过程')

      // 展开后的 Thinking 内容
      if (this.thinkingExpanded && this.message.thinkingContent) {
        Text(this.message.thinkingContent)
          .fontSize(13)
          .fontColor(tc('color_text_secondary'))
          .padding({ top: 4, bottom: 8, left: 12, right: 12 })
          .width('100%')
      }
    }
    .width('80%')
    .backgroundColor(tc('color_thinking_bg'))
    .borderRadius(12)
    .margin({ bottom: 6 })
  }
}
