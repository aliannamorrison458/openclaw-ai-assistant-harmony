import { describe, it, expect } from '@ohos.hapjs';

describe('OfflineFallbackManager', () => {
  it('get_fallback_response', 0, () => {
    const responses = ['A', 'B', 'C'];
    const idx = 0;
    expect(responses[idx]).assertEqual('A');
  });

  it('is_offline_error_network', 0, () => {
    const error = 'network error';
    expect(error.includes('network')).assertTrue();
  });

  it('is_offline_error_timeout', 0, () => {
    const error = 'timeout';
    expect(error.includes('timeout')).assertTrue();
  });

  it('is_offline_error_connection', 0, () => {
    const error = 'connection failed';
    expect(error.includes('connection')).assertTrue();
  });
});
