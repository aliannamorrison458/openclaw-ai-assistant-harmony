// SessionManager.ets — 会话管理服务（多会话存储 + 持久化）
import { preferences } from '@kit.ArkData';
import { ChatSession, ChatMessage } from '../common/ChatTypes';

const PREF_SESSIONS = 'chat_sessions';
const PREF_PREFIX = 'session_msgs_';
const KEY_SESSION_LIST = 'session_list';
const KEY_CURRENT_SESSION_ID = 'current_session_id';

export class SessionManager {
  private static instance: SessionManager | null = null;
  private sessions: ChatSession[] = [];
  private currentSessionId: string = '';
  private prefStore: preferences.Preferences | null = null;
  private _onUpdate: (() => void) | null = null;
  private _initialized: boolean = false;

  private constructor() {}

  static getInstance(): SessionManager {
    if (!SessionManager.instance) {
      SessionManager.instance = new SessionManager();
    }
    return SessionManager.instance;
  }

  onUpdate(callback: () => void): void {
    this._onUpdate = callback;
  }

  private _notify(): void {
    if (this._onUpdate) {
      this._onUpdate();
    }
  }

  async init(): Promise<void> {
    if (this._initialized) return;
    try {
      this.prefStore = await preferences.getPreferences(globalThis.context, PREF_SESSIONS);
      const savedList = await this.prefStore.get(KEY_SESSION_LIST, '[]');
      this.sessions = JSON.parse(savedList as string);
      this.currentSessionId = await this.prefStore.get(KEY_CURRENT_SESSION_ID, '') as string;

      // 如果没有会话，创建默认会话
      if (this.sessions.length === 0) {
        await this.createSession('新对话');
      } else if (!this.currentSessionId || !this.sessions.find(s => s.id === this.currentSessionId)) {
        this.currentSessionId = this.sessions[0].id;
        await this._saveCurrentSessionId();
      }
    } catch (e) {
      console.error('[SessionManager] init error:', JSON.stringify(e));
      this.sessions = [];
      await this.createSession('新对话');
    }
    this._initialized = true;
  }

  getSessions(): ChatSession[] {
    // 按 updatedAt 倒序
    return [...this.sessions].sort((a, b) => b.updatedAt - a.updatedAt);
  }

  getCurrentSessionId(): string {
    return this.currentSessionId;
  }

  getCurrentSession(): ChatSession | null {
    return this.sessions.find(s => s.id === this.currentSessionId) || null;
  }

  async createSession(title?: string): Promise<ChatSession> {
    const now = Date.now();
    const session: ChatSession = {
      id: `${now}-${Math.random().toString(36).substring(2, 9)}`,
      title: title || '新对话',
      createdAt: now,
      updatedAt: now,
      messageCount: 0,
      lastMessagePreview: ''
    };
    this.sessions.push(session);
    this.currentSessionId = session.id;
    await this._persist();
    await this._saveCurrentSessionId();
    // 初始化空消息列表
    await this._saveMessages(session.id, []);
    this._notify();
    return session;
  }

  async switchSession(sessionId: string): Promise<boolean> {
    const session = this.sessions.find(s => s.id === sessionId);
    if (!session) return false;
    this.currentSessionId = sessionId;
    await this._saveCurrentSessionId();
    this._notify();
    return true;
  }

  async deleteSession(sessionId: string): Promise<boolean> {
    const idx = this.sessions.findIndex(s => s.id === sessionId);
    if (idx < 0) return false;

    this.sessions.splice(idx, 1);

    // 删除关联消息
    try {
      const msgPref = await preferences.getPreferences(globalThis.context, PREF_PREFIX + sessionId);
      await msgPref.delete(KEY_SESSION_LIST);
      await msgPref.flush();
    } catch (e) {
      // ignore
    }

    // 如果删除的是当前会话，切换到第一个
    if (this.currentSessionId === sessionId) {
      if (this.sessions.length > 0) {
        this.currentSessionId = this.sessions[0].id;
      } else {
        // 至少保留一个会话
        const newSession = await this.createSession('新对话');
        this.currentSessionId = newSession.id;
      }
      await this._saveCurrentSessionId();
    }

    await this._persist();
    this._notify();
    return true;
  }

  async renameSession(sessionId: string, newTitle: string): Promise<boolean> {
    const session = this.sessions.find(s => s.id === sessionId);
    if (!session) return false;
    session.title = newTitle.trim() || session.title;
    session.updatedAt = Date.now();
    await this._persist();
    this._notify();
    return true;
  }

  searchSessions(keyword: string): ChatSession[] {
    const kw = keyword.trim().toLowerCase();
    if (!kw) return this.getSessions();
    return this.getSessions().filter(s =>
      s.title.toLowerCase().includes(kw)
    );
  }

  async updateSessionOnNewMessage(sessionId: string, message: ChatMessage): Promise<void> {
    const session = this.sessions.find(s => s.id === sessionId);
    if (!session) return;

    session.messageCount += 1;
    session.updatedAt = Date.now();

    // 自动更新标题：第一条用户消息的前20字
    if (message.isUser && session.messageCount <= 1) {
      session.title = message.text.substring(0, 20) || session.title;
    }

    session.lastMessagePreview = message.text.substring(0, 30);

    await this._persist();
    this._notify();
  }

  // 持久化消息
  async saveMessages(sessionId: string, messages: ChatMessage[]): Promise<void> {
    await this._saveMessages(sessionId, messages);
  }

  async loadMessages(sessionId: string): Promise<ChatMessage[]> {
    try {
      const msgPref = await preferences.getPreferences(globalThis.context, PREF_PREFIX + sessionId);
      const saved = await msgPref.get('messages', '[]');
      return JSON.parse(saved as string);
    } catch (e) {
      console.error('[SessionManager] loadMessages error:', JSON.stringify(e));
      return [];
    }
  }

  private async _saveMessages(sessionId: string, messages: ChatMessage[]): Promise<void> {
    try {
      const msgPref = await preferences.getPreferences(globalThis.context, PREF_PREFIX + sessionId);
      await msgPref.put('messages', JSON.stringify(messages));
      await msgPref.flush();
    } catch (e) {
      console.error('[SessionManager] saveMessages error:', JSON.stringify(e));
    }
  }

  private async _persist(): Promise<void> {
    if (!this.prefStore) return;
    try {
      await this.prefStore.put(KEY_SESSION_LIST, JSON.stringify(this.sessions));
      await this.prefStore.flush();
    } catch (e) {
      console.error('[SessionManager] persist error:', JSON.stringify(e));
    }
  }

  private async _saveCurrentSessionId(): Promise<void> {
    if (!this.prefStore) return;
    try {
      await this.prefStore.put(KEY_CURRENT_SESSION_ID, this.currentSessionId);
      await this.prefStore.flush();
    } catch (e) {
      console.error('[SessionManager] saveCurrentSessionId error:', JSON.stringify(e));
    }
  }
}
