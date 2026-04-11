// VoiceServiceManager.ets — 录音→STT→TTS 播放管理器
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { STTServiceClient, STTResult } from './STTServiceClient';
import { TTSClient, TTSResult } from './TTSClient';
import { NetworkMonitor, ConnectionType } from './NetworkMonitor';
import { fileIo } from '@kit.CoreFileKit';

// 语音按钮状态
export enum VoiceState {
  IDLE = 'idle',         // 空闲
  RECORDING = 'recording', // 录音中
  PROCESSING = 'processing', // 处理中（STT/TTS请求中）
  PLAYING = 'playing'     // 播放中
}

// 离线队列缓存项
interface QueuedVoiceTask {
  type: 'stt' | 'tts';
  audioPath?: string;
  audioBuffer?: ArrayBuffer;
  text?: string;
  voice?: string;
  timestamp: number;
}

export class VoiceServiceManager {
  private static instance: VoiceServiceManager;

  private sttClient: STTServiceClient;
  private ttsClient: TTSClient;
  private networkMonitor: NetworkMonitor;

  private _state: VoiceState = VoiceState.IDLE;
  private _isOffline: boolean = false;
  private _isWeakNetwork: boolean = false;

  // 录音相关
  private audioCapturer: audio.AudioCapturer | null = null;
  private recordingPath: string = '';
  private recordingChunks: ArrayBuffer[] = [];
  private _isRecording: boolean = false;

  // 离线队列
  private offlineQueue: QueuedVoiceTask[] = [];

  // 回调
  private _onStateChange: ((state: VoiceState) => void) | null = null;
  private _onSTTResult: ((text: string) => void) | null = null;
  private _onError: ((error: string) => void) | null = null;
  private _onOfflineWarning: ((message: string) => void) | null = null;

  private constructor() {
    this.sttClient = new STTServiceClient();
    this.ttsClient = new TTSClient();
    this.networkMonitor = NetworkMonitor.getInstance();

    // 监听网络状态
    this.networkMonitor.addListener((connected: boolean, type: ConnectionType) => {
      const wasOffline = this._isOffline;
      this._isOffline = !connected;
      this._isWeakNetwork = connected && type === ConnectionType.CELLULAR;

      if (!connected) {
        this._onOfflineWarning?.('⚠️ 网络已断开，语音功能暂时不可用');
        // 停止录音和播放
        this.stopAll();
      } else if (wasOffline) {
        // 网络恢复，处理队列
        this._processOfflineQueue();
      }
    });

    // TTS 播放状态监听
    this.ttsClient.onPlayStateChange((playing: boolean) => {
      if (!playing && this._state === VoiceState.PLAYING) {
        this._setState(VoiceState.IDLE);
      }
    });
  }

  static getInstance(): VoiceServiceManager {
    if (!VoiceServiceManager.instance) {
      VoiceServiceManager.instance = new VoiceServiceManager();
    }
    return VoiceServiceManager.instance;
  }

  get state(): VoiceState {
    return this._state;
  }

  get isOffline(): boolean {
    return this._isOffline;
  }

  get isWeakNetwork(): boolean {
    return this._isWeakNetwork;
  }

  get isRecording(): boolean {
    return this._isRecording;
  }

  get isPlaying(): boolean {
    return this._state === VoiceState.PLAYING;
  }

  get isProcessing(): boolean {
    return this._state === VoiceState.PROCESSING;
  }

  get queueLength(): number {
    return this.offlineQueue.length;
  }

  // 注册回调
  onStateChange(callback: (state: VoiceState) => void): void {
    this._onStateChange = callback;
  }

  onSTTResult(callback: (text: string) => void): void {
    this._onSTTResult = callback;
  }

  onError(callback: (error: string) => void): void {
    this._onError = callback;
  }

  onOfflineWarning(callback: (message: string) => void): void {
    this._onOfflineWarning = callback;
  }

  /**
   * 开始录音
   */
  async startRecording(): Promise<void> {
    if (this._isOffline) {
      this._onError?.('网络已断开，无法使用语音功能');
      return;
    }

    if (this._state !== VoiceState.IDLE) {
      console.warn('[VoiceServiceManager] not idle, current state:', this._state);
      return;
    }

    try {
      // 获取音频管理器
      const audioManager = audio.getAudioManager();
      const audioCapturerOptions: audio.AudioCapturerOptions = {
        streamInfo: {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        capturerInfo: {
          source: audio.SourceType.SOURCE_TYPE_MIC,
          capturerFlags: 0
        }
      };

      this.audioCapturer = await audio.createAudioCapturer(audioCapturerOptions);
      this.recordingChunks = [];

      // 设置录音路径
      const cacheDir = globalThis.context?.cacheDir || '/data/storage/el2/base/cache';
      this.recordingPath = `${cacheDir}/recording_${Date.now()}.pcm`;

      // 监听录音数据
      this.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
        if (this._isRecording) {
          this.recordingChunks.push(buffer);
        }
      });

      // 开始录音
      await this.audioCapturer.start();
      this._isRecording = true;
      this._setState(VoiceState.RECORDING);

      console.info('[VoiceServiceManager] recording started');
    } catch (err) {
      console.error('[VoiceServiceManager] startRecording error:', JSON.stringify(err));
      this._onError?.('启动录音失败，请检查麦克风权限');
      this._setState(VoiceState.IDLE);
    }
  }

  /**
   * 停止录音并开始 STT 识别
   */
  async stopRecordingAndTranscribe(): Promise<void> {
    if (!this._isRecording || !this.audioCapturer) {
      return;
    }

    this._setState(VoiceState.PROCESSING);

    try {
      // 停止录音
      await this.audioCapturer.stop();
      this._isRecording = false;

      // 合并录音数据
      const totalLength = this.recordingChunks.reduce((sum, chunk) => sum + chunk.byteLength, 0);
      const combinedBuffer = new ArrayBuffer(totalLength);
      const combinedView = new Uint8Array(combinedBuffer);
      let offset = 0;
      for (const chunk of this.recordingChunks) {
        combinedView.set(new Uint8Array(chunk), offset);
        offset += chunk.byteLength;
      }

      // 释放录音器
      await this.audioCapturer.release();
      this.audioCapturer = null;

      if (totalLength === 0) {
        this._onError?.('录音数据为空');
        this._setState(VoiceState.IDLE);
        return;
      }

      console.info('[VoiceServiceManager] recording stopped, size:', totalLength);

      // 发送到 STT 服务
      if (this._isOffline) {
        // 离线时加入队列
        this._addToOfflineQueue({
          type: 'stt',
          audioBuffer: combinedBuffer,
          timestamp: Date.now()
        });
        this._onOfflineWarning?.('⚠️ 已离线，语音将稍后处理');
        this._setState(VoiceState.IDLE);
      } else {
        this.sttClient.uploadAudioBuffer(combinedBuffer, (result: STTResult) => {
          if (result.success && result.text) {
            this._onSTTResult?.(result.text);
          } else {
            this._onError?.(result.error || '语音识别失败');
          }
          this._setState(VoiceState.IDLE);
        });
      }
    } catch (err) {
      console.error('[VoiceServiceManager] stopRecording error:', JSON.stringify(err));
      this._onError?.('停止录音失败');
      this._setState(VoiceState.IDLE);
      this.audioCapturer = null;
    }
  }

  /**
   * 取消录音
   */
  async cancelRecording(): Promise<void> {
    if (!this._isRecording || !this.audioCapturer) {
      return;
    }

    try {
      await this.audioCapturer.stop();
      await this.audioCapturer.release();
    } catch (e) {
      console.error('[VoiceServiceManager] cancelRecording error:', JSON.stringify(e));
    }

    this.audioCapturer = null;
    this._isRecording = false;
    this.recordingChunks = [];
    this._setState(VoiceState.IDLE);
  }

  /**
   * TTS 播报文字
   */
  speak(text: string, voice: string = 'default'): void {
    if (!text.trim()) return;

    if (this._isOffline) {
      // 离线时加入队列
      this._addToOfflineQueue({
        type: 'tts',
        text: text,
        voice: voice,
        timestamp: Date.now()
      });
      this._onOfflineWarning?.('⚠️ 已离线，语音播报将稍后执行');
      return;
    }

    if (this._state === VoiceState.PLAYING) {
      this.ttsClient.stop().then(() => {
        this._doSpeak(text, voice);
      });
    } else if (this._state === VoiceState.IDLE) {
      this._doSpeak(text, voice);
    }
  }

  /**
   * 停止当前播放
   */
  async stopSpeaking(): Promise<void> {
    if (this._state === VoiceState.PLAYING) {
      await this.ttsClient.stop();
      this._setState(VoiceState.IDLE);
    }
  }

  /**
   * 停止所有活动
   */
  async stopAll(): Promise<void> {
    if (this._isRecording) {
      await this.cancelRecording();
    }
    if (this._state === VoiceState.PLAYING) {
      await this.ttsClient.stop();
    }
    this._setState(VoiceState.IDLE);
  }

  private _doSpeak(text: string, voice: string): void {
    this._setState(VoiceState.PROCESSING);

    this.ttsClient.speak(text, voice, (result: TTSResult) => {
      if (!result.success) {
        this._onError?.(result.error || '语音播报失败');
        this._setState(VoiceState.IDLE);
      }
      // 播放完成由 onPlayStateChange 回调处理
    });

    // 进入播放状态（实际由 TTSClient 的回调驱动）
    // 这里暂不设置 PLAYING，等 TTSClient 回调
  }

  private _setState(state: VoiceState): void {
    this._state = state;
    this._onStateChange?.(state);
  }

  // 离线队列管理
  private _addToOfflineQueue(task: QueuedVoiceTask): void {
    this.offlineQueue.push(task);
    console.info('[VoiceServiceManager] queued task, queue length:', this.offlineQueue.length);
  }

  private async _processOfflineQueue(): Promise<void> {
    if (this.offlineQueue.length === 0) return;

    console.info('[VoiceServiceManager] processing offline queue, length:', this.offlineQueue.length);

    const queue = [...this.offlineQueue];
    this.offlineQueue = [];

    for (const task of queue) {
      if (task.type === 'stt' && task.audioBuffer) {
        this._setState(VoiceState.PROCESSING);
        await new Promise<void>((resolve) => {
          this.sttClient.uploadAudioBuffer(task.audioBuffer!, (result: STTResult) => {
            if (result.success && result.text) {
              this._onSTTResult?.(result.text);
            } else {
              this._onError?.(result.error || '离线队列语音识别失败');
            }
            resolve();
          });
        });
        this._setState(VoiceState.IDLE);
      } else if (task.type === 'tts' && task.text) {
        await new Promise<void>((resolve) => {
          this.speak(task.text!, task.voice);
          // 等待播放完成或超时
          const checkInterval = setInterval(() => {
            if (this._state === VoiceState.IDLE) {
              clearInterval(checkInterval);
              resolve();
            }
          }, 500);
          // 超时 30 秒
          setTimeout(() => {
            clearInterval(checkInterval);
            resolve();
          }, 30000);
        });
      }
    }

    console.info('[VoiceServiceManager] offline queue processed');
  }
}
