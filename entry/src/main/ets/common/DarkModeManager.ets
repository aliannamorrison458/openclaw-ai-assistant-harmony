// DarkModeManager.ets — 深色模式管理器（AppStorage 响应式）
import { AppStorage } from '@kit.ArkUI';

export type DarkModeSetting = 'system' | 'light' | 'dark';

const DARK_MODE_KEY = 'darkModeSetting';

// 初始化 AppStorage 中的值
AppStorage.setOrCreate<DarkModeSetting>(DARK_MODE_KEY, 'system');

// 颜色定义
interface ColorDef { light: string; dark: string }

const COLOR_MAP: Record<string, ColorDef> = {
  color_background: { light: '#FAFAFA', dark: '#1A1A1A' },
  color_surface: { light: '#FFFFFF', dark: '#2D2D2D' },
  color_surface_alt: { light: '#F5F5F5', dark: '#333333' },
  color_surface_elevated: { light: '#F8F9FA', dark: '#2A2A2A' },
  color_text_primary: { light: '#1A1A1A', dark: '#FFFFFF' },
  color_text_secondary: { light: '#666666', dark: '#999999' },
  color_text_tertiary: { light: '#999999', dark: '#777777' },
  color_text_quaternary: { light: '#888888', dark: '#888888' },
  color_text_placeholder: { light: '#BBBBBB', dark: '#666666' },
  color_text_on_accent: { light: '#FFFFFF', dark: '#FFFFFF' },
  color_accent: { light: '#4A90D9', dark: '#5BA0E8' },
  color_accent_dim: { light: '#CCCCCC', dark: '#555555' },
  color_bubble_user: { light: '#4A90D9', dark: '#3A7BC8' },
  color_bubble_user_text: { light: '#FFFFFF', dark: '#FFFFFF' },
  color_bubble_user_time: { light: 'rgba(255,255,255,0.7)', dark: 'rgba(255,255,255,0.7)' },
  color_bubble_assistant: { light: '#F0F0F0', dark: '#3A3A3A' },
  color_bubble_assistant_text: { light: '#1A1A1A', dark: '#E8E8E8' },
  color_bubble_assistant_time: { light: '#999999', dark: '#888888' },
  color_warning: { light: '#FF9800', dark: '#FF9800' },
  color_error: { light: '#F44336', dark: '#EF5350' },
  color_success: { light: '#4CAF50', dark: '#66BB6A' },
  color_warning_bg: { light: '#E3F2FD', dark: '#2D2518' },
  color_error_bg: { light: '#FFF5F5', dark: '#3D2020' },
  color_error_border: { light: '#FFCDD2', dark: '#6B3030' },
  color_shadow: { light: 'rgba(0,0,0,0.08)', dark: 'rgba(0,0,0,0.3)' },
  color_quote_bar: { light: '#4A90D9', dark: '#5BA0E8' },
  color_quote_text: { light: '#888888', dark: '#999999' },
  color_quote_bg: { light: '#F5F5F5', dark: '#2D2D2D' },
  color_menu_bg: { light: '#FFFFFF', dark: '#333333' },
  color_tool_bg: { light: '#F8F8F8', dark: '#2D2D2D' },
  color_tool_error_bg: { light: '#FFF5F5', dark: '#3D2020' },
  color_tool_error_border: { light: '#FFCDD2', dark: '#6B3030' },
  color_tool_border: { light: '#E8E8E8', dark: '#444444' },
  color_tool_params_bg: { light: '#F8F9FA', dark: '#252525' },
  color_tool_key: { light: '#888888', dark: '#999999' },
  color_tool_value: { light: '#333333', dark: '#CCCCCC' },
  color_tool_result_error_label: { light: '#F44336', dark: '#EF5350' },
  color_tool_result_label: { light: '#666666', dark: '#999999' },
  color_md_heading: { light: '#1A1A1A', dark: '#FFFFFF' },
  color_md_text: { light: '#1A1A1A', dark: '#E0E0E0' },
  color_md_bold: { light: '#1A1A1A', dark: '#FFFFFF' },
  color_md_code_bg: { light: '#F6F8FA', dark: '#1E1E1E' },
  color_md_code_border: { light: '#E1E4E8', dark: '#404040' },
  color_md_lang_label: { light: '#666666', dark: '#999999' },
  color_md_inline_code: { light: '#D63384', dark: '#F06292' },
  color_md_inline_code_bg: { light: '#F5F5F5', dark: '#2D2D2D' },
  color_md_link: { light: '#0D6EFD', dark: '#64B5F6' },
  color_code_keyword: { light: '#D73A49', dark: '#FF7B72' },
  color_code_string: { light: '#032F62', dark: '#A5D6FF' },
  color_code_comment: { light: '#6A737D', dark: '#8B949E' },
  color_code_number: { light: '#005CC5', dark: '#79C0FF' },
  color_code_punctuation: { light: '#24292E', dark: '#C9D1D9' },
  color_code_plain: { light: '#24292E', dark: '#C9D1D9' },
  color_divider: { light: '#E0E0E0', dark: '#404040' },
  color_voice_indicator_bg: { light: '#E3F2FD', dark: '#1A2A3D' },
  color_voice_indicator_text: { light: '#4A90D9', dark: '#7BB8E8' },
  color_info: { light: '#4A90D9', dark: '#5BA0E8' },
};

// 判断当前是否为暗色模式
export function isDarkMode(): boolean {
  const setting = AppStorage.get<DarkModeSetting>(DARK_MODE_KEY) || 'system';
  if (setting === 'dark') return true;
  if (setting === 'light') return false;
  // system: 暂时默认 light，后续可通过 window API 检测
  return false;
}

// 根据当前模式获取颜色
export function tc(key: string): string {
  const pair = COLOR_MAP[key];
  if (!pair) return key;
  return isDarkMode() ? pair.dark : pair.light;
}

// 获取/设置深色模式设置
export function getDarkModeSetting(): DarkModeSetting {
  return AppStorage.get<DarkModeSetting>(DARK_MODE_KEY) || 'system';
}

export function setDarkModeSetting(mode: DarkModeSetting): void {
  AppStorage.setOrCreate<DarkModeSetting>(DARK_MODE_KEY, mode);
}
