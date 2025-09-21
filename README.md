# QuickTranslate

一个功能强大的 macOS AI翻译工具，支持全局快捷键和双向翻译验证。

## 主要功能

- 🚀 **全局快捷键翻译** - 按 `⌘ + Shift + T` 即可翻译选中文本
- 🤖 **AI 智能翻译** - 支持 OpenAI 兼容 API（如 OpenRouter）
- 🔄 **双向翻译验证** - 自动反向翻译确保准确性
- 💬 **浮动气泡界面** - 优雅的翻译结果展示
- 🌍 **多语言支持** - 支持中英日韩法德西意葡俄等10种语言
- ⚡ **文本直接替换** - 可直接替换原文，无需复制粘贴

## 安装使用

### 1. 运行应用
双击 `QuickTranslate.app` 启动应用。应用将在菜单栏显示翻译图标。

### 2. 配置 AI 设置
- 点击菜单栏图标打开设置
- 配置 AI 设置：
  - **AI Endpoint**: `https://api.openai.com/v1` 或其他兼容服务
  - **API Key**: 你的 API 密钥
  - **Model**: `gpt-3.5-turbo` 或其他模型
- 点击"测试连接"确认配置正确

### 3. 授权辅助功能权限
- 前往 **系统偏好设置** → **安全性与隐私** → **隐私** → **辅助功能**
- 点击锁图标解锁设置
- 点击 `+` 添加 QuickTranslate 应用
- 确保开关已开启

### 4. 开始翻译
1. 在任意应用中选中要翻译的文本
2. 按 `⌘ + Shift + T` 快捷键
3. 在弹出的气泡中查看翻译结果
4. 选择操作：
   - **替换** - 直接替换原文
   - **编辑** - 修改译文后替换
   - **取消** - 取消操作

## 技术特性

- **系统要求**: macOS 13.0+
- **架构**: Apple Silicon (ARM64) 和 Intel (x86_64) 兼容
- **框架**: Swift 5.9+ / SwiftUI + AppKit
- **AI 兼容**: 支持 OpenAI API 格式
- **安全**: 沙盒应用，数据不会被存储或上传

## 支持的语言

- 中文 (Chinese)
- English
- 日本語 (Japanese)
- 한국어 (Korean)
- Français (French)
- Deutsch (German)
- Español (Spanish)
- Italiano (Italian)
- Português (Portuguese)
- Русский (Russian)

## 推荐 AI 服务

### OpenAI
- Endpoint: `https://api.openai.com/v1`
- 推荐模型: `gpt-3.5-turbo`, `gpt-4`

### OpenRouter
- Endpoint: `https://openrouter.ai/api/v1`
- 支持多种开源模型，更便宜的选择

### 其他兼容服务
任何支持 OpenAI Chat Completions API 格式的服务都可以使用。

## 常见问题

**Q: 为什么快捷键不工作？**
A: 请确保已授权辅助功能权限，并在设置中开启了快捷键功能。

**Q: 翻译质量不好怎么办？**
A: 可以尝试更换更强大的 AI 模型，或调整 API 设置。

**Q: 支持离线翻译吗？**
A: 目前需要网络连接调用 AI API，暂不支持离线翻译。

## 开发信息

- **开发语言**: Swift
- **UI 框架**: SwiftUI
- **最低系统**: macOS 13.0
- **编译环境**: Xcode 15.0+

## 许可证

本项目仅供学习和个人使用。