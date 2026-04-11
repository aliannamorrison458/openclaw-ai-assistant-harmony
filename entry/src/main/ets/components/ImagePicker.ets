// ImagePicker.ets — 图片选择器组件（从相册选择图片）
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

export interface ImagePickResult {
  imageData: string;   // base64 encoded
  imageUri: string;    // file path
}

export class ImagePickerHelper {
  // 从相册选择图片并返回 base64 + 文件路径
  static async pickImage(context: common.UIAbilityContext): Promise<ImagePickResult | null> {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETYPE.IMAGE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);

      if (!result || !result.photoUris || result.photoUris.length === 0) {
        return null;
      }

      const uri = result.photoUris[0];
      // Read file as ArrayBuffer then convert to base64
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const arrayBuffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, arrayBuffer);
      fileIo.closeSync(file.fd);

      // Convert ArrayBuffer to base64
      const uint8Array = new Uint8Array(arrayBuffer);
      const imageData = ImagePickerHelper.arrayBufferToBase64(uint8Array);

      return {
        imageData: imageData,
        imageUri: uri
      };
    } catch (err) {
      console.error('[ImagePicker] pickImage error:', JSON.stringify(err));
      return null;
    }
  }

  // 从文件路径读取图片并转 base64
  static async loadBase64FromUri(uri: string): Promise<string> {
    try {
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const arrayBuffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, arrayBuffer);
      fileIo.closeSync(file.fd);

      const uint8Array = new Uint8Array(arrayBuffer);
      return ImagePickerHelper.arrayBufferToBase64(uint8Array);
    } catch (err) {
      console.error('[ImagePicker] loadBase64 error:', JSON.stringify(err));
      return '';
    }
  }

  // 将图片保存到相册
  static async saveToAlbum(context: common.UIAbilityContext, base64Data: string, displayName: string = 'image'): Promise<boolean> {
    try {
      const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
      if (!uri) return false;

      // Decode base64 to ArrayBuffer and write to file
      const uint8Array = ImagePickerHelper.base64ToArrayBuffer(base64Data);
      const file = fileIo.openSync(uri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);
      fileIo.writeSync(file.fd, uint8Array.buffer);
      fileIo.closeSync(file.fd);

      return true;
    } catch (err) {
      console.error('[ImagePicker] saveToAlbum error:', JSON.stringify(err));
      return false;
    }
  }

  // ArrayBuffer → base64 (分块处理避免栈溢出)
  private static arrayBufferToBase64(uint8Array: Uint8Array): string {
    let binary = '';
    const chunkSize = 8192;
    for (let i = 0; i < uint8Array.length; i += chunkSize) {
      const chunk = uint8Array.subarray(i, Math.min(i + chunkSize, uint8Array.length));
      for (let j = 0; j < chunk.length; j++) {
        binary += String.fromCharCode(chunk[j]);
      }
    }
    return btoa(binary);
  }

  // base64 → ArrayBuffer
  private static base64ToArrayBuffer(base64: string): Uint8Array {
    const binary = atob(base64);
    const uint8Array = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      uint8Array[i] = binary.charCodeAt(i);
    }
    return uint8Array;
  }
}
