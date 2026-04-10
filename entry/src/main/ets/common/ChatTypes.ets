// ChatTypes.ets — 聊天数据模型（对齐 iOS ChatMessage + Android ChatEntity）

export enum SendStatus {
  NONE = 'none',       // 非用户消息
  SENDING = 'sending', // 发送中
  SENT = 'sent',       // 已发送
  FAILED = 'failed'    // 发送失败
}

export interface ChatMessage {
  id: string;
  text: string;
  isUser: boolean;
  sendStatus: SendStatus;
  createdAt: number;     // Unix timestamp ms
  isDegraded: boolean;   // 离线降级标记
  isRead: boolean;       // 已读状态
  isRecalled: boolean;   // 已撤回
  quotedMessageId?: string;
  quotedText?: string;
  imageData?: string;    // base64 encoded image
}

export interface ChatSession {
  id: string;
  title: string;
  createdAt: number;
  updatedAt: number;
  messageCount: number;
  lastMessagePreview: string;
}

export function createUserId(text: string): ChatMessage {
  return {
    id: generateId(),
    text: text,
    isUser: true,
    sendStatus: SendStatus.SENDING,
    createdAt: Date.now(),
    isDegraded: false,
    isRead: false,
    isRecalled: false
  };
}

export function createAssistantMessage(text: string): ChatMessage {
  return {
    id: generateId(),
    text: text,
    isUser: false,
    sendStatus: SendStatus.NONE,
    createdAt: Date.now(),
    isDegraded: false,
    isRead: false,
    isRecalled: false
  };
}

export function createSystemMessage(text: string): ChatMessage {
  return {
    id: generateId(),
    text: text,
    isUser: false,
    sendStatus: SendStatus.NONE,
    createdAt: Date.now(),
    isDegraded: false,
    isRead: false,
    isRecalled: false
  };
}

function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
}
