// Accessibility - VoiceOver/TalkBack labels
class Accessibility {
  // Semantic labels for screen readers
  static CHAT_MESSAGE = 'Chat message';
  static SEND_BUTTON = 'Send message button';
  static VOICE_BUTTON = 'Voice input button';
  static SETTINGS_BUTTON = 'Settings button';
  static BACK_BUTTON = 'Go back';
  static SESSION_ITEM = 'Conversation item';
  
  static describe(element: string, details: string): string {
    return `${element}: ${details}`;
  }
}

export default Accessibility;
