// TTSClient.ets — 文字转语音客户端（获取音频并播放）
import { http } from '@kit.NetworkKit';
import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';

const TTS_BASE_URL = 'http://localhost:7700';

export interface TTSResult {
  success: boolean;
  error?: string;
}

export class TTSClient {
  private baseURL: string;
  private audioPlayer: media.AVPlayer | null = null;
  private _isPlaying: boolean = false;
  private _onPlayStateChange: ((playing: boolean) => void) | null = null;

  constructor(baseURL?: string) {
    this.baseURL = baseURL || TTS_BASE_URL;
  }

  get isPlaying(): boolean {
    return this._isPlaying;
  }

  onPlayStateChange(callback: (playing: boolean) => void): void {
    this._onPlayStateChange = callback;
  }

  /**
   * 调用 TTS 服务获取音频并播放
   * @param text 要播报的文字
   * @param voice 语音类型（可选）
   * @param callback 回调函数
   */
  speak(text: string, voice: string = 'default', callback?: (result: TTSResult) => void): void {
    console.info('[TTSClient] speak:', text.substring(0, 50));

    const httpRequest = http.createHttp();
    const url = `${this.baseURL}/v1/tts`;

    const body = JSON.stringify({
      text: text,
      voice: voice
    });

    httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: body,
      expectDataType: http.HttpDataType.ARRAY_BUFFER,
      connectTimeout: 10000,
      readTimeout: 30000
    }, (err, data) => {
      if (err) {
        console.error('[TTSClient] request error:', JSON.stringify(err));
        callback?.({ success: false, error: `网络请求失败: ${err.code}` });
        httpRequest.destroy();
        return;
      }

      try {
        // 获取音频数据
        const audioBuffer = data.result as ArrayBuffer;
        if (!audioBuffer || audioBuffer.byteLength === 0) {
          callback?.({ success: false, error: 'TTS 返回空音频数据' });
          httpRequest.destroy();
          return;
        }

        console.info('[TTSClient] received audio, size:', audioBuffer.byteLength);

        // 写入缓存文件并播放
        this._playAudioBuffer(audioBuffer, callback);
      } catch (e) {
        console.error('[TTSClient] error:', JSON.stringify(e));
        callback?.({ success: false, error: '处理音频失败' });
      }

      httpRequest.destroy();
    });
  }

  /**
   * 停止当前播放
   */
  async stop(): Promise<void> {
    if (this.audioPlayer) {
      try {
        await this.audioPlayer.stop();
        await this.audioPlayer.release();
      } catch (e) {
        console.error('[TTSClient] stop error:', JSON.stringify(e));
      }
      this.audioPlayer = null;
      this._isPlaying = false;
      this._onPlayStateChange?.(false);
    }
  }

  private _playAudioBuffer(buffer: ArrayBuffer, callback?: (result: TTSResult) => void): void {
    // 写入临时文件
    const cacheDir = globalThis.context?.cacheDir || '/data/storage/el2/base/cache';
    const tempPath = `${cacheDir}/tts_${Date.now()}.wav`;

    try {
      const file = fileIo.openSync(tempPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);
      fileIo.writeSync(file.fd, buffer);
      fileIo.closeSync(file.fd);

      console.info('[TTSClient] audio saved to:', tempPath);

      // 创建 AVPlayer 播放
      this._createAndPlay(tempPath, callback);
    } catch (e) {
      console.error('[TTSClient] write audio file error:', JSON.stringify(e));
      callback?.({ success: false, error: '写入音频文件失败' });
    }
  }

  private async _createAndPlay(filePath: string, callback?: (result: TTSResult) => void): Promise<void> {
    // 先停止之前的播放
    await this.stop();

    try {
      const player = await media.createAVPlayer();
      this.audioPlayer = player;

      // 状态变化监听
      player.on('stateChange', (state: string, reason: Error) => {
        console.info('[TTSClient] player state:', state);
        switch (state) {
          case 'initialized':
            player.prepare();
            break;
          case 'prepared':
            this._isPlaying = true;
            this._onPlayStateChange?.(true);
            player.play();
            break;
          case 'completed':
          case 'stopped':
            this._isPlaying = false;
            this._onPlayStateChange?.(false);
            player.release();
            this.audioPlayer = null;
            // 清理临时文件
            try { fileIo.unlinkSync(filePath); } catch (_) {}
            callback?.({ success: true });
            break;
          case 'error':
            console.error('[TTSClient] player error:', JSON.stringify(reason));
            this._isPlaying = false;
            this._onPlayStateChange?.(false);
            player.release();
            this.audioPlayer = null;
            try { fileIo.unlinkSync(filePath); } catch (_) {}
            callback?.({ success: false, error: '播放失败' });
            break;
        }
      });

      // 设置播放源 — fdSrc 需要 AVFileDescriptor
      const audioFd = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      player.fdSrc = { fd: audioFd.fd, offset: 0, length: 0 };
    } catch (e) {
      console.error('[TTSClient] create player error:', JSON.stringify(e));
      callback?.({ success: false, error: '创建播放器失败' });
    }
  }
}
