// VoiceRecorder Test (H5)
import { describe, it, expect } from '@ohos.hapjs';

describe('VoiceRecorder', () => {
  // T01: isActive returns boolean
  it('isActive_returns_false_initially', 0, async () => {
    const mgr = await import('../services/VoiceRecorder');
    expect(mgr.default.isActive()).assertFalse();
  });

  // T02: startRecording method exists
  it('startRecording_method_exists', 0, async () => {
    const mgr = await import('../services/VoiceRecorder');
    expect(typeof mgr.default.startRecording).assertEqual('function');
  });

  // T03: stopRecording method exists
  it('stopRecording_method_exists', 0, async () => {
    const mgr = await import('../services/VoiceRecorder');
    expect(typeof mgr.default.stopRecording).assertEqual('function');
  });
});
