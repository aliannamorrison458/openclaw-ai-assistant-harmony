// LLMClient.ets — LLM API 客户端（SSE streaming + tool use + thinking）
// 对齐 iOS OpenAIClient + Android OpenAIClient
import { http } from '@kit.NetworkKit';
import { ConversationMessage, ToolCall } from '../common/ChatTypes';

// ─── Config ───────────────────────────────────────────────

export interface LLMConfig {
  baseURL: string;
  apiKey: string;
  model: string;
  maxTokens: number;
  temperature: number;
  tools?: ToolDefinition[];
}

export interface ToolDefinition {
  type: string;
  function: {
    name: string;
    description: string;
    parameters: Record<string, Object>;
  };
}

const DEFAULT_CONFIG: LLMConfig = {
  baseURL: 'https://api.openai.com/v1',
  apiKey: '',
  model: 'gpt-3.5-turbo',
  maxTokens: 4096,
  temperature: 0.7
};

// ─── Streaming event types ────────────────────────────────

export interface StreamToolCallDelta {
  index: number;
  id?: string;
  type?: string;
  function?: {
    name?: string;
    arguments?: string;
  };
}

export interface SSEStreamEvent {
  type: 'content' | 'tool_use' | 'thinking' | 'done' | 'error';
  content: string;
  toolCalls?: StreamToolCallDelta[];
  toolCallIndex?: number;
  finishReason?: string;
}

export interface LLMStreamCallbacks {
  onContent: (chunk: string) => void;
  onThinking: (chunk: string) => void;
  onToolCall: (toolCalls: ToolCall[]) => void;
  onComplete: (finishReason: string) => void;
  onError: (error: string) => void;
}

export interface LLMResponse {
  success: boolean;
  content: string;
  thinking?: string;
  toolCalls?: ToolCall[];
  error?: string;
}

// ─── SSE parser ───────────────────────────────────────────

class SSEParser {
  private buffer: string = '';

  addData(raw: string): SSEStreamEvent[] {
    this.buffer += raw;
    const events: SSEStreamEvent[] = [];
    const lines = this.buffer.split('\n');
    // Keep last potentially incomplete line
    this.buffer = lines.pop() || '';

    let currentEventType: string = '';
    let currentData: string = '';

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      if (line.startsWith('event:')) {
        currentEventType = line.substring(6).trim();
        continue;
      }

      if (line.startsWith('data:')) {
        currentData = line.substring(5).trim();
        continue;
      }

      // Empty line signals end of SSE event
      if (line.trim() === '') {
        if (currentData.length > 0) {
          const event = this.parseEventData(currentData, currentEventType);
          if (event) {
            events.push(event);
          }
        }
        currentEventType = '';
        currentData = '';
        continue;
      }
    }

    return events;
  }

  flush(): SSEStreamEvent[] {
    if (this.buffer.trim().length > 0) {
      const remaining = this.buffer;
      this.buffer = '';
      return this.addData(remaining + '\n\n');
    }
    return [];
  }

  reset(): void {
    this.buffer = '';
  }

  private parseEventData(data: string, eventType: string): SSEStreamEvent | null {
    if (data === '[DONE]') {
      return { type: 'done', content: '', finishReason: 'stop' };
    }

    try {
      const json = JSON.parse(data);

      // Handle error responses
      if (json.error) {
        return { type: 'error', content: json.error.message || 'Unknown error' };
      }

      const choices = json.choices;
      if (!choices || choices.length === 0) {
        return null;
      }

      const choice = choices[0];
      const delta = choice.delta;
      if (!delta) {
        return null;
      }

      // Thinking / reasoning content (Claude-style or extended models)
      if (delta.reasoning || delta.reasoning_content) {
        const thinkingText = (delta.reasoning || delta.reasoning_content) as string;
        return { type: 'thinking', content: thinkingText };
      }

      // Tool calls delta
      if (delta.tool_calls && delta.tool_calls.length > 0) {
        return {
          type: 'tool_use',
          content: '',
          toolCalls: delta.tool_calls as StreamToolCallDelta[]
        };
      }

      // Regular content
      if (delta.content) {
        return { type: 'content', content: delta.content as string };
      }

      // Finish reason
      if (choice.finish_reason) {
        return { type: 'done', content: '', finishReason: choice.finish_reason as string };
      }

      return null;
    } catch (e) {
      console.warn('[SSEParser] parse error:', data.substring(0, 100));
      return null;
    }
  }
}

// ─── Partial tool call accumulator ────────────────────────

interface PartialToolCall {
  id: string;
  name: string;
  arguments: string;
}

// ─── LLMClient ────────────────────────────────────────────

export class LLMClient {
  private config: LLMConfig;
  private abortController: (() => void) | null = null;

  constructor(config?: Partial<LLMConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  updateConfig(config: Partial<LLMConfig>): void {
    this.config = { ...this.config, ...config };
  }

  setTools(tools: ToolDefinition[]): void {
    this.config.tools = tools;
  }

  // Cancel active streaming request
  abort(): void {
    if (this.abortController) {
      this.abortController();
      this.abortController = null;
    }
  }

  // ─── Non-streaming send (backward compatible) ───────────

  sendMessage(prompt: string, callback: (response: LLMResponse) => void): void {
    if (!this.config.apiKey) {
      callback({ success: false, content: '', error: 'API Key 未配置，请在设置中填写' });
      return;
    }

    const httpRequest = http.createHttp();
    const url = `${this.config.baseURL}/chat/completions`;

    const messages: ConversationMessage[] = [
      { role: 'user', content: prompt }
    ];

    const bodyObj: Record<string, Object> = {
      model: this.config.model,
      messages: messages,
      stream: false,
      max_tokens: this.config.maxTokens,
      temperature: this.config.temperature
    };

    if (this.config.tools && this.config.tools.length > 0) {
      bodyObj['tools'] = this.config.tools;
    }

    const body = JSON.stringify(bodyObj);

    httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.config.apiKey}`
      },
      extraData: body,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 10000,
      readTimeout: 60000
    }, (err, data) => {
      if (err) {
        console.error('[LLMClient] request error:', JSON.stringify(err));
        callback({ success: false, content: '', error: `网络请求失败: ${err.code}` });
        return;
      }

      try {
        const result = JSON.parse(data.result as string);
        if (result.choices && result.choices.length > 0) {
          const choice = result.choices[0];
          const message = choice.message;

          let toolCalls: ToolCall[] | undefined;
          if (message.tool_calls && message.tool_calls.length > 0) {
            toolCalls = message.tool_calls.map((tc: any) => ({
              id: tc.id,
              name: tc.function.name,
              arguments: tc.function.arguments
            }));
          }

          callback({
            success: true,
            content: message.content || '',
            thinking: message.reasoning || message.reasoning_content,
            toolCalls: toolCalls
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

  // ─── Streaming send with SSE ────────────────────────────

  sendStreaming(
    messages: ConversationMessage[],
    callbacks: LLMStreamCallbacks
  ): void {
    if (!this.config.apiKey) {
      callbacks.onError('API Key 未配置，请在设置中填写');
      return;
    }

    const httpRequest = http.createHttp();
    const url = `${this.config.baseURL}/chat/completions`;

    const bodyObj: Record<string, Object> = {
      model: this.config.model,
      messages: messages,
      stream: true,
      max_tokens: this.config.maxTokens,
      temperature: this.config.temperature
    };

    if (this.config.tools && this.config.tools.length > 0) {
      bodyObj['tools'] = this.config.tools;
    }

    const body = JSON.stringify(bodyObj);
    const sseParser = new SSEParser();
    const partialToolCalls: Map<number, PartialToolCall> = new Map();
    let isAborted = false;

    // Register abort handler
    this.abortController = () => {
      isAborted = true;
      httpRequest.destroy();
    };

    httpRequest.requestInStream(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.config.apiKey}`,
        'Accept': 'text/event-stream'
      },
      extraData: body,
      connectTimeout: 10000,
      readTimeout: 120000
    }, (err, data) => {
      if (isAborted) return;

      if (err) {
        console.error('[LLMClient] stream error:', JSON.stringify(err));
        callbacks.onError(`网络请求失败: ${err.code}`);
        this.abortController = null;
        return;
      }

      // data is the HttpStreamResponse
      const streamResponse = data as HttpStreamResponse;

      // Data received handler
      streamResponse.onData((chunk: ArrayBuffer) => {
        if (isAborted) return;
        try {
          const raw = String.fromArrayBuffer(chunk);
          const events = sseParser.addData(raw);
          this.processEvents(events, partialToolCalls, callbacks);
        } catch (e) {
          console.error('[LLMClient] chunk decode error');
        }
      });

      // Stream complete handler
      streamResponse.onEnd(() => {
        if (isAborted) return;
        // Flush remaining buffer
        const remaining = sseParser.flush();
        this.processEvents(remaining, partialToolCalls, callbacks);

        // If tool calls were accumulated, send them
        if (partialToolCalls.size > 0) {
          const toolCalls: ToolCall[] = [];
          const sortedIndices = Array.from(partialToolCalls.keys()).sort((a, b) => a - b);
          for (const idx of sortedIndices) {
            const ptc = partialToolCalls.get(idx);
            if (ptc) {
              toolCalls.push({
                id: ptc.id,
                name: ptc.name,
                arguments: ptc.arguments
              });
            }
          }
          callbacks.onToolCall(toolCalls);
        }

        callbacks.onComplete('stop');
        this.abortController = null;
      });

      // Error handler
      streamResponse.onError((err: Object) => {
        if (isAborted) return;
        console.error('[LLMClient] stream data error:', JSON.stringify(err));
        callbacks.onError('流式传输中断');
        this.abortController = null;
      });
    });
  }

  // ─── Process parsed SSE events ──────────────────────────

  private processEvents(
    events: SSEStreamEvent[],
    partialToolCalls: Map<number, PartialToolCall>,
    callbacks: LLMStreamCallbacks
  ): void {
    for (let i = 0; i < events.length; i++) {
      const event = events[i];

      switch (event.type) {
        case 'content':
          callbacks.onContent(event.content);
          break;

        case 'thinking':
          callbacks.onThinking(event.content);
          break;

        case 'tool_use':
          this.accumulateToolCalls(event.toolCalls || [], partialToolCalls);
          break;

        case 'done':
          if (event.finishReason === 'tool_calls') {
            // Collect all accumulated tool calls
            const toolCalls: ToolCall[] = [];
            const sortedIndices = Array.from(partialToolCalls.keys()).sort((a, b) => a - b);
            for (const idx of sortedIndices) {
              const ptc = partialToolCalls.get(idx);
              if (ptc) {
                toolCalls.push({
                  id: ptc.id,
                  name: ptc.name,
                  arguments: ptc.arguments
                });
              }
            }
            partialToolCalls.clear();
            callbacks.onToolCall(toolCalls);
          }
          callbacks.onComplete(event.finishReason || 'stop');
          break;

        case 'error':
          callbacks.onError(event.content);
          break;
      }
    }
  }

  // ─── Accumulate streaming tool call deltas ──────────────

  private accumulateToolCalls(
    deltas: StreamToolCallDelta[],
    partialToolCalls: Map<number, PartialToolCall>
  ): void {
    for (let i = 0; i < deltas.length; i++) {
      const delta = deltas[i];
      const idx = delta.index;

      if (!partialToolCalls.has(idx)) {
        partialToolCalls.set(idx, {
          id: delta.id || '',
          name: delta.function?.name || '',
          arguments: ''
        });
      }

      const existing = partialToolCalls.get(idx);
      if (existing) {
        if (delta.id && delta.id.length > 0) {
          existing.id = delta.id;
        }
        if (delta.function?.name && delta.function.name.length > 0) {
          existing.name = delta.function.name;
        }
        if (delta.function?.arguments) {
          existing.arguments += delta.function.arguments;
        }
      }
    }
  }

  // ─── Build conversation messages from ChatMessage ───────

  static buildConversationHistory(
    messages: Array<{ role: string; content: string; toolCalls?: ToolCall[]; toolCallId?: string; name?: string }>
  ): ConversationMessage[] {
    const result: ConversationMessage[] = [];
    for (let i = 0; i < messages.length; i++) {
      const msg = messages[i];
      const conv: ConversationMessage = {
        role: msg.role,
        content: msg.content
      };
      if (msg.toolCalls && msg.toolCalls.length > 0) {
        conv.toolCalls = msg.toolCalls;
      }
      if (msg.toolCallId) {
        conv.toolCallId = msg.toolCallId;
      }
      if (msg.name) {
        conv.name = msg.name;
      }
      result.push(conv);
    }
    return result;
  }
}

// ─── Mock 客户端（本地测试用）────────────────────────────

export class MockLLMClient {
  private timerId: number = 0;

  abort(): void {
    if (this.timerId > 0) {
      clearTimeout(this.timerId);
      this.timerId = 0;
    }
  }

  sendMessage(prompt: string, callback: (response: LLMResponse) => void): void {
    this.timerId = setTimeout(() => {
      callback({
        success: true,
        content: `这是模拟回复。你发送了：「${prompt}」\n\nAI 助手正在处理你的请求。当前为离线模拟模式。`
      });
      this.timerId = 0;
    }, 800 + Math.random() * 500) as unknown as number;
  }

  // Mock streaming: simulates token-by-token output
  sendStreaming(
    prompt: string,
    callbacks: LLMStreamCallbacks
  ): void {
    const fullText = `这是模拟的流式回复。你发送了：「${prompt}」\n\nAI 助手正在逐字输出，模拟流式传输效果。每个字之间有间隔。`;
    let index = 0;
    const chars = Array.from(fullText);

    const sendNext = () => {
      if (index < chars.length) {
        callbacks.onContent(chars[index]);
        index++;
        // Random delay between 30-80ms
        this.timerId = setTimeout(sendNext, 30 + Math.random() * 50) as unknown as number;
      } else {
        callbacks.onComplete('stop');
        this.timerId = 0;
      }
    };

    // Start after initial delay
    this.timerId = setTimeout(sendNext, 500) as unknown as number;
  }
}

// ─── Stream response interface (ArkTS http module) ────────

interface HttpStreamResponse {
  responseCode: number;
  header: Object;
  onData: (callback: (chunk: ArrayBuffer) => void) => void;
  onEnd: (callback: () => void) => void;
  onError: (callback: (err: Object) => void) => void;
}
