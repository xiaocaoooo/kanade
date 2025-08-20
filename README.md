# Kanade - 本地音乐播放器

一款功能完整的本地音乐播放器Android应用，基于Flutter开发，支持现代音频播放技术和Material You动态主题。

## 🎵 功能特性

### 核心播放功能
- **高质量音频播放**: 基于just_audio引擎，支持多种音频格式
- **后台播放**: 集成just_audio_background，支持后台播放和通知控制
- **播放控制**: 播放/暂停、上一首/下一首、进度调节、音量控制
- **播放模式**: 顺序播放、随机播放、单曲循环、列表循环
- **播放队列**: 完整的播放列表管理
- **音频焦点**: 智能处理音频焦点变化（来电暂停、耳机插拔等）

### 音乐管理
- **多维度浏览**: 
  - 📁 按文件夹浏览音乐文件
  - 👨‍🎤 按艺术家分类查看
  - 💽 按专辑组织音乐
  - 🎵 全部歌曲列表
- **智能搜索**: 支持按歌曲名、艺术家、专辑搜索
- **封面显示**: 自动加载和缓存专辑封面
- **详细信息**: 显示歌曲详细信息（比特率、采样率、文件大小等）
- **文件夹白名单**: 支持选择性扫描指定文件夹

### 用户体验
- **Material You主题**: 支持Android 12+动态色彩主题
- **响应式设计**: 适配不同屏幕尺寸
- **流畅动画**: 优雅的页面切换和交互动画
- **深色模式**: 完整的深色主题支持
- **迷你播放器**: 底部悬浮播放控制条
- **手势操作**: 支持滑动手势切换歌曲

## 🏗️ 技术架构

### 核心组件
- **音频引擎**: just_audio + just_audio_background
- **状态管理**: Provider模式（全局单例模式）
- **本地存储**: SharedPreferences
- **权限管理**: 完整的存储权限处理
- **缓存系统**: 专辑封面和元数据缓存
- **原生集成**: MethodChannel与Android原生代码交互

### 项目结构
```
lib/
├── main.dart                    # 应用入口
├── models/
│   └── song.dart               # 歌曲数据模型
├── services/
│   ├── audio_player_service.dart      # 音频播放核心服务
│   ├── audio_player_service_new.dart  # 新版音频播放服务
│   ├── background_audio_service.dart  # 后台音频服务
│   ├── cover_cache_service.dart       # 专辑封面缓存服务
│   ├── media_notification_service.dart # 媒体通知服务
│   ├── music_service.dart              # 音乐扫描服务
│   ├── settings_service.dart         # 设置管理服务
│   └── services.dart                 # 服务聚合导出
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
│   ├── folder_whitelist_page.dart  # 文件夹白名单设置
│   └── about_page.dart         # 关于页面
├── widgets/
│   ├── song_item.dart          # 歌曲列表项
│   └── mini_player.dart        # 迷你播放器
└── utils/
    └── permission_helper.dart    # 权限管理工具
```

## 🚀 快速开始

### 环境要求
- Flutter SDK: ^3.16.0
- Dart SDK: ^3.2.0
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

# 构建App Bundle
flutter build appbundle --release
```

### 开发调试
```bash
# 检查连接的设备
flutter devices

# 运行指定设备
flutter run -d [设备ID]

# 调试模式
flutter run --debug

# 性能分析
flutter run --profile
```

## 🎯 使用指南

### 首次使用
1. 授予存储权限以扫描本地音乐
2. 应用会自动扫描设备中的音乐文件
3. 在设置中配置文件夹白名单（可选）
4. 在对应分类中浏览和播放音乐

### 播放控制
- **点击歌曲**: 直接播放并跳转到播放器
- **长按歌曲**: 显示操作菜单
- **播放器页面**: 完整的播放控制和信息显示
- **迷你播放器**: 底部快速控制当前播放
- **手势操作**: 左右滑动切换上一首/下一首

### 搜索功能
- 支持按歌曲名、艺术家、专辑名搜索
- 实时显示搜索结果
- 点击结果直接播放

### 文件夹白名单
1. 进入设置 → 文件夹白名单
2. 选择要扫描的音乐文件夹
3. 保存设置后重新扫描音乐库
4. 只扫描白名单中的文件夹，提高扫描效率

## 🔧 技术栈

### 核心依赖
- **just_audio**: ^0.9.38 - 音频播放引擎
- **just_audio_background**: ^0.0.1-beta.11 - 后台播放支持
- **provider**: ^6.1.2 - 状态管理
- **dynamic_color**: ^1.6.8 - Material You动态主题
- **permission_handler**: ^11.1.0 - 权限管理
- **path_provider**: ^2.1.2 - 文件路径管理
- **shared_preferences**: ^2.2.2 - 本地存储
- **path**: ^1.8.3 - 路径处理

### 开发依赖
- **flutter_lints**: ^3.0.1 - 代码规范
- **flutter_test**: SDK内置 - 测试框架

## 📱 设备支持

### 测试设备
- **主要测试**: Xiaomi MIX 3 (Android 10)
- **兼容性测试**: 多种Android设备 (API 21-34)
- **性能测试**: 低端到高端设备全覆盖

### 系统要求
- **最低版本**: Android 5.0 (API 21)
- **推荐版本**: Android 8.0+ (API 26+)
- **架构支持**: armeabi-v7a, arm64-v8a, x86, x86_64

## 📝 开发说明

### 代码规范
- 遵循Flutter官方代码规范
- 使用dart format格式化代码
- 所有公共方法添加文档注释
- 使用dart analyze检查代码质量

### 调试技巧
- 使用Flutter Inspector查看UI结构
- 通过日志查看音频播放状态
- 利用断点调试播放逻辑
- 使用Flutter DevTools进行性能分析

### 架构设计
- **单例模式**: 音频服务、缓存管理使用全局单例
- **状态管理**: Provider模式确保状态一致性
- **错误处理**: 完善的错误处理和用户反馈
- **性能优化**: 异步操作和缓存策略

## 🔄 近期更新

### v2.0.0 (当前版本)
- ✨ 集成just_audio_background完整后台播放
- 🎨 优化Material You动态主题支持
- 🔍 增强搜索功能和性能
- 📁 新增文件夹白名单功能
- 🎵 改进音频焦点处理
- 🔧 优化播放队列管理
- 📱 适配Android 14新特性

### v1.1.0
- 🚀 从audioplayers迁移到just_audio
- 🎵 添加迷你播放器功能
- 🔍 优化音乐扫描性能
- 📱 改进响应式设计

### v1.0.0
- ✨ 基础音频播放功能
- 🎨 Material You主题支持
- 🔍 智能音乐搜索
- 📁 多维度音乐浏览

## 🤝 贡献指南

欢迎提交Issue和Pull Request！在贡献代码前，请确保：

1. 遵循项目的代码规范
2. 添加适当的测试
3. 更新相关文档
4. 通过所有CI检查

### 开发流程
1. Fork项目到个人账户
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开Pull Request

## 📄 开源协议

本项目采用MIT开源协议，详见[LICENSE](LICENSE)文件。

## 📚 相关文档

- [JUST_AUDIO_BACKGROUND集成指南](JUST_AUDIO_BACKGROUND_INTEGRATION.md)
- [后台音频播放修复说明](BACKGROUND_AUDIO_FIX.md)
- [文件夹白名单功能指南](FOLDER_WHITELIST_GUIDE.md)
- [从AudioPlayers迁移到JustAudio](JUST_AUDIO_MIGRATION.md)
- [媒体播放功能完整指南](MEDIA_PLAYER_GUIDE.md)

## 👥 开发团队

- **主要开发者**: Kanade Team
- **贡献者**: 欢迎所有贡献者
- **联系方式**: dev@kanade.app
- **项目地址**: [GitHub仓库地址]

## 📊 版本历史

| 版本 | 发布日期 | 主要特性 |
|------|----------|----------|
| v2.0.0 | 2024-01 | 完整后台播放支持 |
| v1.1.0 | 2023-12 | 迁移到just_audio |
| v1.0.0 | 2023-11 | 基础播放功能 |

---

**享受音乐，享受生活！** 🎶
