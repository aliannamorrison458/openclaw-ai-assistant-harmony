// SessionListPage.ets — 会话列表页面（新建/切换/删除/搜索/重命名）
import { SessionManager } from '../service/SessionManager';
import { ChatSession } from '../common/ChatTypes';

@Entry
@Component
struct SessionListPage {
  @State sessions: ChatSession[] = [];
  @State searchKeyword: string = '';
  @State showRenameDialog: boolean = false;
  @State renameTargetId: string = '';
  @State renameInput: string = '';

  private sessionManager: SessionManager = SessionManager.getInstance();

  aboutToAppear() {
    this.sessionManager.onUpdate(() => {
      this.refreshList();
    });
    this.refreshList();
  }

  private refreshList(): void {
    if (this.searchKeyword.trim()) {
      this.sessions = this.sessionManager.searchSessions(this.searchKeyword);
    } else {
      this.sessions = this.sessionManager.getSessions();
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('返回')
          .fontSize(16)
          .fontColor('#4A90D9')
          .onClick(() => router.back())

        Blank()

        Text('会话列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Blank()

        // 新建按钮
        Text('＋')
          .fontSize(24)
          .fontColor('#4A90D9')
          .fontWeight(FontWeight.Bold)
          .onClick(() => this.onCreateSession())
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.08)', offsetY: 1 })

      // 搜索栏
      Row() {
        TextInput({ placeholder: '搜索会话...' })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#F0F0F0')
          .borderRadius(18)
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.refreshList();
          })

        if (this.searchKeyword) {
          Text('取消')
            .fontSize(14)
            .fontColor('#4A90D9')
            .margin({ left: 8 })
            .onClick(() => {
              this.searchKeyword = '';
              this.refreshList();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // 会话列表
      List({ space: 0 }) {
        ForEach(this.sessions, (session: ChatSession) => {
          ListItem() {
            this.buildSessionItem(session)
          }
          .swipeAction({ end: this.buildDeleteButton(session) })
        }, (session: ChatSession) => session.id)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({
        strokeWidth: 0.5,
        color: '#F0F0F0',
        startMargin: 72,
        endMargin: 0
      })

      // 空状态
      if (this.sessions.length === 0) {
        Column() {
          Text(this.searchKeyword ? '未找到匹配的会话' : '暂无会话')
            .fontSize(15)
            .fontColor('#999999')
            .margin({ top: 40 })
          if (!this.searchKeyword) {
            Text('点击上方 ＋ 创建新对话')
              .fontSize(13)
              .fontColor('#BBBBBB')
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')

    // 重命名弹窗
    if (this.showRenameDialog) {
      this.buildRenameDialog()
    }
  }

  @Builder
  buildSessionItem(session: ChatSession) {
    Row() {
      // 头像占位
      Circle({ width: 40, height: 40 })
        .fill(session.id === this.sessionManager.getCurrentSessionId() ? '#4A90D9' : '#E0E0E0')
        .margin({ right: 12 })

      Column() {
        Text(session.title)
          .fontSize(16)
          .fontWeight(session.id === this.sessionManager.getCurrentSessionId() ? FontWeight.Medium : FontWeight.Normal)
          .fontColor('#1A1A1A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          if (session.lastMessagePreview) {
            Text(session.lastMessagePreview)
              .fontSize(13)
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          } else {
            Text('暂无消息')
              .fontSize(13)
              .fontColor('#CCCCCC')
              .layoutWeight(1)
          }

          Text(this.formatTime(session.updatedAt))
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 当前会话标记
      if (session.id === this.sessionManager.getCurrentSessionId()) {
        Text('●')
          .fontSize(10)
          .fontColor('#4A90D9')
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .onClick(() => this.onSelectSession(session.id))
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          this.renameTargetId = session.id;
          this.renameInput = session.title;
          this.showRenameDialog = true;
        })
    )
  }

  @Builder
  buildDeleteButton(session: ChatSession) {
    Button('删除')
      .width(72)
      .height('100%')
      .fontSize(15)
      .fontColor('#FFFFFF')
      .backgroundColor('#FF4444')
      .borderRadius(0)
      .onClick(() => this.onDeleteSession(session.id))
  }

  @Builder
  buildRenameDialog() {
    Column() {
      // 半透明背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => this.showRenameDialog = false)

      // 对话框
      Column({ space: 16 }) {
        Text('重命名会话')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        TextInput({ text: this.renameInput, placeholder: '输入新名称' })
          .width('100%')
          .height(40)
          .fontSize(15)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onChange((v: string) => this.renameInput = v)

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .fontColor('#666666')
            .backgroundColor('#F0F0F0')
            .borderRadius(8)
            .onClick(() => this.showRenameDialog = false)

          Button('确定')
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor('#4A90D9')
            .borderRadius(8)
            .onClick(() => this.onConfirmRename())
        }
        .width('100%')
      }
      .width('80%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private async onCreateSession(): Promise<void> {
    await this.sessionManager.createSession();
    router.back();
  }

  private async onSelectSession(sessionId: string): Promise<void> {
    if (sessionId === this.sessionManager.getCurrentSessionId()) {
      router.back();
      return;
    }
    await this.sessionManager.switchSession(sessionId);
    router.back();
  }

  private async onDeleteSession(sessionId: string): Promise<void> {
    await this.sessionManager.deleteSession(sessionId);
  }

  private async onConfirmRename(): Promise<void> {
    if (this.renameInput.trim()) {
      await this.sessionManager.renameSession(this.renameTargetId, this.renameInput.trim());
    }
    this.showRenameDialog = false;
  }

  private formatTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp;
    const date = new Date(timestamp);

    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`;

    const today = new Date();
    if (date.toDateString() === today.toDateString()) {
      return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
    }

    return `${date.getMonth() + 1}/${date.getDate()}`;
  }
}
