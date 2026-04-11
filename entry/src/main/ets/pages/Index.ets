// Index.ets — 聊天主页面（集成语音输入和播报功能 + 深色模式）
import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { MessageBubble } from '../components/MessageBubble';
import { ChatMessage, SendStatus } from '../common/ChatTypes';
import { VoiceState } from '../service/VoiceServiceManager';
import { DarkModeSetting, tc } from '../common/DarkModeManager';

@Entry
@Component
struct Index {
  @State viewModel: ChatViewModel = new ChatViewModel();
  @State inputText: string = '';
  @State showOfflineBanner: boolean = false;
  @State quotingMessage: ChatMessage | null = null;
  @State showContextMenu: boolean = false;
  @State contextMenuMessage: ChatMessage | null = null;
  @StorageProp('darkModeSetting') darkMode: DarkModeSetting = 'system';

  aboutToAppear() {
    this.viewModel.onUpdate(() => {
      // Trigger re-render by updating state
      this.showOfflineBanner = this.viewModel.isOffline;
      this.inputText = this.viewModel.inputText;
    });
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text($r('app.string.nav_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(tc('color_text_primary'))

        Blank()

        // Network status indicator
        if (this.showOfflineBanner) {
          Text($r('app.string.offline_badge'))
            .fontSize(12)
            .fontColor(tc('color_text_on_accent'))
            .backgroundColor(tc('color_warning'))
            .padding({ top: 2, bottom: 2, left: 8, right: 8 })
            .borderRadius(10)
        } else if (this.viewModel.isWeakNetwork) {
          Text($r('app.string.weak_network_badge'))
            .fontSize(12)
            .fontColor(tc('color_text_on_accent'))
            .backgroundColor('#FFC107')
            .padding({ top: 2, bottom: 2, left: 8, right: 8 })
            .borderRadius(10)
        }

        // Settings button
        Text('⚙️')
          .fontSize(22)
          .margin({ left: 12 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsPage' });
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(tc('color_surface'))
      .shadow({ radius: 2, color: tc('color_shadow'), offsetY: 1 })

      // Offline banner
      if (this.showOfflineBanner) {
        Row() {
          Text('📶')
            .fontSize(14)
          Text($r('app.string.offline_banner'))
            .fontSize(13)
            .fontColor(tc('color_text_on_accent'))
            .margin({ left: 6 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 6, bottom: 6 })
        .backgroundColor(tc('color_warning'))
        .animation({ duration: 250, curve: Curve.EaseInOut })
      }

      // Voice offline warning banner
      if (this.viewModel.voiceOfflineWarning) {
        Row() {
          Text(this.viewModel.voiceOfflineWarning)
            .fontSize(13)
            .fontColor(tc('color_text_on_accent'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 6, bottom: 6 })
        .backgroundColor(tc('color_error'))
        .animation({ duration: 250, curve: Curve.EaseInOut })
      }

      // Voice state indicator (recording / processing / playing)
      if (this.viewModel.voiceState !== VoiceState.IDLE) {
        Row() {
          // Animated indicator based on state
          if (this.viewModel.isRecording) {
            // Recording indicator: pulsing red dot
            Text('🔴')
              .fontSize(14)
              .animation({ duration: 500, iterations: -1, playMode: PlayMode.Alternate })
          } else if (this.viewModel.isVoiceProcessing) {
            // Processing indicator: spinner
            LoadingProgress()
              .width(16)
              .height(16)
              .color(tc('color_voice_indicator_text'))
          } else if (this.viewModel.isVoicePlaying) {
            // Playing indicator: speaker
            Text('🔊')
              .fontSize(14)
          }

          Text(this.getVoiceStateText())
            .fontSize(13)
            .fontColor(tc('color_voice_indicator_text'))
            .margin({ left: 8 })
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 6, bottom: 6 })
        .backgroundColor(tc('color_voice_indicator_bg'))
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
              },
              quoteAssistantLabel: $r('app.string.quote_assistant').toString(),
              quoteYouLabel: $r('app.string.quote_you').toString(),
              retryLabel: $r('app.string.btn_retry').toString(),
              offlineLabel: $r('app.string.msg_offline').toString()
            })
          }
        }, (msg: ChatMessage) => msg.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8 })
      .scrollBar(BarState.Off)
      .onScrollIndex((start: number, end: number) => {
        // Auto-scroll handled by List
      })

      // Quoting preview bar
      if (this.quotingMessage) {
        Row() {
          Rectangle()
            .width(3)
            .height('100%')
            .color(tc('color_quote_bar'))

          Column() {
            Text(this.quotingMessage.isUser ? $r('app.string.quote_self') : $r('app.string.quote_assistant'))
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(tc('color_accent'))
            Text(this.quotingMessage.text)
              .fontSize(12)
              .fontColor(tc('color_quote_text'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .margin({ left: 8 })

          Text('✕')
            .fontSize(16)
            .fontColor(tc('color_text_tertiary'))
            .onClick(() => this.quotingMessage = null)
        }
        .width('100%')
        .height(48)
        .padding({ left: 12, right: 12 })
        .backgroundColor(tc('color_quote_bg'))
      }

      // Input area
      Row() {
        // Voice button - changes state based on current activity
        this.buildVoiceButton()

        TextInput({ text: this.inputText, placeholder: $r('app.string.input_placeholder').toString() })
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(tc('color_text_primary'))
          .placeholderColor(tc('color_text_placeholder'))
          .padding({ left: 12, right: 12 })
          .backgroundColor(tc('color_surface_alt'))
          .borderRadius(20)
          .onChange((value: string) => {
            this.inputText = value;
            this.viewModel.inputText = value;
          })
          .onSubmit(() => this.sendMessage())
          .enabled(this.viewModel.voiceState === VoiceState.IDLE)

        Button($r('app.string.btn_send'))
          .width(60)
          .height(40)
          .fontSize(15)
          .fontColor(tc('color_text_on_accent'))
          .backgroundColor(this.viewModel.canSend && this.inputText.trim() ? tc('color_accent') : tc('color_accent_dim'))
          .borderRadius(20)
          .margin({ left: 8 })
          .enabled(this.viewModel.canSend && this.inputText.trim().length > 0 && this.viewModel.voiceState === VoiceState.IDLE)
          .onClick(() => this.sendMessage())
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(tc('color_surface'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(tc('color_background'))

    // Context menu overlay
    if (this.showContextMenu && this.contextMenuMessage) {
      this.buildContextMenu()
    }
  }

  private getVoiceStateText(): string {
    switch (this.viewModel.voiceState) {
      case VoiceState.RECORDING: return $r('app.string.voice_recording').toString();
      case VoiceState.PROCESSING: return $r('app.string.voice_processing').toString();
      case VoiceState.PLAYING: return $r('app.string.voice_playing').toString();
      default: return '';
    }
  }

  @Builder
  buildVoiceButton() {
    // Voice button with 3 states
    if (this.viewModel.isRecording) {
      // Recording state: red stop button
      Button('⏹')
        .width(40)
        .height(40)
        .fontSize(18)
        .fontColor(tc('color_text_on_accent'))
        .backgroundColor(tc('color_error'))
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
      // Processing state: disabled button with spinner
      Button() {
        LoadingProgress()
          .width(20)
          .height(20)
          .color(tc('color_text_on_accent'))
      }
      .width(40)
      .height(40)
      .backgroundColor(tc('color_accent_dim'))
      .borderRadius(20)
      .margin({ right: 8 })
      .enabled(false)
    } else if (this.viewModel.isVoicePlaying) {
      // Playing state: stop button
      Button('🔊')
        .width(40)
        .height(40)
        .fontSize(18)
        .fontColor(tc('color_text_on_accent'))
        .backgroundColor(tc('color_warning'))
        .borderRadius(20)
        .margin({ right: 8 })
        .onClick(() => {
          this.viewModel.stopSpeaking();
        })
    } else {
      // Idle state: microphone button
      Button('🎤')
        .width(40)
        .height(40)
        .fontSize(18)
        .fontColor(tc('color_text_on_accent'))
        .backgroundColor(this.viewModel.canUseVoice ? tc('color_accent') : tc('color_accent_dim'))
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
      // Backdrop
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => this.showContextMenu = false)

      // Menu items
      Column() {
        if (this.contextMenuMessage?.isUser) {
          Text($r('app.string.btn_copy'))
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontColor(tc('color_text_primary'))
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.copyText(this.contextMenuMessage!.text);
              this.showContextMenu = false;
            })

          Divider()
            .color(tc('color_divider'))

          Text($r('app.string.btn_quote_reply'))
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontColor(tc('color_text_primary'))
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.quotingMessage = this.contextMenuMessage;
              this.showContextMenu = false;
            })

          Divider()
            .color(tc('color_divider'))

          // 语音播报选项
          Text($r('app.string.btn_voice_playback'))
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontColor(tc('color_text_primary'))
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.viewModel.speakText(this.contextMenuMessage!.text);
              this.showContextMenu = false;
            })

          Divider()
            .color(tc('color_divider'))

          if (this.contextMenuMessage?.sendStatus === SendStatus.FAILED) {
            Text($r('app.string.btn_resend'))
              .fontSize(16)
              .width('100%')
              .textAlign(TextAlign.Center)
              .fontColor(tc('color_accent'))
              .padding({ top: 14, bottom: 14 })
              .onClick(() => {
                this.viewModel.retry(this.contextMenuMessage!.id);
                this.showContextMenu = false;
              })
            Divider()
              .color(tc('color_divider'))
          }

          Text($r('app.string.btn_delete'))
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontColor(tc('color_error'))
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.viewModel.deleteMessage(this.contextMenuMessage!.id);
              this.showContextMenu = false;
            })
        } else {
          // Assistant message
          Text($r('app.string.btn_copy'))
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontColor(tc('color_text_primary'))
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.copyText(this.contextMenuMessage!.text);
              this.showContextMenu = false;
            })

          Divider()
            .color(tc('color_divider'))

          Text($r('app.string.btn_quote_reply'))
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontColor(tc('color_text_primary'))
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.quotingMessage = this.contextMenuMessage;
              this.showContextMenu = false;
            })

          Divider()
            .color(tc('color_divider'))

          // 语音播报选项
          Text($r('app.string.btn_voice_playback'))
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontColor(tc('color_text_primary'))
            .padding({ top: 14, bottom: 14 })
            .onClick(() => {
              this.viewModel.speakText(this.contextMenuMessage!.text);
              this.showContextMenu = false;
            })
        }
      }
      .width('70%')
      .backgroundColor(tc('color_menu_bg'))
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
    // ArkTS clipboard API
    import { systemPasteboard } from '@kit.BasicServicesKit';
    systemPasteboard.setData(systemPasteboard.MIMETYPE_TEXT_PLAINTEXT, text, (err) => {
      if (err) {
        console.error('Copy failed:', JSON.stringify(err));
      }
    });
  }
}
