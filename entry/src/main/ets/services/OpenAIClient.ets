// OpenAIClient - Network layer (H4)
// HarmonyOS ArkTS implementation
import http from '@ohos.net.http';

class OpenAIClient {
  private baseURL: string = 'http://192.168.8.104:18789';
  private apiKey: string = '';
  private model: string = 'openclclaw';

  constructor(config?: { baseURL?: string; apiKey?: string; model?: string }) {
    if (config) {
      this.baseURL = config.baseURL ?? this.baseURL;
      this.apiKey = config.apiKey ?? this.apiKey;
      this.model = config.model ?? this.model;
    }
  }

  async reply(messages: Array<{ role: string; content: string }>): Promise<string> {
    const httpRequest = http.createHttp();
    
    try {
      const response = await httpRequest.request(
        `${this.baseURL}/v1/chat/completions`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`,
          },
          extraData: {
            model: this.model,
            messages: messages,
            stream: false,
          },
        }
      );

      if (response.responseCode === 200) {
        const data = JSON.parse(response.result as string);
        return data.choices[0]?.message?.content ?? '';
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  async replyStream(
    messages: Array<{ role: string; content: string }>,
    onToken: (token: string) => void
  ): Promise<void> {
    const httpRequest = http.createHttp();
    
    try {
      const response = await httpRequest.request(
        `${this.baseURL}/v1/chat/completions`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`,
          },
          extraData: {
            model: this.model,
            messages: messages,
            stream: true,
          },
        }
      );

      if (response.responseCode === 200) {
        const lines = (response.result as string).split('\n');
        for (const line of lines) {
          if (line.startsWith('data: ') && !line.includes('[DONE]')) {
            try {
              const data = JSON.parse(line.substring(6));
              const content = data.choices[0]?.delta?.content;
              if (content) {
                onToken(content);
              }
            } catch (e) {
              // Skip malformed JSON
            }
          }
        }
      }
    } finally {
      httpRequest.destroy();
    }
  }
}

export default OpenAIClient;
