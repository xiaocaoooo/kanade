# 音频播放插件迁移指南

## 概述

本指南将帮助您将原项目中的音频播放功能迁移到新的 `kanade_audio_plugin` 插件中。

## 迁移步骤

### 1. 添加插件依赖

在原项目的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  kanade_audio_plugin:
    path: ../kanade_audio_plugin
```

### 2. 替换导入

将原来的导入：
```dart
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
```

替换为：
```dart
import 'package:kanade_audio_plugin/kanade_audio_plugin.dart';
```

### 3. 更新服务类

使用新的 `AudioPlayerService` 类替换原来的 `AudioPlayerService` 类。新的服务类已经封装了所有必要的功能。

### 4. 更新 Song 模型

确保您的 Song 模型与插件中的 Song 类兼容：

```dart
class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final int duration;
  final int? albumId;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.duration,
    this.albumId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      'duration': duration,
      'albumId': albumId,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as int,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      path: map['path'] as String,
      duration: map['duration'] as int,
      albumId: map['albumId'] as int?,
    );
  }
}
```

### 5. 更新播放控制

使用新的 API：

```dart
// 设置播放列表
await audioPlayerService.setPlaylist(songs, initialIndex: 0);

// 播放控制
await audioPlayerService.play();
await audioPlayerService.pause();
await audioPlayerService.next();
await audioPlayerService.previous();

// 获取专辑封面
final albumArt = await audioPlayerService.getAlbumArt(song);
```

### 6. 监听状态变化

```dart
// 监听播放状态
audioPlayerService.addListener(() {
  // 状态已更新
  final isPlaying = audioPlayerService.isPlaying;
  final currentSong = audioPlayerService.currentSong;
  final position = audioPlayerService.position;
});
```

## 功能对比

| 功能 | 原实现 | 新插件 |
|------|--------|--------|
| 播放控制 | just_audio | ExoPlayer |
| 播放列表管理 | 自定义 | 内置支持 |
| 专辑封面获取 | 自定义 | 内置支持 |
| 播放模式 | 支持 | 支持 |
| 后台播放 | just_audio_background | 需要单独实现 |
| 跨平台 | 部分支持 | Android 专用 |

## 注意事项

1. **后台播放**：新的插件目前专注于 Android 平台，后台播放需要单独实现。
2. **权限**：确保在 AndroidManifest.xml 中声明必要的权限：
   ```xml
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.INTERNET" />
   ```
3. **文件访问**：对于 Android 10+，请使用存储访问框架或适当的权限。

## 测试

运行插件的示例应用：

```bash
cd kanade_audio_plugin/example
flutter run
```

## 故障排除

### 常见问题

1. **专辑封面无法加载**：检查文件路径是否正确，是否有读取权限。
2. **播放失败**：确认音频文件格式受支持，文件路径可访问。
3. **状态不同步**：确保正确监听状态变化事件。

### 调试

启用调试日志：

```dart
// 在 Android 原生代码中设置日志级别
android.util.Log.d("KanadeAudioPlugin", "Debug message");
```

## 后续计划

1. 添加 iOS 支持
2. 实现后台播放
3. 添加音频效果支持
4. 优化内存管理