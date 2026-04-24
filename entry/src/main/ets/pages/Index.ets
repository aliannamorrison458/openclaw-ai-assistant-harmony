// Index Page - Main chat interface
@Entry
@Component
struct Index {
  @State message: string = 'Hello OpenClaw';

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .margin({ top: 20 })

      Button('Send')
        .margin({ top: 20 })
        .onClick(() => {
          this.message = 'Response from AI';
        })
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
