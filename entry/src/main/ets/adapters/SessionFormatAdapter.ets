// SessionFormatAdapter - Cross-platform data adapter (H7)
// Converts between iOS/Android/HarmonyOS session formats

interface iOSSession {
  id: string;
  title: string;
  messages: Array<{ role: string; content: string; createdAt: number }>;
  createdAt: number;
  updatedAt: number;
}

interface AndroidSession {
  sessionId: string;
  sessionTitle: string;
  messageList: Array<{ messageRole: string; messageContent: string; messageTime: number }>;
  createdTime: number;
  updatedTime: number;
}

interface HarmonySession {
  id: string;
  title: string;
  messages: Array<{ role: string; content: string; timestamp: number }>;
  createdAt: number;
  updatedAt: number;
}

class SessionFormatAdapter {
  // iOS -> HarmonyOS
  fromiOS(session: iOSSession): HarmonySession {
    return {
      id: session.id,
      title: session.title,
      messages: session.messages.map(m => ({
        role: m.role,
        content: m.content,
        timestamp: m.createdAt,
      })),
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    };
  }

  // Android -> HarmonyOS
  fromAndroid(session: AndroidSession): HarmonySession {
    return {
      id: session.sessionId,
      title: session.sessionTitle,
      messages: session.messageList.map(m => ({
        role: m.messageRole,
        content: m.messageContent,
        timestamp: m.messageTime,
      })),
      createdAt: session.createdTime,
      updatedAt: session.updatedTime,
    };
  }

  // HarmonyOS -> iOS
  toiOS(session: HarmonySession): iOSSession {
    return {
      id: session.id,
      title: session.title,
      messages: session.messages.map(m => ({
        role: m.role,
        content: m.content,
        createdAt: m.timestamp,
      })),
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    };
  }

  // HarmonyOS -> Android
  toAndroid(session: HarmonySession): AndroidSession {
    return {
      sessionId: session.id,
      sessionTitle: session.title,
      messageList: session.messages.map(m => ({
        messageRole: m.role,
        messageContent: m.content,
        messageTime: m.timestamp,
      })),
      createdTime: session.createdAt,
      updatedTime: session.updatedAt,
    };
  }

  // Export to JSON
  toJSON(session: HarmonySession): string {
    return JSON.stringify(session);
  }

  // Import from JSON
  fromJSON(json: string): HarmonySession {
    return JSON.parse(json);
  }
}

export default new SessionFormatAdapter();
