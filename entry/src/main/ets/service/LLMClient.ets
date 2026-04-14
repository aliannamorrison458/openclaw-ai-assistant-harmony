// LLMClient.ets — LLM API 客户端（SSE streaming + tool use + thinking）
// 对齐 iOS OpenAIClient + Android OpenAIClient
import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { ChatMessage, MessageType } from '../common/ChatTypes';

// ─── Conversation types (for LLM API) ─────────────────────

export interface ToolCall {
  id: string;
  name: string;
  arguments: string;
}

export interface ConversationMessage {
  role: string;
  content: string;
  toolCalls?: ToolCall[];
  toolCallId?: string;
  name?: string;
}

// ─── Config ───────────────────────────────────────────────

export interface LLMConfig {
  baseURL: string;
  apiKey: string;
  model: string;
  maxTokens?: number;
  temperature?: number;
  tools?: ToolDefinition[];
}

interface ToolFunctionDef {
  name: string;
  description: string;
  parameters: Record<string, Object>;
}

export interface ToolDefinition {
  type: string;
  function: ToolFunctionDef;
}

const DEFAULT_CONFIG: LLMConfig = {
  baseURL: 'https://api.openai.com/v1',
  apiKey: '',
  model: 'gpt-3.5-turbo',
  maxTokens: 4096,
  temperature: 0.7
};

// ─── Streaming event types ────────────────────────────────

interface StreamFunctionDelta {
  name?: string;
  arguments?: string;
}

export interface StreamToolCallDelta {
  index: number;
  id?: string;
  type?: string;
  function?: StreamFunctionDelta;
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
  onToolCall: (toolCalls: ToolCallInfo[]) => void;
  onComplete: (finishReason: string) => void;
  onError: (error: string) => void;
}

export class ToolCallInfo {
  name: string = '';
  arguments: string = '';
  id: string = '';
}

export class SendMessageResponse {
  success: boolean = false;
  content: string = '';
  thinking?: string;
  error?: string;
}

// Request body class for ArkTS strict mode
export class ChatRequestBody {
  model: string = '';
  messages: ConversationMessage[] = [];
  stream: boolean = false;
  max_tokens?: number;
  temperature?: number;
  tools?: Object[];
}

// Response parsed from JSON
export interface ChatChoice {
  message: ChatResponseMessage;
  index?: number;
  finish_reason?: string;
}

export interface ChatResponseMessage {
  content: string;
  reasoning?: string;
  reasoning_content?: string;
  tool_calls?: ChatToolCall[];
}

export interface ChatToolCall {
  id: string;
  function: ChatToolCallFunc;
  type?: string;
}

export interface ChatToolCallFunc {
  name: string;
  arguments: string;
}

export interface ChatApiResponse {
  choices?: ChatChoice[];
  error?: ChatApiError;
}

export interface ChatApiError {
  message: string;
  type?: string;
  code?: string;
}

// SSE stream parsed delta
export interface StreamDelta {
  role?: string;
  content?: string;
  reasoning?: string;
  reasoning_content?: string;
  tool_calls?: ChatToolCall[];
}

export interface StreamChoice {
  delta: StreamDelta;
  index?: number;
  finish_reason?: string;
}

export interface StreamChunk {
  choices?: StreamChoice[];
  error?: ChatApiError;
}

// Interface for buildConversationHistory input
export interface ConversationInput {
  role: string;
  content: string;
  toolCalls?: ToolCall[];
  toolCallId?: string;
  name?: string;
}

export interface LLMResponse {
  success: boolean;
  content: string;
  thinking?: string;
  toolCalls?: ToolCall[];
  error?: string;
}

// ─── Non-streaming response interfaces ────────────────────

interface ParsedSSEError {
  message: string;
}

interface ParsedToolCallFunc {
  name: string;
  arguments: string;
}

interface ParsedToolCall {
  id: string;
  function: ParsedToolCallFunc;
}

interface ParsedMessage {
  content: string;
  reasoning?: string;
  reasoning_content?: string;
  tool_calls?: ParsedToolCall[];
}

interface ParsedChoice {
  message: ParsedMessage;
  finish_reason?: string;
}

interface ParsedCompletionResponse {
  error?: ParsedSSEError;
  choices?: ParsedChoice[];
}

// ─── SSE parser ───────────────────────────────────────────

interface ParsedSSEDelta {
  content?: string;
  reasoning?: string;
  reasoning_content?: string;
  tool_calls?: StreamToolCallDelta[];
}

interface ParsedSSEChoice {
  delta?: ParsedSSEDelta;
  finish_reason?: string;
}

interface ParsedSSEResponse {
  error?: ParsedSSEError;
  choices?: ParsedSSEChoice[];
}

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
      const json: ParsedSSEResponse = JSON.parse(data) as ParsedSSEResponse;

      // Handle error responses
      if (json.error) {
        return { type: 'error', content: json.error.message || 'Unknown error' };
      }

      const choices: ParsedSSEChoice[] = json.choices || [];
      if (choices.length === 0) {
        return null;
      }

      const choice: ParsedSSEChoice = choices[0];
      const delta: ParsedSSEDelta | undefined = choice.delta;
      if (!delta) {
        return null;
      }

      // Thinking / reasoning content (Claude-style or extended models)
      if (delta.reasoning || delta.reasoning_content) {
        const thinkingText: string = delta.reasoning || delta.reasoning_content || '';
        return { type: 'thinking', content: thinkingText };
      }

      // Tool calls delta
      if (delta.tool_calls && delta.tool_calls.length > 0) {
        return {
          type: 'tool_use',
          content: '',
          toolCalls: delta.tool_calls
        };
      }

      // Regular content
      if (delta.content) {
        return { type: 'content', content: delta.content };
      }

      // Finish reason
      if (choice.finish_reason) {
        return { type: 'done', content: '', finishReason: choice.finish_reason };
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

  constructor(config?: LLMConfig) {
    if (config) {
      this.config = {
        baseURL: config.baseURL || DEFAULT_CONFIG.baseURL,
        apiKey: config.apiKey || DEFAULT_CONFIG.apiKey,
        model: config.model || DEFAULT_CONFIG.model,
        maxTokens: config.maxTokens || DEFAULT_CONFIG.maxTokens,
        temperature: config.temperature || DEFAULT_CONFIG.temperature,
        tools: config.tools
      };
    } else {
      this.config = {
        baseURL: DEFAULT_CONFIG.baseURL,
        apiKey: DEFAULT_CONFIG.apiKey,
        model: DEFAULT_CONFIG.model,
        maxTokens: DEFAULT_CONFIG.maxTokens,
        temperature: DEFAULT_CONFIG.temperature
      };
    }
  }

  updateConfig(config: LLMConfig): void {
    this.config = {
      baseURL: config.baseURL || this.config.baseURL,
      apiKey: config.apiKey || this.config.apiKey,
      model: config.model || this.config.model,
      maxTokens: config.maxTokens || this.config.maxTokens,
      temperature: config.temperature || this.config.temperature,
      tools: config.tools !== undefined ? config.tools : this.config.tools
    };
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

  sendMessage(prompt: string, callback: (response: LLMResponse) => void, systemPrompt?: string): void {
    if (!this.config.apiKey) {
      callback({ success: false, content: '', error: 'API Key 未配置，请在设置中填写' });
      return;
    }

    const httpRequest = http.createHttp();
    const url = `${this.config.baseURL}/chat/completions`;

    const messages: ConversationMessage[] = [];
    if (systemPrompt && systemPrompt.trim().length > 0) {
      messages.push({ role: 'system', content: systemPrompt.trim() });
    }
    messages.push({ role: 'user', content: prompt });

    const bodyObj: ChatRequestBody = {
      model: this.config.model,
      messages: messages,
      stream: false,
      max_tokens: this.config.maxTokens,
      temperature: this.config.temperature
    };

    if (this.config.tools && this.config.tools.length > 0) {
      bodyObj.tools = this.config.tools;
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
    }, (err: Error | undefined, data: http.HttpResponse) => {
      if (err) {
        console.error('[LLMClient] request error:', JSON.stringify(err));
        callback({ success: false, content: '', error: `网络请求失败: ${err}` });
        return;
      }

      try {
        const rawResult: Object = JSON.parse(data.result as string);
        const result: ChatApiResponse = rawResult as ChatApiResponse;
        if (result.choices && result.choices.length > 0) {
          const choice: ChatChoice = result.choices[0];
          const message: ChatResponseMessage = choice.message;

          let toolCalls: ToolCall[] | undefined;
          if (message.tool_calls && message.tool_calls.length > 0) {
            toolCalls = [];
            for (let ti = 0; ti < message.tool_calls.length; ti++) {
              const tc: ChatToolCall = message.tool_calls[ti];
              toolCalls.push({
                id: tc.id,
                name: tc.function.name,
                arguments: tc.function.arguments
              });
            }
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
    callbacks: LLMStreamCallbacks,
    systemPrompt?: string
  ): void {
    if (!this.config.apiKey) {
      callbacks.onError('API Key 未配置，请在设置中填写');
      return;
    }

    const httpRequest = http.createHttp();
    const url = `${this.config.baseURL}/chat/completions`;

    // Prepend system prompt if provided
    const finalMessages: ConversationMessage[] = [];
    if (systemPrompt && systemPrompt.trim().length > 0) {
      finalMessages.push({ role: 'system', content: systemPrompt.trim() });
    }
    for (let mi = 0; mi < messages.length; mi++) {
      finalMessages.push(messages[mi]);
    }

    const bodyObj: ChatRequestBody = {
      model: this.config.model,
      messages: finalMessages,
      stream: true,
      max_tokens: this.config.maxTokens,
      temperature: this.config.temperature
    };

    if (this.config.tools && this.config.tools.length > 0) {
      bodyObj.tools = this.config.tools;
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
    }, (err: Error | undefined, statusCode: number) => {
      if (err) {
        console.error('[LLMClient] stream request error:', JSON.stringify(err));
        callbacks.onError(`网络请求失败: ${err}`);
        this.abortController = null;
        httpRequest.destroy();
        return;
      }
      console.info('[LLMClient] stream started, status:', statusCode);
    });

    // Event-based streaming handlers (HarmonyOS NetworkKit API)
    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      if (isAborted) return;
      try {
        const textDecoder = new util.TextDecoder('utf-8');
        const raw = textDecoder.decode(new Uint8Array(data));
        const events = sseParser.addData(raw);
        this.processEvents(events, partialToolCalls, callbacks);
      } catch (e) {
        console.error('[LLMClient] chunk decode error');
      }
    });

    httpRequest.on('dataEnd', () => {
      if (isAborted) return;
      // Flush remaining buffer
      const remaining = sseParser.flush();
      this.processEvents(remaining, partialToolCalls, callbacks);

      // If tool calls were accumulated, send them
      if (partialToolCalls.size > 0) {
        const toolCalls: ToolCall[] = [];
        const keys: number[] = [];
        partialToolCalls.forEach((value: PartialToolCall, key: number) => {
          keys.push(key);
        });
        keys.sort((a: number, b: number): number => a - b);
        for (let ki = 0; ki < keys.length; ki++) {
          const idx = keys[ki];
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
      httpRequest.destroy();
    });

    httpRequest.destroy();
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
            const doneKeys: number[] = [];
            partialToolCalls.forEach((value: PartialToolCall, key: number) => {
              doneKeys.push(key);
            });
            doneKeys.sort((a: number, b: number): number => a - b);
            for (let ki = 0; ki < doneKeys.length; ki++) {
              const idx = doneKeys[ki];
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
    messages: ConversationInput[]
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
    const delay: number = 800 + Math.floor(Math.random() * 500);
    this.timerId = setTimeout(() => {
      callback({
        success: true,
        content: `这是模拟回复。你发送了：「${prompt}」\n\nAI 助手正在处理你的请求。当前为离线模拟模式。`
      });
      this.timerId = 0;
    }, delay);
  }

  // Mock streaming: simulates token-by-token output
  sendStreaming(
    prompt: string,
    callbacks: LLMStreamCallbacks
  ): void {
    const fullText = `这是模拟的流式回复。你发送了：「${prompt}」\n\nAI 助手正在逐字输出，模拟流式传输效果。每个字之间有间隔。`;
    let index = 0;
    const chars: string[] = [];
    for (let ci = 0; ci < fullText.length; ci++) {
      chars.push(fullText.charAt(ci));
    }

    const sendNext = () => {
      if (index < chars.length) {
        callbacks.onContent(chars[index]);
        index++;
        // Random delay between 30-80ms
        const nextDelay: number = 30 + Math.floor(Math.random() * 50);
        this.timerId = setTimeout(sendNext, nextDelay);
      } else {
        callbacks.onComplete('stop');
        this.timerId = 0;
      }
    };

    // Start after initial delay
    this.timerId = setTimeout(sendNext, 500);
  }
}

// ─── Stream response interface (ArkTS http module) ────────

interface HttpStreamResponse {
  responseCode: number;
  header: Record<string, string>;
  onData: (callback: (chunk: ArrayBuffer) => void) => void;
  onEnd: (callback: () => void) => void;
  onError: (callback: (err: Error) => void) => void;
}
