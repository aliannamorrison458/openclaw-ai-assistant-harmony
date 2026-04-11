// STTServiceClient.ets — 语音转文字客户端（上传音频获取文字）
import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

const STT_BASE_URL = 'http://localhost:7700';

export interface STTResult {
  success: boolean;
  text: string;
  error?: string;
}

export class STTServiceClient {
  private baseURL: string;

  constructor(baseURL?: string) {
    this.baseURL = baseURL || STT_BASE_URL;
  }

  /**
   * 上传音频文件到 STT 服务，返回识别文字
   * @param audioPath 音频文件路径（rawFile 或 cache 路径）
   * @param callback 回调函数
   */
  transcribe(audioPath: string, callback: (result: STTResult) => void): void {
    console.info('[STTServiceClient] transcribe:', audioPath);

    // 读取音频文件为 ArrayBuffer
    fileIo.open(audioPath, fileIo.OpenMode.READ_ONLY).then((file) => {
      const stat = fileIo.statSync(file.fd);
      const fileSize = stat.size;
      const arrayBuffer = new ArrayBuffer(fileSize);
      fileIo.readSync(file.fd, arrayBuffer);
      fileIo.closeSync(file.fd);

      this._uploadAudio(arrayBuffer, callback);
    }).catch((err: Error) => {
      console.error('[STTServiceClient] read file error:', JSON.stringify(err));
      callback({ success: false, text: '', error: '读取音频文件失败' });
    });
  }

  /**
   * 上传音频 ArrayBuffer
   */
  uploadAudioBuffer(buffer: ArrayBuffer, callback: (result: STTResult) => void): void {
    this._uploadAudio(buffer, callback);
  }

  private _uploadAudio(audioBuffer: ArrayBuffer, callback: (result: STTResult) => void): void {
    const httpRequest = http.createHttp();
    const url = `${this.baseURL}/v1/stt`;

    // 构建 multipart/form-data boundary
    const boundary = '----HarmonyOSBoundary' + Date.now();
    const filename = 'recording.pcm';

    // 构建 multipart body
    const bodyParts: ArrayBuffer[] = [];

    // 文件头
    const headerStr = `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${filename}"\r\nContent-Type: audio/pcm\r\n\r\n`;
    bodyParts.push(this._stringToArrayBuffer(headerStr));

    // 音频数据
    bodyParts.push(audioBuffer);

    // 文件尾
    const footerStr = `\r\n--${boundary}--\r\n`;
    bodyParts.push(this._stringToArrayBuffer(footerStr));

    // 合并所有部分
    const totalLength = bodyParts.reduce((sum, part) => sum + part.byteLength, 0);
    const combinedBuffer = new ArrayBuffer(totalLength);
    const combinedView = new Uint8Array(combinedBuffer);
    let offset = 0;
    for (const part of bodyParts) {
      combinedView.set(new Uint8Array(part), offset);
      offset += part.byteLength;
    }

    console.info('[STTServiceClient] uploading audio, size:', totalLength);

    httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': `multipart/form-data; boundary=${boundary}`
      },
      extraData: combinedBuffer,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 10000,
      readTimeout: 30000
    }, (err, data) => {
      if (err) {
        console.error('[STTServiceClient] request error:', JSON.stringify(err));
        callback({ success: false, text: '', error: `网络请求失败: ${err.code}` });
        httpRequest.destroy();
        return;
      }

      try {
        const result = JSON.parse(data.result as string);
        if (result.text) {
          callback({ success: true, text: result.text });
        } else if (result.error) {
          callback({ success: false, text: '', error: result.error });
        } else {
          callback({ success: false, text: '', error: '未知响应格式' });
        }
      } catch (e) {
        console.error('[STTServiceClient] parse error:', JSON.stringify(e));
        callback({ success: false, text: '', error: '解析响应失败' });
      }

      httpRequest.destroy();
    });
  }

  private _stringToArrayBuffer(str: string): ArrayBuffer {
    const encoder = new util.TextEncoder();
    const uint8Array: Uint8Array = encoder.encode(str);
    return uint8Array.buffer as ArrayBuffer;
  }
}
