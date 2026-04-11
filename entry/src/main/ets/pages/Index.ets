// Index.ets — 聊天主页面（集成语音输入 + 多会话管理）
import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { MessageBubble } from '../components/MessageBubble';
import { ChatMessage, SendStatus } from '../common/ChatTypes';
import { VoiceState } from '../service/VoiceServiceManager';

@Entry
@Component
struct Index {
  @State viewModel: ChatViewModel = new ChatViewModel();
  @State inputText: string = '';
  @State showOfflineBanner: boolean = false;
  @State quotingMessage: ChatMessage | null = null;
  @State showContextMenu: boolean = false;
  @State contextMenuMessage: ChatMessage | null = null;
  @State sessionTitle: string = '新对话';

  aboutToAppear() {
    this.viewModel.onUpdate(() => {
      this.showOfflineBanner = this.viewModel.isOffline;
      this.inputText = this.viewModel.inputText;
      this.sessionTitle = this.viewModel.currentSessionTitle;
    });
  }

  build() {
    Column() {
      // Navigation bar — 显示当前会话名称 + 左侧会话列表入口
      Row() {
        // 左侧按钮：打开会话列表
        Text('☰')
          .fontSize(22)
          .fontColor('#4A90D9')
          .margin({ right: 12 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SessionListPage' });
          })

        // 会话标题
        Text(this.sessionTitle)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        // Network status indicator
        if (this.showOfflineBanner) {
          Text('离线')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF9800')
            .padding({ top: 2, bottom: 2, left: 8, right: 8 })
            .borderRadius(10)
            .margin({ right: 8 })
        } else if (this.viewModel.isWeakNetwork) {
          Text('弱网')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#FFC107')
            .padding({ top: 2, bottom: 2, left: 8, right: 8 })
            .borderRadius(10)
            .margin({ right: 8 })
        }

        // Settings button
        Text('⚙️')
          .fontSize(22)
          .margin({ left: 4 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsPage' });
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.08)', offsetY: 1 })

      // Offline banner
      if (this.showOfflineBanner) {
        Row() {
          Text('📶')
            .fontSize(14)
          Text('网络已断开，消息将暂停发送')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .margin({ left: 6 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 6, bottom: 6 })
        .backgroundColor('#FF9800')
        .animation({ duration: 250, curve: Curve.EaseInOut })
      }

      // Voice offline warning banner
      if (this.viewModel.voiceOfflineWarning) {
        Row() {
          Text(this.viewModel.voiceOfflineWarning)
            .fontSize(13)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 6, bottom: 6 })
        .backgroundColor('#F44336')
        .animation({ duration: 250, curve: Curve.EaseInOut })
      }

      // Voice state indicator (recording / processing / playing)
      if (this.viewModel.voiceState !== VoiceState.IDLE) {
        Row() {
          if (this.viewModel.isRecording) {
            Text('🔴')
              .fontSize(14)
              .animation({ duration: 500, iterations: -1, playMode: PlayMode.Alternate })
          } else if (this.viewModel.isVoiceProcessing) {
            LoadingProgress()
              .width(16)
              .height(16)
              .color('#4A90D9')
          } else if (this.viewModel.isVoicePlaying) {
            Text('🔊')
              .fontSize(14)
          }

          Text(this.viewModel.voiceStateText)
            .fontSize(13)
            .fontColor('#4A90D9')
            .margin({ left: 8 })
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 6, bottom: 6 })
        .backgroundColor('#E3F2FD')
        .animation({ duration: 250, curve: Curve.EaseInOut })
      }

      // Message list
      List({ space: 8 }) {
        ForEach(this.viewModel.messages, (msg: ChatMessage) => {
          ListItem() {
            MessageBubble({
              message: msg,
              onRetry: () => this.viewModel.retry(msg.id),
              onLongPress: (m: ChatMessage) => {
                this.contextMenuMessage = m;
                this.showContextMenu = true;
              }
            })
          }
        }, (msg: ChatMessage) => msg.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8 })
      .scrollBar(BarState.Off)

      // Quoting preview bar
      if (this.quotingMessage) {
        Row() {
          Rectangle()
            .width(3)
            .height('100%')
            .color('#4A90D9')

          Column() {
            Text(this.quotingMessage.isUser ? '回复自己' : '回复助手')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4A90D9')
            Text(this.quotingMessage.text)
              .fontSize(12)
              .fontColor('#888888')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .margin({ left: 8 })

          Text('✕')
            .fontSize(16)
            .fontColor('#999999')
            .onClick(() => this.quotingMessage = null)
        }
        .width('100%')
        .height(48)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#F5F5F5')
      }

      // Input area
      Row() {
        this.buildVoiceButton()

        TextInput({ text: this.inputText, placeholder: '输入消息...' })
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .onChange((value: string) => {
            this.inputText = value;
            this.viewModel.inputText = value;
          })
          .onSubmit(() => this.sendMessage())
          .enabled(this.viewModel.voiceState === VoiceState.IDLE)

        Button('发送')
          .width(60)
          .height(40)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(this.viewModel.canSend && this.inputText.trim() ? '#4A90D9' : '#CCCCCC')
          .borderRadius(20)
          .margin({ left: 8 })
          .enabled(this.viewModel.canSend && this.inputText.trim().length > 0 && this.viewModel.voiceState === VoiceState.IDLE)
          .onClick(() => this.sendMessage())
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')

    // Context menu overlay
    if (this.showContextMenu && this.contextMenuMessage) {
      this.buildContextMenu()
    }
  }

  @Builder
  buildVoiceButton() {
    if (this.viewModel.isRecording) {
      Button('⏹')
        .width(40)
        .height(40)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor('#F44336')
        .borderRadius(20)
        .margin({ right: 8 })
        .onClick(() => {
          this.viewModel.stopVoiceRecording();
        })
        .gesture(
          LongPressGesture({ repeat: false })
            .onAction(() => {
              this.viewModel.cancelVoiceRecording();
            })
        )
    } else if (this.viewModel.isVoiceProcessing) {
      Button() {
        LoadingProgress()
          .width(20)
          .height(20)
          .color('#FFFFFF')
      }
      .width(40)
      .height(40)
      .backgroundColor('#CCCCCC')
      .borderRadius(20)
      .margin({ right: 8 })
      .enabled(false)
    } else if (this.viewModel.isVoicePlaying) {
      Button('🔊')
        .width(40)
        .height(40)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF9800')
        .borderRadius(20)
        .margin({ right: 8 })
        .onClick(() => {
          this.viewModel.stopSpeaking();
        })
    } else {
      Button('🎤')
        .width(40)
        .height(40)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .backgroundColor(this.viewModel.canUseVoice ? '#4A90D9' : '#CCCCCC')
        .borderRadius(20)
        .margin({ right: 8 })
        .enabled(this.viewModel.canUseVoice)
        .onClick(() => {
          this.viewModel.startVoiceRecording();
        })
    }
  }

  @Builder
  buildContextMenu() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => this.showContextMenu = false)

      Column() {
        if (this.contextMenuMessage?.isUser) {
          Text('复制')
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.copyText(this.contextMenuMessage!.text);
              this.showContextMenu = false;
            })

          Divider()

          Text('引用回复')
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.quotingMessage = this.contextMenuMessage;
              this.showContextMenu = false;
            })

          Divider()

          Text('语音播报')
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.viewModel.speakText(this.contextMenuMessage!.text);
              this.showContextMenu = false;
            })

          Divider()

          if (this.contextMenuMessage?.sendStatus === SendStatus.FAILED) {
            Text('重新发送')
              .fontSize(16)
              .width('100%')
              .textAlign(TextAlign.Center)
              .fontColor('#4A90D9')
              .padding({ top: 14, bottom: 14 })
              .onClick(() => {
                this.viewModel.retry(this.contextMenuMessage!.id);
                this.showContextMenu = false;
              })
            Divider()
          }

          Text('删除')
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontColor('#FF4444')
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.viewModel.deleteMessage(this.contextMenuMessage!.id);
              this.showContextMenu = false;
            })
        } else {
          Text('复制')
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.copyText(this.contextMenuMessage!.text);
              this.showContextMenu = false;
            })

          Divider()

          Text('引用回复')
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.quotingMessage = this.contextMenuMessage;
              this.showContextMenu = false;
            })

          Divider()

          Text('语音播报')
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.viewModel.speakText(this.contextMenuMessage!.text);
              this.showContextMenu = false;
            })
        }
      }
      .width('70%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private sendMessage(): void {
    if (!this.inputText.trim()) return;

    const quotedId = this.quotingMessage?.id;
    const quotedText = this.quotingMessage?.text;
    this.viewModel.send(this.inputText, quotedId, quotedText);
    this.inputText = '';
    this.quotingMessage = null;
  }

  private copyText(text: string): void {
    import { systemPasteboard } from '@kit.BasicServicesKit';
    systemPasteboard.setData(systemPasteboard.MIMETYPE_TEXT_PLAINTEXT, text, (err) => {
      if (err) {
        console.error('Copy failed:', JSON.stringify(err));
      }
    });
  }
}
