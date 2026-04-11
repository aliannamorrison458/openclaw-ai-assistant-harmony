// ToolUseBubble.ets — 工具调用展示组件（可折叠/展开）
import { ToolUseData, MessageType } from '../common/ChatTypes';

@Component
export struct ToolUseBubble {
  toolData: ToolUseData = {} as ToolUseData;
  messageType: MessageType = MessageType.TOOL_USE;

  // i18n string props
  statusExecuting: string = '执行中...';
  statusCompleted: string = '已完成';
  statusError: string = '执行出错';
  paramsLabel: string = '📋 参数';
  resultLabel: string = '📝 执行结果';
  errorResultLabel: string = '❌ 错误结果';
  moreItemsSuffix: string = '个';

  @State expanded: boolean = false;

  // 格式化 JSON 参数（带缩进 + 截断）
  private formatParams(json: string): string {
    try {
      const obj = JSON.parse(json);
      const formatted = JSON.stringify(obj, null, 2);
      if (formatted.length > 300) {
        return formatted.substring(0, 300) + '\n...';
      }
      return formatted;
    } catch (e) {
      if (json.length > 300) {
        return json.substring(0, 300) + '...';
      }
      return json;
    }
  }

  // 截断摘要文本
  private truncateSummary(text: string | undefined, maxLen: number = 120): string {
    if (!text) return '';
    if (text.length <= maxLen) return text;
    return text.substring(0, maxLen) + '...';
  }

  // 状态图标
  private getStatusIcon(): string {
    switch (this.toolData.status) {
      case 'running': return '⏳';
      case 'completed': return '✅';
      case 'error': return '❌';
      default: return '🔧';
    }
  }

  // 状态文案
  private getStatusText(): string {
    switch (this.toolData.status) {
      case 'running': return this.statusExecuting;
      case 'completed': return this.statusCompleted;
      case 'error': return this.statusError;
      default: return '';
    }
  }

  // 状态颜色
  private getStatusColor(): string {
    switch (this.toolData.status) {
      case 'running': return '#FF9800';
      case 'completed': return '#4CAF50';
      case 'error': return '#F44336';
      default: return '#999999';
    }
  }

  // 耗时计算
  private getDuration(): string {
    if (!this.toolData.startTime || !this.toolData.endTime) return '';
    const ms = this.toolData.endTime - this.toolData.startTime;
    if (ms < 1000) return `${ms}ms`;
    return `${(ms / 1000).toFixed(1)}s`;
  }

  // 简洁参数摘要（一行）
  private getParamPreview(): string {
    try {
      const obj = JSON.parse(this.toolData.paramsJson);
      const keys = Object.keys(obj);
      if (keys.length === 0) return '{}';
      const previews: string[] = [];
      for (const key of keys.slice(0, 3)) {
        const val = typeof obj[key] === 'string'
          ? (obj[key] as string).substring(0, 30)
          : JSON.stringify(obj[key]);
        previews.push(`${key}: ${val}`);
      }
      if (keys.length > 3) previews.push(`...+${keys.length - 3}${this.moreItemsSuffix}`);
      return previews.join(', ');
    } catch (e) {
      if (this.toolData.paramsJson.length > 80) {
        return this.toolData.paramsJson.substring(0, 80) + '...';
      }
      return this.toolData.paramsJson;
    }
  }

  // 参数列表键值对
  private getParamEntries(): Array<{ key: string, value: string }> {
    try {
      const obj = JSON.parse(this.toolData.paramsJson);
      return Object.entries(obj).map(([k, v]) => ({
        key: k,
        value: typeof v === 'string' ? v : JSON.stringify(v)
      }));
    } catch (e) {
      return [{ key: 'raw', value: this.toolData.paramsJson }];
    }
  }

  build() {
    Column() {
      // ===== 折叠状态：紧凑摘要 =====
      Row() {
        // 工具图标 + 名称
        Text(this.getStatusIcon())
          .fontSize(16)
          .margin({ right: 6 })

        Column() {
          Row() {
            Text(this.toolData.toolName)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')

            // 状态标签
            Text(this.getStatusText())
              .fontSize(11)
              .fontColor(this.getStatusColor())
              .fontWeight(FontWeight.Medium)
              .margin({ left: 8 })
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.getStatusColor() + '18')
              .borderRadius(10)
          }

          if (!this.expanded) {
            // 参数预览
            Text(this.getParamPreview())
              .fontSize(12)
              .fontColor('#888888')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }

          // 结果预览（折叠时仅显示前几个字）
          if (!this.expanded && this.toolData.resultSummary) {
            Text(this.truncateSummary(this.toolData.resultSummary, 60))
              .fontSize(12)
              .fontColor('#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)

        // 展开/折叠箭头
        Text(this.expanded ? '▲' : '▼')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ top: 10, bottom: 10, left: 12, right: 12 })
      .onClick(() => {
        this.expanded = !this.expanded;
      })

      // ===== 展开状态：详细信息 =====
      if (this.expanded) {
        // 参数详情
        Column() {
          Text(this.paramsLabel)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#666666')
            .margin({ bottom: 6 })

          Column() {
            ForEach(this.getParamEntries(), (entry: { key: string, value: string }) => {
              Row() {
                Text(entry.key + ':')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#888888')
                  .margin({ right: 6 })
                Text(entry.value)
                  .fontSize(12)
                  .fontColor('#333333')
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ top: 2, bottom: 2 })
            }, (entry: { key: string, value: string }) => entry.key)
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .backgroundColor('#F8F9FA')
          .borderRadius(6)
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 8 })

        // 结果详情
        if (this.toolData.resultSummary) {
          Column() {
            Text(this.toolData.status === 'error' ? this.errorResultLabel : this.resultLabel)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.toolData.status === 'error' ? '#F44336' : '#666666')
              .margin({ bottom: 6 })

            Text(this.toolData.resultSummary)
              .fontSize(12)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 8, right: 8, top: 8, bottom: 8 })
              .backgroundColor(this.toolData.status === 'error' ? '#FFF5F5' : '#F8F9FA')
              .borderRadius(6)
              .border({
                width: 1,
                color: this.toolData.status === 'error' ? '#FFCDD2' : '#E8E8E8'
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 8 })
        }

        // 耗时
        if (this.getDuration()) {
          Row() {
            Text('⏱️ ' + this.getDuration())
              .fontSize(11)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 8 })
        }
      }
    }
    .width('80%')
    .backgroundColor(this.messageType === MessageType.TOOL_RESULT && this.toolData.status === 'error'
      ? '#FFF5F5' : '#F8F8F8')
    .borderRadius(12)
    .border({
      width: 1,
      color: this.messageType === MessageType.TOOL_RESULT && this.toolData.status === 'error'
        ? '#FFCDD2' : '#E8E8E8'
    })
    .margin({
      left: 0,
      right: 40
    })
  }
}
