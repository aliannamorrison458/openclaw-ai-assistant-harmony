// OfflineFallbackManager - Offline graceful degradation
class OfflineFallbackManager {
  private static OFFLINE_RESPONSES: string[] = [
    '网络不可用，请检查连接后重试',
    '抱歉，当前无法连接到服务器',
    '请检查网络设置后再次尝试',
  ];

  static getFallbackResponse(): string {
    const idx = Math.floor(Math.random() * OfflineFallbackManager.OFFLINE_RESPONSES.length);
    return OfflineFallbackManager.OFFLINE_RESPONSES[idx];
  }

  static isOfflineError(error: string): boolean {
    return error.includes('network') || 
           error.includes('timeout') || 
           error.includes('connection') ||
           error.includes('offline');
  }
}

export default OfflineFallbackManager;
