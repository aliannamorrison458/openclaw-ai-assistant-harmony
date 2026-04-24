// VoiceRecorder - Voice input (H5)
import audio from '@ohos.multimedia.audio';

class VoiceRecorder {
  private audioCapturer: audio.AudioCapturer | null = null;
  private isRecording: boolean = false;

  async startRecording(): Promise<void> {
    const audioCapturer = await audio.createAudioCapturer(audio.AudioStreamSourceType.MIC);
    this.audioCapturer = audioCapturer;
    this.isRecording = true;
    await audioCapturer.start();
  }

  async stopRecording(): Promise<ArrayBuffer> {
    if (this.audioCapturer) {
      this.isRecording = false;
      await this.audioCapturer.stop();
      const buffer = await this.audioCapturer.getBuffer();
      this.audioCapturer.release();
      this.audioCapturer = null;
      return buffer;
    }
    return new ArrayBuffer(0);
  }

  isActive(): boolean {
    return this.isRecording;
  }
}

export default new VoiceRecorder();
