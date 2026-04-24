// ChatSessionManager - Session management (H3)
import preferences from '@ohos.data.preferences';

interface ChatSession {
  id: string;
  title: string;
  messages: Array<{ role: string; content: string; timestamp?: number }>;
  createdAt: number;
  updatedAt: number;
}

var sessions: Map<string, ChatSession> = new Map();
var currentSessionId: string | null = null;

class ChatSessionManager {
  async createSession(title: string): Promise<ChatSession> {
    const session: ChatSession = {
      id: `session_${Date.now()}`,
      title: title,
      messages: [],
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };
    sessions.set(session.id, session);
    currentSessionId = session.id;
    return session;
  }

  getSession(id: string): ChatSession | null {
    return sessions.get(id) ?? null;
  }

  getCurrentSession(): ChatSession | null {
    if (currentSessionId) {
      return sessions.get(currentSessionId) ?? null;
    }
    return null;
  }

  getAllSessions(): ChatSession[] {
    return Array.from(sessions.values()).sort((a, b) => b.updatedAt - a.updatedAt);
  }

  addMessage(sessionId: string, message: { role: string; content: string }): void {
    const session = sessions.get(sessionId);
    if (session) {
      session.messages.push({
        ...message,
        timestamp: Date.now(),
      });
      session.updatedAt = Date.now();
    }
  }

  deleteSession(id: string): boolean {
    return sessions.delete(id);
  }

  renameSession(id: string, title: string): boolean {
    const session = sessions.get(id);
    if (session) {
      session.title = title;
      session.updatedAt = Date.now();
      return true;
    }
    return false;
  }
}

export default new ChatSessionManager();
