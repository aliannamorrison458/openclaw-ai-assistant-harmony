// NetworkMonitor.ets — 网络状态监测（对齐 iOS NWPathMonitor + Android NetworkMonitor）
import { netConnection } from '@kit.NetworkKit';

export enum ConnectionType {
  NONE = 'none',
  WIFI = 'wifi',
  CELLULAR = 'cellular',
  UNKNOWN = 'unknown'
}

export class NetworkMonitor {
  private static instance: NetworkMonitor;
  private _isConnected: boolean = true;
  private _connectionType: ConnectionType = ConnectionType.UNKNOWN;
  private _netConn: any = null;
  private _listeners: Array<(connected: boolean, type: ConnectionType) => void> = [];

  private constructor() {}

  static getInstance(): NetworkMonitor {
    if (!NetworkMonitor.instance) {
      NetworkMonitor.instance = new NetworkMonitor();
    }
    return NetworkMonitor.instance;
  }

  get isConnected(): boolean {
    return this._isConnected;
  }

  get connectionType(): ConnectionType {
    return this._connectionType;
  }

  get statusText(): string {
    if (!this._isConnected) return '离线';
    switch (this._connectionType) {
      case ConnectionType.WIFI: return 'WiFi';
      case ConnectionType.CELLULAR: return '移动数据';
      default: return '已连接';
    }
  }

  start(): void {
    try {
      this._netConn = netConnection.createNetConnection();
      this._netConn.register((error: any) => {
        if (error) {
          console.error('[NetworkMonitor] register error:', JSON.stringify(error));
          return;
        }
        console.info('[NetworkMonitor] registered');
      });

      this._netConn.on('netAvailable', (data: any) => {
        this._isConnected = true;
        this._updateConnectionType(data);
        this._notifyListeners();
      });

      this._netConn.on('netUnavailable', () => {
        this._isConnected = false;
        this._connectionType = ConnectionType.NONE;
        this._notifyListeners();
      });

      this._netConn.on('netBlockStatusChange', (data: any) => {
        console.info('[NetworkMonitor] block status:', JSON.stringify(data));
      });
    } catch (err) {
      console.error('[NetworkMonitor] init error:', JSON.stringify(err));
    }
  }

  stop(): void {
    if (this._netConn) {
      this._netConn.unregister(() => {});
      this._netConn = null;
    }
  }

  addListener(listener: (connected: boolean, type: ConnectionType) => void): void {
    this._listeners.push(listener);
  }

  removeListener(listener: (connected: boolean, type: ConnectionType) => void): void {
    const idx = this._listeners.indexOf(listener);
    if (idx >= 0) this._listeners.splice(idx, 1);
  }

  private _updateConnectionType(data: any): void {
    if (data && data.netCapabilities) {
      const caps = data.netCapabilities;
      if (caps.linkUpBandwidth && caps.linkUpBandwidth > 0) {
        // Heuristic: WiFi typically has higher bandwidth
        this._connectionType = caps.linkUpBandwidth > 100 ? ConnectionType.WIFI : ConnectionType.CELLULAR;
      } else {
        this._connectionType = ConnectionType.UNKNOWN;
      }
    }
  }

  private _notifyListeners(): void {
    for (const listener of this._listeners) {
      listener(this._isConnected, this._connectionType);
    }
  }
}
