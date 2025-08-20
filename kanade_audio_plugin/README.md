# Kanade Audio Plugin

一个专为 Android 平台设计的 Flutter 音频播放插件，基于 ExoPlayer 实现。

## 功能特性

- 🎵 完整的音频播放控制（播放/暂停/停止/上一首/下一首）
- 📱 播放列表管理
- 🎨 专辑封面获取
- 🔄 多种播放模式（顺序/单曲循环/列表循环/随机播放）
- 🔊 音量控制
- 📊 实时播放进度和状态监听
- 🎯 精准的时间控制

## 安装

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  kanade_audio_plugin:
    path: ../kanade_audio_plugin
```

## 快速开始

```dart
import 'package:kanade_audio_plugin/kanade_audio_plugin.dart';

final audioPlugin = KanadeAudioPlugin();

// 初始化
await audioPlugin.initialize();

// 创建播放列表
final songs = [
  Song(
    id: 1,
    title: '示例歌曲',
    artist: '艺术家',
    album: '专辑',
    path: '/path/to/audio.mp3',
    duration: 180000,
  ),
];

// 设置播放列表并开始播放
await audioPlugin.setPlaylist(songs, initialIndex: 0);
await audioPlugin.play();
```

## 完整 API

查看 [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) 获取详细的迁移指南和完整 API 文档。

## 运行示例

```bash
cd kanade_audio_plugin/example
flutter run
```

## 许可证

MIT License

