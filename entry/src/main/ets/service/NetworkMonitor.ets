// NetworkMonitor.ets — 网络状态监测（弱网/离线处理扩展）
import { netConnection } from '@kit.NetworkKit';

export enum ConnectionType {
  NONE = 'none',
  WIFI = 'wifi',
  CELLULAR = 'cellular',
  UNKNOWN = 'unknown'
}

export enum NetworkQuality {
  GOOD = 'good',         // 良好：WiFi 或高速蜂窝
  WEAK = 'weak',         // 弱网：低速蜂窝或高延迟
  OFFLINE = 'offline'    // 离线
}

export class NetworkMonitor {
  private static instance: NetworkMonitor;
  private _isConnected: boolean = true;
  private _connectionType: ConnectionType = ConnectionType.UNKNOWN;
  private _networkQuality: NetworkQuality = NetworkQuality.GOOD;
  private _netConn: any = null;
  private _listeners: Array<(connected: boolean, type: ConnectionType, quality: NetworkQuality) => void> = [];
  private _qualityListeners: Array<(quality: NetworkQuality) => void> = [];

  // 弱网检测参数
  private _lastCheckTime: number = 0;
  private _consecutiveFailures: number = 0;
  private _weakNetworkThreshold: number = 3; // 连续失败次数判定弱网

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

  get networkQuality(): NetworkQuality {
    return this._networkQuality;
  }

  get isWeakNetwork(): boolean {
    return this._networkQuality === NetworkQuality.WEAK;
  }

  get isOffline(): boolean {
    return this._networkQuality === NetworkQuality.OFFLINE;
  }

  get isGoodNetwork(): boolean {
    return this._networkQuality === NetworkQuality.GOOD;
  }

  get statusText(): string {
    if (!this._isConnected) return '离线';
    switch (this._connectionType) {
      case ConnectionType.WIFI:
        return this._networkQuality === NetworkQuality.WEAK ? 'WiFi(弱)' : 'WiFi';
      case ConnectionType.CELLULAR:
        return this._networkQuality === NetworkQuality.WEAK ? '移动数据(弱)' : '移动数据';
      default: return '已连接';
    }
  }

  get qualityText(): string {
    switch (this._networkQuality) {
      case NetworkQuality.GOOD: return '网络良好';
      case NetworkQuality.WEAK: return '网络较弱';
      case NetworkQuality.OFFLINE: return '已离线';
      default: return '未知';
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
        this._updateNetworkQuality(data);
        this._notifyListeners();
      });

      this._netConn.on('netUnavailable', () => {
        this._isConnected = false;
        this._connectionType = ConnectionType.NONE;
        this._networkQuality = NetworkQuality.OFFLINE;
        this._notifyListeners();
      });

      this._netConn.on('netBlockStatusChange', (data: any) => {
        console.info('[NetworkMonitor] block status:', JSON.stringify(data));
        if (data && data.netBlocked) {
          this._networkQuality = NetworkQuality.OFFLINE;
          this._notifyListeners();
        }
      });

      // 弱网定期检测
      this._startQualityCheck();
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

  addListener(listener: (connected: boolean, type: ConnectionType, quality: NetworkQuality) => void): void {
    this._listeners.push(listener);
  }

  removeListener(listener: (connected: boolean, type: ConnectionType, quality: NetworkQuality) => void): void {
    const idx = this._listeners.indexOf(listener);
    if (idx >= 0) this._listeners.splice(idx, 1);
  }

  addQualityListener(listener: (quality: NetworkQuality) => void): void {
    this._qualityListeners.push(listener);
  }

  removeQualityListener(listener: (quality: NetworkQuality) => void): void {
    const idx = this._qualityListeners.indexOf(listener);
    if (idx >= 0) this._qualityListeners.splice(idx, 1);
  }

  /**
   * 手动报告网络请求结果，用于弱网检测
   */
  reportRequestResult(success: boolean): void {
    if (!success) {
      this._consecutiveFailures++;
      if (this._consecutiveFailures >= this._weakNetworkThreshold &&
          this._isConnected &&
          this._networkQuality !== NetworkQuality.WEAK) {
        this._networkQuality = NetworkQuality.WEAK;
        console.warn('[NetworkMonitor] weak network detected, consecutive failures:', this._consecutiveFailures);
        this._notifyListeners();
      }
    } else {
      this._consecutiveFailures = 0;
      if (this._isConnected && this._networkQuality === NetworkQuality.WEAK) {
        this._networkQuality = NetworkQuality.GOOD;
        this._notifyListeners();
      }
    }
  }

  /**
   * 检查语音功能是否可用
   */
  isVoiceAvailable(): { available: boolean; reason: string } {
    if (!this._isConnected) {
      return { available: false, reason: '网络已断开，语音功能暂时不可用' };
    }
    if (this._networkQuality === NetworkQuality.WEAK) {
      return { available: false, reason: '网络信号较弱，语音功能可能不稳定' };
    }
    return { available: true, reason: '' };
  }

  private _updateConnectionType(data: any): void {
    if (data && data.netCapabilities) {
      const caps = data.netCapabilities;
      if (caps.linkUpBandwidth && caps.linkUpBandwidth > 0) {
        this._connectionType = caps.linkUpBandwidth > 100 ? ConnectionType.WIFI : ConnectionType.CELLULAR;
      } else {
        this._connectionType = ConnectionType.UNKNOWN;
      }
    }
  }

  private _updateNetworkQuality(data: any): void {
    if (!this._isConnected) {
      this._networkQuality = NetworkQuality.OFFLINE;
      return;
    }

    if (data && data.netCapabilities) {
      const caps = data.netCapabilities;
      // 低带宽判断为弱网
      if (caps.linkUpBandwidth && caps.linkUpBandwidth < 50) {
        this._networkQuality = NetworkQuality.WEAK;
      } else {
        this._networkQuality = NetworkQuality.GOOD;
      }
    }
  }

  private _startQualityCheck(): void {
    // 每 30 秒检查一次网络质量
    setInterval(() => {
      if (!this._isConnected) return;

      const now = Date.now();
      if (now - this._lastCheckTime < 30000) return;
      this._lastCheckTime = now;

      // 如果连续失败过多，标记为弱网
      if (this._consecutiveFailures >= this._weakNetworkThreshold) {
        if (this._networkQuality !== NetworkQuality.WEAK) {
          this._networkQuality = NetworkQuality.WEAK;
          console.warn('[NetworkMonitor] quality check: weak network');
          this._notifyListeners();
        }
      }
    }, 30000);
  }

  private _notifyListeners(): void {
    for (const listener of this._listeners) {
      listener(this._isConnected, this._connectionType, this._networkQuality);
    }
    for (const listener of this._qualityListeners) {
      listener(this._networkQuality);
    }
  }
}
