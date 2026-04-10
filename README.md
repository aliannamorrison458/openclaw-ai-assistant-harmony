# AI 助手 — HarmonyOS NEXT 版

端侧优先、语音友好的个人 AI 助手，HarmonyOS NEXT 原生实现。

## 功能清单（对齐 iOS/Android）

| 功能 | 状态 | 说明 |
|------|------|------|
| 文字对话 | ✅ | 流式输出 + 消息持久化 |
| 语音输入 | 📋 TODO | ASR 转文字 |
| 语音播报 | 📋 TODO | TTS 播报 |
| 离线降级 | ✅ | 断网自动切本地 mock |
| 消息状态 | ✅ | 发送中/已发送/失败 + 重试 |
| 引用回复 | ✅ | 长按消息引用 |
| 长按菜单 | ✅ | 复制/删除/重试 |
| 设置页 | ✅ | API 配置 + 模拟模式切换 |
| 网络检测 | ✅ | 实时监测 + 状态条 |
| 深色模式 | 📋 TODO | |
| 会话管理 | 📋 TODO | |

## 构建要求

- DevEco Studio 5.x+
- HarmonyOS NEXT SDK API 12+
- ohpm 6.x

## 环境变量

```bash
export DEVECO_STUDIO="/Applications/DevEco-Studio.app"
export DEVECO_SDK_HOME="$HOME/Library/Huawei/Sdk"
export PATH="$DEVECO_STUDIO/Contents/tools/ohpm/bin:$PATH"
export PATH="$DEVECO_STUDIO/Contents/sdk/default/openharmony/toolchains:$PATH"
```

## 构建

```bash
cd openclaw-ai-assistant-harmony
ohpm install
hvigorw assembleHap
```

## 调试

```bash
# 连接设备
hdc list targets
# 安装
hdc install entry/build/default/outputs/default/entry-default-signed.hap
# 启动
hdc shell aa start -a EntryAbility -b ai.openclaw.assistant
```
