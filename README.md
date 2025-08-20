# Kanade - 本地音乐播放器

一款功能完整的本地音乐播放器Android应用，基于Flutter开发，支持现代音频播放技术和Material You动态主题。

## 🎵 功能特性

### 核心播放功能
- **高质量音频播放**: 基于just_audio引擎，支持多种音频格式
- **后台播放**: 集成just_audio_background，支持后台播放和通知控制
- **播放控制**: 播放/暂停、上一首/下一首、进度调节、音量控制
- **播放模式**: 顺序播放、随机播放、单曲循环
- **播放队列**: 完整的播放列表管理

### 音乐管理
- **多维度浏览**: 
  - 📁 按文件夹浏览音乐文件
  - 👨‍🎤 按艺术家分类查看
  - 💽 按专辑组织音乐
  - 🎵 全部歌曲列表
- **智能搜索**: 支持按歌曲名、艺术家、专辑搜索
- **封面显示**: 自动加载和缓存专辑封面
- **详细信息**: 显示歌曲详细信息（比特率、采样率等）

### 用户体验
- **Material You主题**: 支持Android 12+动态色彩主题
- **响应式设计**: 适配不同屏幕尺寸
- **流畅动画**: 优雅的页面切换和交互动画
- **深色模式**: 完整的深色主题支持

## 🏗️ 技术架构

### 核心组件
- **音频引擎**: just_audio + just_audio_background
- **状态管理**: Provider模式
- **本地存储**: SharedPreferences
- **权限管理**: 完整的存储权限处理
- **缓存系统**: 专辑封面和元数据缓存

### 项目结构
```
lib/
├── main.dart                    # 应用入口
├── models/
│   └── song.dart               # 歌曲数据模型
├── services/
│   ├── audio_player_service.dart    # 音频播放服务
   ├── music_service.dart            # 音乐扫描服务
   ├── cover_cache_service.dart      # 封面缓存服务
   └── permission_helper.dart        # 权限管理
├── pages/
│   ├── home_page.dart          # 主页框架
│   ├── music_page.dart         # 音乐浏览入口
│   ├── search_page.dart        # 搜索页面
│   ├── player_page.dart        # 播放器页面
│   ├── folder_page.dart        # 文件夹浏览
│   ├── artist_page.dart        # 艺术家页面
│   ├── album_page.dart         # 专辑页面
│   ├── songs_page.dart         # 全部歌曲
│   ├── settings_page.dart      # 设置页面
│   └── about_page.dart         # 关于页面
└── widgets/
    ├── song_item.dart          # 歌曲列表项
    └── mini_player.dart        # 迷你播放器
```

## 🚀 快速开始

### 环境要求
- Flutter SDK: ^3.10.0
- Dart SDK: ^3.0.0
- Android: API 21+ (Android 5.0)

### 安装运行
```bash
# 克隆项目
git clone [项目地址]
cd kanade

# 安装依赖
flutter pub get

# 运行应用
flutter run

# 构建发布版本
flutter build apk --release
```

### 开发调试
```bash
# 检查连接的设备
flutter devices

# 运行指定设备
flutter run -d [设备ID]

# 调试模式
flutter run --debug
```

## 🎯 使用指南

### 首次使用
1. 授予存储权限以扫描本地音乐
2. 应用会自动扫描设备中的音乐文件
3. 在对应分类中浏览和播放音乐

### 播放控制
- **点击歌曲**: 直接播放并跳转到播放器
- **长按歌曲**: 显示操作菜单
- **播放器页面**: 完整的播放控制和信息显示

### 搜索功能
- 支持按歌曲名、艺术家、专辑名搜索
- 实时显示搜索结果
- 点击结果直接播放

## 🔧 技术栈

### 核心依赖
- **just_audio**: ^0.9.34 - 音频播放引擎
- **just_audio_background**: ^0.0.1-beta.11 - 后台播放支持
- **provider**: ^6.0.5 - 状态管理
- **dynamic_color**: ^1.6.5 - Material You动态主题
- **permission_handler**: ^10.4.3 - 权限管理
- **path_provider**: ^2.1.1 - 文件路径管理
- **shared_preferences**: ^2.2.1 - 本地存储

### 开发依赖
- **flutter_lints**: ^2.0.2 - 代码规范
- **flutter_test**: SDK内置 - 测试框架

## 📱 设备支持

### 测试设备
- **主要测试**: Xiaomi MIX 3 (Android 10)
- **兼容性测试**: 多种Android设备 (API 21-33)

### 系统要求
- **最低版本**: Android 5.0 (API 21)
- **推荐版本**: Android 8.0+ (API 26+)
- **架构支持**: armeabi-v7a, arm64-v8a, x86, x86_64

## 📝 开发说明

### 代码规范
- 遵循Flutter官方代码规范
- 使用dart format格式化代码
- 所有公共方法添加文档注释

### 调试技巧
- 使用Flutter Inspector查看UI结构
- 通过日志查看音频播放状态
- 利用断点调试播放逻辑

## 🤝 贡献指南

欢迎提交Issue和Pull Request！在贡献代码前，请确保：

1. 遵循项目的代码规范
2. 添加适当的测试
3. 更新相关文档

## 📄 开源协议

本项目采用MIT开源协议，详见[LICENSE](LICENSE)文件。

## 👥 开发团队

- **主要开发者**: Kanade Team
- **贡献者**: 欢迎所有贡献者
- **联系方式**: dev@kanade.app
- **项目地址**: [GitHub仓库地址]

## 📊 版本历史

### v1.0.0 (当前版本)
- ✨ 完整的音频播放功能
- 🎨 Material You动态主题
- 🔍 智能音乐搜索
- 📁 多维度音乐浏览
- 🎵 后台播放支持

---

**享受音乐，享受生活！** 🎶
