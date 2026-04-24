// SearchPage - Session/Message search
@Entry
@Component
struct SearchPage {
  @State query: string = '';
  @State results: Array<{ sessionId: string; message: string; timestamp: number }> = [];

  build() {
    Column() {
      TextInput({ placeholder: 'Search...', text: this.query })
        .onChange((text) => {
          this.query = text;
          this.doSearch(text);
        })

      List() {
        ForEach(this.results, (result) => {
          ListItem() {
            Text(result.message)
              .margin(10)
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private doSearch(query: string) {
    // Search implementation
    this.results = [];
  }
}

export default SearchPage;
