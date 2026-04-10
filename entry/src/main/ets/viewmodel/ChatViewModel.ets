// ChatViewModel.ets — 聊天 ViewModel（对齐 iOS ChatViewModel）
import { ChatMessage, SendStatus, createUserId, createAssistantMessage, createSystemMessage } from '../common/ChatTypes';
import { LLMClient, MockLLMClient, LLMConfig } from '../service/LLMClient';
import { NetworkMonitor, ConnectionType } from '../service/NetworkMonitor';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'ai_assistant_prefs';
const KEY_API_BASE = 'api_base_url';
const KEY_API_TOKEN = 'api_token';
const KEY_USE_MOCK = 'use_mock';
const KEY_MODEL = 'model_name';

export class ChatViewModel {
  messages: ChatMessage[] = [];
  isOffline: boolean = false;
  isDegraded: boolean = false;
  inputText: string = '';

  private llmClient: LLMClient;
  private mockClient: MockLLMClient;
  private useMock: boolean = true;
  private networkMonitor: NetworkMonitor;
  private prefStore: preferences.Preferences | null = null;
  private _onUpdate: (() => void) | null = null;

  constructor() {
    this.llmClient = new LLMClient();
    this.mockClient = new MockLLMClient();
    this.networkMonitor = NetworkMonitor.getInstance();
    this._init();
  }

  onUpdate(callback: () => void): void {
    this._onUpdate = callback;
  }

  private _notify(): void {
    if (this._onUpdate) {
      this._onUpdate();
    }
  }

  private async _init(): Promise<void> {
    // Load preferences
    try {
      this.prefStore = await preferences.getPreferences(globalThis.context, PREF_NAME);
      const useMock = await this.prefStore.get(KEY_USE_MOCK, true);
      this.useMock = useMock as boolean;

      const baseURL = await this.prefStore.get(KEY_API_BASE, 'https://api.openai.com/v1');
      const apiKey = await this.prefStore.get(KEY_API_TOKEN, '');
      const model = await this.prefStore.get(KEY_MODEL, 'gpt-3.5-turbo');

      this.llmClient.updateConfig({
        baseURL: baseURL as string,
        apiKey: apiKey as string,
        model: model as string
      });
    } catch (e) {
      console.error('[ChatViewModel] prefs init error:', JSON.stringify(e));
    }

    // Start network monitoring
    this.networkMonitor.start();
    this.networkMonitor.addListener((connected, type) => {
      this.isOffline = !connected;
      this.isDegraded = !connected;
      this._notify();
    });
  }

  get canSend(): boolean {
    return !this.messages.some(m => m.isUser && m.sendStatus === SendStatus.SENDING);
  }

  send(text: string, quotedMessageId?: string, quotedText?: string): void {
    if (!text.trim()) return;
    if (!this.canSend) return;

    const wasOffline = this.isOffline;

    const userMsg = createUserId(text);
    userMsg.sendStatus = SendStatus.SENDING;
    userMsg.isDegraded = wasOffline;
    userMsg.quotedMessageId = quotedMessageId;
    userMsg.quotedText = quotedText;

    this.messages.push(userMsg);
    const messageId = userMsg.id;

    if (wasOffline) {
      this.messages.push(createSystemMessage('⚠️ 已降级到本地模式'));
    }

    this._notify();

    const callback = (response: { success: boolean; content: string; error?: string }) => {
      const idx = this.messages.findIndex(m => m.id === messageId);
      if (idx < 0) return;

      if (response.success) {
        this.messages[idx].sendStatus = SendStatus.SENT;
        this.messages.push(createAssistantMessage(response.content));
      } else {
        this.messages[idx].sendStatus = SendStatus.FAILED;
        this.messages.push(createSystemMessage(`错误: ${response.error || '未知错误'}`));
      }
      this._notify();
    };

    if (this.useMock || wasOffline) {
      this.mockClient.sendMessage(text, callback);
    } else {
      this.llmClient.sendMessage(text, callback);
    }
  }

  retry(messageId: string): void {
    const idx = this.messages.findIndex(m => m.id === messageId);
    if (idx < 0) return;

    const msg = this.messages[idx];
    if (!msg.isUser || msg.sendStatus !== SendStatus.FAILED) return;

    this.messages[idx].sendStatus = SendStatus.SENDING;
    this._notify();

    const callback = (response: { success: boolean; content: string; error?: string }) => {
      if (response.success) {
        this.messages[idx].sendStatus = SendStatus.SENT;
        this.messages.push(createAssistantMessage(response.content));
      } else {
        this.messages[idx].sendStatus = SendStatus.FAILED;
      }
      this._notify();
    };

    if (this.useMock || this.isOffline) {
      this.mockClient.sendMessage(msg.text, callback);
    } else {
      this.llmClient.sendMessage(msg.text, callback);
    }
  }

  deleteMessage(messageId: string): void {
    const idx = this.messages.findIndex(m => m.id === messageId);
    if (idx >= 0) {
      this.messages.splice(idx, 1);
      this._notify();
    }
  }

  clearAll(): void {
    this.messages = [];
    this._notify();
  }

  async saveSettings(baseURL: string, apiKey: string, useMock: boolean, model: string): Promise<void> {
    this.useMock = useMock;
    this.llmClient.updateConfig({ baseURL, apiKey, model });

    if (this.prefStore) {
      await this.prefStore.put(KEY_API_BASE, baseURL);
      await this.prefStore.put(KEY_API_TOKEN, apiKey);
      await this.prefStore.put(KEY_USE_MOCK, useMock);
      await this.prefStore.put(KEY_MODEL, model);
      await this.prefStore.flush();
    }
  }

  async loadSettings(): Promise<{ baseURL: string; apiKey: string; useMock: boolean; model: string }> {
    if (!this.prefStore) {
      return { baseURL: 'https://api.openai.com/v1', apiKey: '', useMock: true, model: 'gpt-3.5-turbo' };
    }
    return {
      baseURL: await this.prefStore.get(KEY_API_BASE, 'https://api.openai.com/v1') as string,
      apiKey: await this.prefStore.get(KEY_API_TOKEN, '') as string,
      useMock: await this.prefStore.get(KEY_USE_MOCK, true) as boolean,
      model: await this.prefStore.get(KEY_MODEL, 'gpt-3.5-turbo') as string
    };
  }
}
