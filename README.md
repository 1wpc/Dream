# 白日做梦

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge" alt="MIT License">
</div>

<div align="center">
  <h3>✨ 一个优雅的梦境记录与AI解析应用 ✨</h3>
  <p>记录您的梦境，用AI生成梦境场景，并与社区分享您的奇妙体验</p>
</div>

---

## 📖 项目简介

梦境记录器是一款基于Flutter开发的移动应用，旨在帮助用户记录、分析和分享他们的梦境体验。应用集成了AI技术，可以根据梦境描述生成相应的视觉场景，并提供专业的梦境解析服务。

## ✨ 核心功能

### 🌙 梦境管理
- **梦境记录**: 详细记录梦境内容、时间和情感
- **梦境编辑**: 随时修改和完善梦境描述
- **智能分类**: 自动识别梦境类型和主题
- **本地存储**: 安全的本地数据库存储

### 🎨 AI梦境生成
- **场景生成**: 根据梦境描述生成对应的视觉场景
- **多场景支持**: 为单个梦境生成多个不同场景
- **高质量图像**: 基于先进AI模型生成高分辨率图像
- **场景导航**: 便捷的场景切换和浏览功能

### 🧠 AI梦境解析
- **深度分析**: 使用DeepSeek AI进行专业梦境解析
- **流式输出**: 实时显示解析过程，提升用户体验
- **Markdown渲染**: 支持丰富文本格式，增强阅读体验
- **心理洞察**: 提供梦境的象征意义和心理暗示
- **个性化建议**: 基于梦境内容给出生活建议

### 🎵 沉浸式体验
- **背景音乐**: 内置舒缓音乐，营造梦幻氛围
- **音频控制**: 便捷的播放/暂停控制
- **全屏查看**: 长按图像进入全屏模式
- **手势交互**: 支持缩放、拖拽等手势操作

### 🌐 社区分享
- **快速分享**: 一键将梦境分享到社区
- **匿名模式**: 保护隐私的匿名分享选项
- **社区互动**: 与其他用户交流梦境体验

## 🛠 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart
- **数据库**: SQLite (sqflite)
- **AI服务**: 
  - DeepSeek API (梦境解析)
  - 即梦API (梦境场景生成)
- **音频**: audioplayers
- **网络**: http, dio
- **图像处理**: extended_image, cached_network_image
- **视频播放**: video_player
- **文本渲染**: flutter_markdown (支持Markdown格式)
- **状态管理**: setState (原生状态管理)
- **UI组件**: Material Design 3
- **动画**: animated_text_kit
- **环境配置**: envied
- **其他**: path_provider, image_picker, intl

## 📱 系统要求

- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **开发环境**: Flutter SDK 3.0+

## 🚀 安装与运行

### 环境准备

1. 安装 Flutter SDK
```bash
# 请参考官方文档安装Flutter
https://flutter.dev/docs/get-started/install
```

2. 验证Flutter环境
```bash
flutter doctor
```

### 项目设置

1. 克隆项目
```bash
git clone <repository-url>
cd dream
```

2. 安装依赖
```bash
flutter pub get
```

3. 配置API密钥
```bash
# 在项目根目录创建 .env 文件
# 添加必要的API密钥配置
DEEPSEEK_API_KEY=your_deepseek_api_key
JIMENG_SC_KEY=your_jimeng_sc_key
DREAM_API_BASE_URL=your_dream_api_base_url
```

4. 构建环境配置
```bash
# 添加环境变量代码生成依赖
dart pub add envied dev:envied_generator dev:build_runner

# 生成环境配置文件
dart run build_runner build
```

5. 准备音频资源
```bash
# 确保 assets/audio/ 目录下有背景音乐文件
# 默认音频文件: dream_music.mp3
```

6. 启用Markdown渲染 (可选)
```bash
# Markdown依赖已在pubspec.yaml中配置
# 如需启用完整Markdown功能，请：
# 1. 取消注释 lib/pages/dream_detail_page_enhanced.dart 中的导入
# 2. 将 _buildMarkdownText() 函数替换为 MarkdownBody 组件
```

### 运行应用

```bash
# 开发模式运行
flutter run

# 构建APK
flutter build apk

# 构建iOS应用
flutter build ios
```

## 📁 项目结构

```
lib/
├── main.dart                   # 应用入口
├── pages/                      # 页面文件
│   ├── daydream_page.dart     # 梦境生成页面
│   ├── dream_record_page.dart # 梦境记录列表
│   ├── dream_detail_page_enhanced.dart # 梦境详情页面
│   └── edit_dream_page.dart   # 梦境编辑页面
├── services/                   # 服务层
│   ├── database_service.dart  # 数据库服务
│   ├── deepseek_service.dart  # AI解析服务
│   └── dream_api_service.dart # 梦境API服务
├── models/                     # 数据模型
└── widgets/                    # 公共组件

assets/
├── audio/                      # 音频资源
│   └── dream_music.mp3
├── videos/                     # 视频资源
│   └── background.mp4
└── images/                     # 图片资源
    └── dream_background.jpg
```

## 🔧 API接口说明

### DeepSeek AI服务
```dart
// 梦境解析 - 支持Markdown格式输出
DeepSeekService.interpretDreamStream(title, content)

// 返回Stream<String>，支持流式输出
// AI输出格式：
// **🔮 梦境概述**
// **💭 心理寓意**
// **🌟 象征解读**
// **💡 生活启示**
// **🌸 积极寄语**
```

### 梦境生成API
```dart
// 生成梦境场景
DreamApiService.generateDreamScene(prompt)

// 快速分享梦境
DreamApiService.quickShareDream(dreamRecord, authorNickname)
```

## 🎨 UI特性

### 设计理念
- **现代化设计**: Material Design 3规范
- **流畅动画**: 自然的过渡效果和交互反馈
- **响应式布局**: 适配不同屏幕尺寸
- **深色友好**: 支持深色模式

### 核心组件
- **梦境卡片**: 渐变背景 + 圆角设计
- **全屏图片查看器**: 手势控制 + 动画过渡
- **流式文本显示**: 打字机效果 + 实时更新
- **音乐控制器**: 美观的播放状态指示

## 🤝 贡献指南

我们欢迎任何形式的贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

### 开发规范
- 遵循Dart代码规范
- 添加必要的注释和文档
- 确保代码通过所有测试
- 保持UI设计一致性

## 🐛 问题反馈

如果您遇到任何问题或有功能建议，请：

1. 查看 [Issues](../../issues) 是否已有相关问题
2. 如果没有，请创建新的Issue
3. 详细描述问题或建议
4. 提供相关的错误日志或截图

## 📝 更新日志

### v1.0.0 (当前版本)
- ✅ 基础梦境记录功能
- ✅ AI梦境场景生成
- ✅ AI梦境解析（流式输出）
- ✅ 音频播放控制
- ✅ 全屏图片查看
- ✅ 社区分享功能
- ✅ 现代化UI设计

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 优秀的跨平台框架
- [DeepSeek](https://www.deepseek.com/) - AI解析服务支持
- [Material Design](https://material.io/) - 设计规范指导

## 📄 许可协议

本项目基于 [MIT License](LICENSE) 开源协议。

---

<div align="center">
  <p>如果这个项目对您有帮助，请给个 ⭐ Star 支持一下！</p>
  <p>Made with ❤️ by Dream Team</p>
</div>
