// LLMClient.ets — LLM API 客户端（对齐 iOS OpenAIClient + Android OpenAIClient）
import { http } from '@kit.NetworkKit';

export interface LLMConfig {
  baseURL: string;
  apiKey: string;
  model: string;
}

export interface LLMResponse {
  success: boolean;
  content: string;
  error?: string;
}

const DEFAULT_CONFIG: LLMConfig = {
  baseURL: 'https://api.openai.com/v1',
  apiKey: '',
  model: 'gpt-3.5-turbo'
};

export class LLMClient {
  private config: LLMConfig;

  constructor(config?: Partial<LLMConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  updateConfig(config: Partial<LLMConfig>): void {
    this.config = { ...this.config, ...config };
  }

  sendMessage(prompt: string, callback: (response: LLMResponse) => void): void {
    if (!this.config.apiKey) {
      callback({ success: false, content: '', error: 'API Key 未配置，请在设置中填写' });
      return;
    }

    const httpRequest = http.createHttp();
    const url = `${this.config.baseURL}/chat/completions`;

    const body = JSON.stringify({
      model: this.config.model,
      messages: [
        { role: 'user', content: prompt }
      ],
      stream: false
    });

    httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.config.apiKey}`
      },
      extraData: body,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 10000,
      readTimeout: 30000
    }, (err, data) => {
      if (err) {
        console.error('[LLMClient] request error:', JSON.stringify(err));
        callback({ success: false, content: '', error: `网络请求失败: ${err.code}` });
        return;
      }

      try {
        const result = JSON.parse(data.result as string);
        if (result.choices && result.choices.length > 0) {
          callback({
            success: true,
            content: result.choices[0].message.content
          });
        } else if (result.error) {
          callback({ success: false, content: '', error: result.error.message });
        } else {
          callback({ success: false, content: '', error: '未知响应格式' });
        }
      } catch (e) {
        callback({ success: false, content: '', error: '解析响应失败' });
      }

      httpRequest.destroy();
    });
  }
}

// Mock 客户端（本地测试用）
export class MockLLMClient {
  sendMessage(prompt: string, callback: (response: LLMResponse) => void): void {
    setTimeout(() => {
      callback({
        success: true,
        content: `这是模拟回复。你发送了：「${prompt}」\n\nAI 助手正在处理你的请求。当前为离线模拟模式。`
      });
    }, 800 + Math.random() * 500);
  }
}
