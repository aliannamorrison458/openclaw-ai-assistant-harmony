// ChatSessionManager Test (H3)
import { describe, it, expect } from '@ohos.hapjs';

describe('ChatSessionManager', () => {
  // T01: createSession
  it('createSession', 0, async () => {
    const mgr = await import('../services/ChatSessionManager');
    const session = await mgr.default.createSession('Test');
    expect(session.id !== null).assertTrue();
    expect(session.title).assertEqual('Test');
  });

  // T02: getSession
  it('getSession', 0, async () => {
    const mgr = await import('../services/ChatSessionManager');
    const session = await mgr.default.createSession('Test2');
    const found = mgr.default.getSession(session.id);
    expect(found !== null).assertTrue();
    expect(found.id).assertEqual(session.id);
  });

  // T03: addMessage
  it('addMessage', 0, async () => {
    const mgr = await import('../services/ChatSessionManager');
    const session = await mgr.default.createSession('Test3');
    mgr.default.addMessage(session.id, { role: 'user', content: 'Hello' });
    const updated = mgr.default.getSession(session.id);
    expect(updated.messages.length).assertEqual(1);
    expect(updated.messages[0].content).assertEqual('Hello');
  });

  // T04: deleteSession
  it('deleteSession', 0, async () => {
    const mgr = await import('../services/ChatSessionManager');
    const session = await mgr.default.createSession('Test4');
    const result = mgr.default.deleteSession(session.id);
    expect(result).assertTrue();
    const found = mgr.default.getSession(session.id);
    expect(found).assertNull();
  });

  // T05: renameSession
  it('renameSession', 0, async () => {
    const mgr = await import('../services/ChatSessionManager');
    const session = await mgr.default.createSession('Old');
    const result = mgr.default.renameSession(session.id, 'New');
    expect(result).assertTrue();
    const updated = mgr.default.getSession(session.id);
    expect(updated.title).assertEqual('New');
  });

  // T06: getAllSessions
  it('getAllSessions', 0, async () => {
    const mgr = await import('../services/ChatSessionManager');
    const sessions = mgr.default.getAllSessions();
    expect(Array.isArray(sessions)).assertTrue();
  });
});
