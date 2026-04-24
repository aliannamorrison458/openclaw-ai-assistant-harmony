// MarkdownRenderer - Message rendering (H6)
@Component
struct MarkdownRenderer {
  @Prop content: string = '';

  @Builder
  renderContent(text: string) {
    Column() {
      // Basic markdown: **bold**, *italic*, `code`, [link](url)
      ForEach(text.split('\n'), (line: string) => {
        Text(this.parseLine(line))
          .fontSize(16)
          .margin({ bottom: 4 })
      })
    }
  }

  private parseLine(text: string): string {
    // Simplified: just return the text
    // Full version would parse **bold** -> bold with weight
    return text;
  }

  build() {
    this.renderContent(this.content)
  }
}

export default MarkdownRenderer;
