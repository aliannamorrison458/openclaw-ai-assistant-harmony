// EntryAbility Test (H1)
import { describe, it, expect } from '@ohos.hapjs';

describe('EntryAbility', () => {
  // T01: Entry class exists
  it('Entry_class_exists', 0, async () => {
    const entry = await import('../entry');
    expect(entry !== null).assertTrue();
  });

  // T02: Default export exists
  it('default_export_exists', 0, async () => {
    const entry = await import('../entry');
    expect(typeof entry.default).assertEqual('object');
  });
});
