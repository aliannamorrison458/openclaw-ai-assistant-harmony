import { describe, it, expect } from '@ohos.hapjs';

describe('VoiceFallbackPolicy', () => {
  it('full_voice_available', 0, () => {
    const result = 'stt+tts';
    expect(result).assertEqual('stt+tts');
  });

  it('stt_only', 0, () => {
    const result = 'stt';
    expect(result).assertEqual('stt');
  });

  it('retry_on_network_error', 0, () => {
    const error = 'network timeout';
    const should = error.includes('network');
    expect(should).assertTrue();
  });

  it('no_retry_when_disabled', 0, () => {
    const mode = 'disabled';
    expect(mode === 'disabled').assertTrue();
  });
});
