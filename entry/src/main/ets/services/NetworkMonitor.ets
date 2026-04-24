// NetworkMonitor - Network status monitoring (H8)
import wifi from '@ohos.wifi';

class NetworkMonitor {
  private isConnected: boolean = true;
  private listeners: Array<(connected: boolean) => void> = [];

  isOnline(): boolean {
    try {
      const wifiManager = wifi.getWifiManager();
      this.isConnected = wifiManager.isWifiConnected();
    } catch (e) {
      this.isConnected = false;
    }
    return this.isConnected;
  }

  onChange(callback: (connected: boolean) => void): void {
    this.listeners.push(callback);
  }

  offChange(callback: (connected: boolean) => void): void {
    const idx = this.listeners.indexOf(callback);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }
}

export default new NetworkMonitor();
