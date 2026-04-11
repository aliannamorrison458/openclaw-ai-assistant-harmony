// ChatViewModel.ets — 聊天 ViewModel（集成语音功能 + 多会话支持）
import { ChatMessage, SendStatus, ChatSession, createUserId, createAssistantMessage, createSystemMessage } from '../common/ChatTypes';
import { LLMClient, MockLLMClient, LLMConfig } from '../service/LLMClient';
import { NetworkMonitor, ConnectionType, NetworkQuality } from '../service/NetworkMonitor';
import { VoiceServiceManager, VoiceState } from '../service/VoiceServiceManager';
import { SessionManager } from '../service/SessionManager';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'ai_assistant_prefs';
const KEY_API_BASE = 'api_base_url';
const KEY_API_TOKEN = '***';
const KEY_USE_MOCK = 'use_mock';
const KEY_MODEL = 'model_name';

export class ChatViewModel {
  messages: ChatMessage[] = [];
  isOffline: boolean = false;
  isDegraded: boolean = false;
  isWeakNetwork: boolean = false;
  inputText: string = '';
  currentSessionTitle: string = '新对话';

  // 语音相关状态
  voiceState: VoiceState = VoiceState.IDLE;
  isRecording: boolean = false;
  isVoicePlaying: boolean = false;
  isVoiceProcessing: boolean = false;
  voiceOfflineWarning: string = '';

  private llmClient: LLMClient;
  private mockClient: MockLLMClient;
  private useMock: boolean = true;
  private networkMonitor: NetworkMonitor;
  private voiceManager: VoiceServiceManager;
  private sessionManager: SessionManager;
  private prefStore: preferences.Preferences | null = null;
  private _onUpdate: (() => void) | null = null;
  private _debounceTimer: number = 0;

  constructor() {
    this.llmClient = new LLMClient();
    this.mockClient = new MockLLMClient();
    this.networkMonitor = NetworkMonitor.getInstance();
    this.voiceManager = VoiceServiceManager.getInstance();
    this.sessionManager = SessionManager.getInstance();
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
    // 初始化 SessionManager
    await this.sessionManager.init();

    // 监听会话变化
    this.sessionManager.onUpdate(() => {
      this._refreshCurrentSession();
    });

    // 加载当前会话的消息
    await this._loadCurrentSessionMessages();

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
    this.networkMonitor.addListener((connected: boolean, type: ConnectionType, quality: NetworkQuality) => {
      this.isOffline = !connected;
      this.isDegraded = !connected;
      this.isWeakNetwork = quality === NetworkQuality.WEAK;
      this._notify();
    });

    // 初始化语音管理器回调
    this.voiceManager.onStateChange((state: VoiceState) => {
      this.voiceState = state;
      this.isRecording = state === VoiceState.RECORDING;
      this.isVoiceProcessing = state === VoiceState.PROCESSING;
      this.isVoicePlaying = state === VoiceState.PLAYING;
      this._notify();
    });

    this.voiceManager.onSTTResult((text: string) => {
      this.inputText = text;
      this._notify();
    });

    this.voiceManager.onError((error: string) => {
      this.messages.push(createSystemMessage(`语音错误: ${error}`));
      this._notify();
    });

    this.voiceManager.onOfflineWarning((message: string) => {
      this.voiceOfflineWarning = message;
      this._notify();
      setTimeout(() => {
        this.voiceOfflineWarning = '';
        this._notify();
      }, 3000);
    });
  }

  private async _loadCurrentSessionMessages(): Promise<void> {
    const sessionId = this.sessionManager.getCurrentSessionId();
    if (!sessionId) return;
    this.messages = await this.sessionManager.loadMessages(sessionId);
    const session = this.sessionManager.getCurrentSession();
    this.currentSessionTitle = session?.title || '新对话';
    this._notify();
  }

  private async _refreshCurrentSession(): Promise<void> {
    const session = this.sessionManager.getCurrentSession();
    if (session) {
      this.currentSessionTitle = session.title;
    }
    this._notify();
  }

  // 防抖保存消息
  private _debouncedSaveMessages(): void {
    if (this._debounceTimer) {
      clearTimeout(this._debounceTimer);
    }
    this._debounceTimer = setTimeout(() => {
      const sessionId = this.sessionManager.getCurrentSessionId();
      if (sessionId) {
        this.sessionManager.saveMessages(sessionId, this.messages);
      }
    }, 300);
  }

  get canSend(): boolean {
    return !this.messages.some(m => m.isUser && m.sendStatus === SendStatus.SENDING);
  }

  get canUseVoice(): boolean {
    return !this.isOffline && this.voiceState === VoiceState.IDLE;
  }

  get voiceStateText(): string {
    switch (this.voiceState) {
      case VoiceState.RECORDING: return '录音中...';
      case VoiceState.PROCESSING: return '处理中...';
      case VoiceState.PLAYING: return '播放中...';
      default: return '';
    }
  }

  // 获取会话列表
  getSessions(): ChatSession[] {
    return this.sessionManager.getSessions();
  }

  getCurrentSessionId(): string {
    return this.sessionManager.getCurrentSessionId();
  }

  // 创建新会话
  async createNewSession(): Promise<void> {
    await this.sessionManager.createSession();
    await this._loadCurrentSessionMessages();
  }

  // 切换会话
  async switchSession(sessionId: string): Promise<void> {
    // 先保存当前会话消息
    const currentId = this.sessionManager.getCurrentSessionId();
    if (currentId) {
      await this.sessionManager.saveMessages(currentId, this.messages);
    }
    await this.sessionManager.switchSession(sessionId);
    await this._loadCurrentSessionMessages();
  }

  startVoiceRecording(): void {
    if (this.isOffline) {
      this.messages.push(createSystemMessage('⚠️ 网络已断开，无法使用语音功能'));
      this._notify();
      return;
    }
    this.voiceManager.startRecording();
  }

  stopVoiceRecording(): void {
    this.voiceManager.stopRecordingAndTranscribe();
  }

  cancelVoiceRecording(): void {
    this.voiceManager.cancelRecording();
  }

  speakText(text: string): void {
    if (this.isOffline) {
      this.messages.push(createSystemMessage('⚠️ 网络已断开，语音播报暂不可用'));
      this._notify();
      return;
    }
    this.voiceManager.speak(text);
  }

  stopSpeaking(): void {
    this.voiceManager.stopSpeaking();
  }

  async send(text: string, quotedMessageId?: string, quotedText?: string): Promise<void> {
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

    // 更新会话信息
    await this.sessionManager.updateSessionOnNewMessage(
      this.sessionManager.getCurrentSessionId(),
      userMsg
    );
    this._debouncedSaveMessages();
    this._notify();

    const callback = (response: { success: boolean; content: string; error?: string }) => {
      const idx = this.messages.findIndex(m => m.id === messageId);
      if (idx < 0) return;

      if (response.success) {
        this.messages[idx].sendStatus = SendStatus.SENT;
        const assistantMsg = createAssistantMessage(response.content);
        this.messages.push(assistantMsg);
        this.sessionManager.updateSessionOnNewMessage(
          this.sessionManager.getCurrentSessionId(),
          assistantMsg
        );
      } else {
        this.messages[idx].sendStatus = SendStatus.FAILED;
        this.messages.push(createSystemMessage(`错误: ${response.error || '未知错误'}`));
      }
      this._debouncedSaveMessages();
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
      this._debouncedSaveMessages();
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
      this._debouncedSaveMessages();
      this._notify();
    }
  }

  clearAll(): void {
    this.messages = [];
    this._debouncedSaveMessages();
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
