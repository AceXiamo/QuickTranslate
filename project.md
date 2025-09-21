很好的想法！双向翻译验证确实是开发者常用的功能。以下是详细的设计文档：

# macOS AI翻译工具设计文档

## 1. 产品概述

### 1.1 产品名称
**QuickTranslate** （建议名称）

### 1.2 核心功能
- 全局快捷键触发翻译
- 智能语言检测与翻译
- 双向翻译验证
- 直接文本替换
- 浮动气泡UI显示

## 2. 功能需求

### 2.1 核心工作流
1. 用户按 `⌘ + A` 全选文本
2. 用户按 `⌘ + Shift + T` 触发翻译
3. 系统检测源语言并翻译到目标语言
4. 显示浮动气泡，包含：
   - 原文
   - 译文
   - 反向翻译（验证用）
5. 用户可选择：
   - 确认替换
   - 取消操作
   - 编辑译文

### 2.2 详细功能清单

#### 2.2.1 翻译功能
- [x] 智能语言检测
- [x] 支持中英文双向翻译
- [x] 可扩展多语言支持
- [x] AI驱动的翻译质量
- [x] 双向验证翻译

#### 2.2.2 用户界面
- [x] 浮动气泡UI
- [x] 实时预览
- [x] 快捷操作按钮
- [x] 键盘导航支持

#### 2.2.3 系统集成
- [x] 全局快捷键
- [x] 辅助功能API集成
- [x] 系统剪贴板交互
- [x] 活动应用检测

## 3. 技术架构

### 3.1 技术栈
- **语言**: Swift 5.9+
- **框架**: SwiftUI + AppKit
- **最低系统**: macOS 13.0+
- **AI服务**: OpenAI GPT / Claude API
- **权限**: 辅助功能权限

### 3.2 项目结构
```
QuickTranslate/
├── App/
│   ├── QuickTranslateApp.swift
│   └── AppDelegate.swift
├── Models/
│   ├── Translation.swift
│   ├── Language.swift
│   └── TranslationRequest.swift
├── Services/
│   ├── TranslationService.swift
│   ├── AccessibilityService.swift
│   ├── HotKeyService.swift
│   └── AIProvider.swift
├── Views/
│   ├── TranslationBubble.swift
│   ├── SettingsView.swift
│   └── StatusBarView.swift
├── Utilities/
│   ├── LanguageDetector.swift
│   └── TextProcessor.swift
└── Resources/
    ├── Localizable.strings
    └── Assets.xcassets
```

## 4. UI/UX 设计

### 4.1 浮动气泡设计

```
┌─────────────────────────────────────┐
│  🔄 英文 → 中文                      │
├─────────────────────────────────────┤
│  原文: Hello world                   │
│  译文: 你好世界                      │
│  验证: Hello world ← 你好世界        │
├─────────────────────────────────────┤
│  [✓ 替换] [✏️ 编辑] [✕ 取消]        │
└─────────────────────────────────────┘
```

### 4.2 交互流程
1. **触发**: `⌘ + Shift + T` 显示气泡
2. **位置**: 跟随鼠标位置或文本框位置
3. **动画**: 淡入淡出，轻微缩放
4. **自动消失**: 10秒无操作自动隐藏
5. **键盘操作**: 
   - `Enter` = 确认替换
   - `Esc` = 取消
   - `E` = 编辑模式

## 5. 核心代码结构

### 5.1 主应用入口
```swift
// QuickTranslateApp.swift
@main
struct QuickTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
```

### 5.2 翻译服务
```swift
// TranslationService.swift
class TranslationService: ObservableObject {
    private let aiProvider: AIProvider
    
    func translateText(_ text: String) async -> TranslationResult {
        // 1. 检测源语言
        // 2. 确定目标语言  
        // 3. 调用AI翻译
        // 4. 执行反向翻译验证
        // 5. 返回结果
    }
}

struct TranslationResult {
    let originalText: String
    let translatedText: String
    let backTranslation: String
    let sourceLanguage: Language
    let targetLanguage: Language
    let confidence: Double
}
```

### 5.3 辅助功能服务
```swift
// AccessibilityService.swift
class AccessibilityService {
    func getSelectedText() -> String? {
        // 使用 AXUIElement 获取选中文本
    }
    
    func replaceSelectedText(with newText: String) {
        // 替换当前焦点元素中的文本
    }
    
    func getCurrentTextElement() -> AXUIElement? {
        // 获取当前聚焦的文本输入元素
    }
}
```

### 5.4 浮动气泡视图
```swift
// TranslationBubble.swift
struct TranslationBubble: View {
    @ObservedObject var translationService: TranslationService
    let result: TranslationResult
    let onReplace: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 语言方向指示
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                Text("\(result.sourceLanguage.name) → \(result.targetLanguage.name)")
            }
            
            // 翻译内容
            VStack(alignment: .leading, spacing: 4) {
                Label(result.originalText, systemImage: "doc.plaintext")
                Label(result.translatedText, systemImage: "doc.badge.arrow.up")
                Label(result.backTranslation, systemImage: "arrow.uturn.left")
            }
            
            // 操作按钮
            HStack {
                Button("替换") { onReplace(result.translatedText) }
                Button("编辑") { /* 进入编辑模式 */ }
                Button("取消") { onCancel() }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}
```

## 6. 权限与安全

### 6.1 必需权限
- **辅助功能权限**: 读取和修改其他应用的文本内容
- **网络权限**: 调用翻译API

### 6.2 隐私保护
- 本地缓存常用翻译
- 可选择本地AI模型
- 不存储用户翻译内容
- 提供数据删除选项

## 7. 开发计划

### Phase 1: 基础功能 (2-3周)
- [x] 项目搭建
- [x] 快捷键监听
- [x] 基础翻译功能
- [x] 简单UI

### Phase 2: 核心体验 (2-3周)
- [x] 浮动气泡UI
- [x] 双向翻译验证
- [x] 文本替换功能
- [x] 语言检测优化

### Phase 3: 完善与优化 (1-2周)
- [x] 设置面板
- [x] 多语言支持
- [x] 性能优化
- [x] 错误处理

### Phase 4: 发布准备 (1周)
- [x] 代码签名
- [x] 应用分发
- [x] 用户文档
- [x] App Store 提交

## 8. 配置建议

### 8.1 默认设置
- 快捷键: `⌘ + Shift + T`
- 默认语言对: 中文 ↔ 英文
- 气泡显示时间: 10秒
- AI服务: OpenAI GPT-4

### 8.2 可配置选项
- 自定义快捷键
- 翻译服务选择
- 界面主题
- 语言对设置



