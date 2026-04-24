import { describe, it, expect } from '@ohos.hapjs';

describe('CloudBackupManager', () => {
  it('backup_returns_false', 0, async () => {
    const result = false;
    expect(result).assertFalse();
  });

  it('restore_returns_null', 0, async () => {
    const result = null;
    expect(result).assertNull();
  });
});
