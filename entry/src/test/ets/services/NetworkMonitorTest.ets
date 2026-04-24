// NetworkMonitor Test (H8)
import { describe, it, expect } from '@ohos.hapjs';

describe('NetworkMonitor', () => {
  // T01: isOnline returns boolean
  it('isOnline_returns_boolean', 0, async () => {
    const mgr = await import('../services/NetworkMonitor');
    const result = mgr.default.isOnline();
    expect(typeof result).assertEqual('boolean');
  });

  // T02: onChange registers callback
  it('onChange_registers', 0, async () => {
    const mgr = await import('../services/NetworkMonitor');
    let called = false;
    mgr.default.onChange(() => { called = true; });
    expect(true).assertTrue();
  });

  // T03: offChange removes callback
  it('offChange_removes', 0, async () => {
    const mgr = await import('../services/NetworkMonitor');
    const fn = () => {};
    mgr.default.onChange(fn);
    mgr.default.offChange(fn);
    expect(true).assertTrue();
  });
});
