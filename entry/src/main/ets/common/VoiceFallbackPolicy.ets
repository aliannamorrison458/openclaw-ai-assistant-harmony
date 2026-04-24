// VoiceFallbackPolicy - Voice service fallback
enum VoiceMode {
  STT_TTS = 'stt+tts',      // Full voice
  STT_ONLY = 'stt',         // Speech to text only
  TTS_ONLY = 'tts',         // Text to speech only
  DISABLED = 'disabled',      // Voice disabled
}

class VoiceFallbackPolicy {
  private static PRIORITY: VoiceMode[] = [
    VoiceMode.STT_TTS,
    VoiceMode.STT_ONLY,
    VoiceMode.TTS_ONLY,
    VoiceMode.DISABLED,
  ];

  static getBestAvailableMode(sttAvailable: boolean, ttsAvailable: boolean): VoiceMode {
    if (sttAvailable && ttsAvailable) {
      return VoiceMode.STT_TTS;
    }
    if (sttAvailable) {
      return VoiceMode.STT_ONLY;
    }
    if (ttsAvailable) {
      return VoiceMode.TTS_ONLY;
    }
    return VoiceMode.DISABLED;
  }

  static shouldRetry(mode: VoiceMode, error: string): boolean {
    if (mode === VoiceMode.DISABLED) {
      return false;
    }
    return error.includes('network') || error.includes('timeout');
  }
}

export default VoiceFallbackPolicy;
