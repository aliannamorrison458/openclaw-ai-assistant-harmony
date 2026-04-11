// ChatTypes.ets — 聊天数据模型（对齐 iOS ChatMessage + Android ChatEntity）

export enum SendStatus {
  NONE = 'none',       // 非用户消息
  SENDING = 'sending', // 发送中
  SENT = 'sent',       // 已发送
  FAILED = 'failed'    // 发送失败
}

export enum MessageType {
  TEXT = 'text',        // 文本消息
  VOICE = 'voice',      // 语音消息
  SYSTEM = 'system'     // 系统消息
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
  messageType?: MessageType; // 消息类型
  voiceDuration?: number; // 语音消息时长（秒）
  voicePath?: string;     // 语音文件路径
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
    isRecalled: false,
    messageType: MessageType.TEXT
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
    isRecalled: false,
    messageType: MessageType.TEXT
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
    isRecalled: false,
    messageType: MessageType.SYSTEM
  };
}

export function createVoiceMessage(text: string, isUser: boolean, voiceDuration?: number, voicePath?: string): ChatMessage {
  return {
    id: generateId(),
    text: text,
    isUser: isUser,
    sendStatus: isUser ? SendStatus.SENDING : SendStatus.NONE,
    createdAt: Date.now(),
    isDegraded: false,
    isRead: false,
    isRecalled: false,
    messageType: MessageType.VOICE,
    voiceDuration: voiceDuration,
    voicePath: voicePath
  };
}

function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
}
