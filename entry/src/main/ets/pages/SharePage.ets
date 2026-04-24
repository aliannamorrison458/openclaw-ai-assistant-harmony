// SharePage - Share/Export conversation
@Entry
@Component
struct SharePage {
  @State format: string = 'markdown';

  build() {
    Column() {
      Text('Share Conversation')
        .fontSize(20)

      Button('Copy as Markdown')
        .onClick(() => {
          this.copyAsMarkdown();
        })

      Button('Copy as Text')
        .onClick(() => {
          this.copyAsText();
        })
    }
  }

  private copyAsMarkdown() {
    // Generate markdown format
  }

  private copyAsText() {
    // Generate plain text
  }
}

export default SharePage;
