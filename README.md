# Kanade - 本地音乐播放器

一款优雅的本地音乐播放器Android应用，基于Flutter开发，支持动态色彩主题。

## 功能特性

- **动态色彩主题**: 集成dynamic_color模块，支持Material You动态色彩
- **多维度音乐浏览**: 
  - 按文件夹浏览
  - 按歌手分类
  - 按专辑展示
- **智能搜索**: 支持关键词搜索本地音乐
- **简洁界面**: 采用Material 3设计语言

## 页面结构

### 1. 主页
- 应用欢迎页面
- 简洁的启动界面

### 2. 搜索页面
- 页面标题："搜索"
- 搜索框功能：支持关键词检索本地歌曲
- "搜索全部音乐"按钮：一键搜索所有本地音乐

### 3. 音乐页面
- 音乐分类入口
- 支持跳转至：
  - 文件夹页面：按文件夹维度展示音乐
  - 歌手页面：按艺术家维度展示音乐
  - 专辑页面：按专辑维度展示音乐

### 4. 更多页面
- 设置页面：应用参数配置
- 关于应用页面：展示应用版本、开发者信息

## 技术栈

- **框架**: Flutter
- **语言**: Dart
- **主题**: Material 3 + dynamic_color
- **平台**: Android

## 开发环境要求

- Flutter SDK: ^3.7.2
- Android设备：MIX 3 (mix3:5555)
- 开发工具：Android Studio / VS Code

## 快速开始

1. 克隆项目
```bash
git clone [项目地址]
cd kanade
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

## 项目结构

```
lib/
├── main.dart              # 应用入口
└── pages/
    ├── home_page.dart     # 主页
    ├── search_page.dart   # 搜索页面
    ├── music_page.dart    # 音乐页面
    ├── more_page.dart     # 更多页面
    ├── folder_page.dart   # 文件夹页面
    ├── artist_page.dart   # 歌手页面
    ├── album_page.dart    # 专辑页面
    ├── settings_page.dart # 设置页面
    └── about_page.dart    # 关于页面
```

## 调试说明

开发及测试过程中，需使用设备名称为"mix3"的Android设备：

```bash
adb devices
# 应显示：mix3:5555 device
```

## 开源协议

MIT License

## 开发者信息

- 开发者：Kanade Team
- 版本：1.0.0
- 邮箱：dev@kanade.app
- 官网：https://kanade.app
