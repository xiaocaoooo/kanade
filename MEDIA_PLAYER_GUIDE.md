# Kanade 媒体播放功能完整指南

## 功能概述

本项目实现了一个功能完整的本地音乐播放器，包含以下核心功能：

### 🎵 音频播放功能
- **播放控制**：播放、暂停、停止、上一首、下一首
- **播放模式**：顺序播放、单曲循环、列表循环、随机播放
- **进度控制**：拖动进度条调整播放位置
- **音量控制**：实时调整播放音量
- **播放列表**：支持完整的播放列表管理

### 🎨 用户界面
- **播放器页面**：全屏播放控制界面
- **迷你播放器**：底部悬浮的播放控制条
- **专辑封面**：支持显示专辑封面图片
- **响应式设计**：适配不同屏幕尺寸

### 📱 媒体通知
- **系统通知**：Android系统级媒体通知
- **锁屏控制**：锁屏界面播放控制
- **后台播放**：支持后台播放和通知栏控制

### 🔧 技术特性
- **状态管理**：使用Provider进行状态管理
- **原生集成**：通过MethodChannel与Android原生代码交互
- **性能优化**：异步加载和缓存优化
- **错误处理**：完善的错误处理和用户反馈

## 文件结构

```
lib/
├── services/
│   ├── audio_player_service.dart    # 音频播放核心服务
│   ├── media_notification_service.dart  # 媒体通知服务
│   └── music_service.dart          # 音乐数据获取服务
├── pages/
│   ├── player_page.dart            # 完整播放器页面
│   └── songs_page.dart            # 歌曲列表页面
├── widgets/
│   └── mini_player.dart           # 迷你播放器小部件
└── models/
    └── song.dart                  # 歌曲数据模型

android/app/src/main/kotlin/
├── MediaServicePlugin.kt          # 原生媒体服务插件
├── MediaNotificationService.kt    # 原生通知服务
└── MediaNotificationReceiver.kt   # 通知事件接收器
```

## 使用方法

### 1. 播放歌曲
在歌曲列表页面点击任意歌曲即可开始播放：

```dart
// 在SongsPage中播放歌曲
void _playSong(Song song) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PlayerPage(
        initialSong: song,
        playlist: _allSongs,
      ),
    ),
  );
}
```

### 2. 使用播放服务
通过AudioPlayerService控制播放：

```dart
// 获取播放服务实例
final playerService = Provider.of<AudioPlayerService>(context);

// 播放歌曲
await playerService.playSong(song);

// 控制播放
await playerService.play();
await playerService.pause();
await playerService.stop();

// 调整进度
await playerService.seek(Duration(seconds: 30));

// 调整音量
await playerService.setVolume(0.5);
```

### 3. 监听播放状态
使用Consumer监听播放状态变化：

```dart
Consumer<AudioPlayerService>(
  builder: (context, player, child) {
    return Column(
      children: [
        Slider(
          value: player.progress,
          onChanged: (value) {
            final newPosition = Duration(
              milliseconds: (value * player.duration.inMilliseconds).toInt(),
            );
            player.seek(newPosition);
          },
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (player.isPlaying) {
                  player.pause();
                } else {
                  player.play();
                }
              },
            ),
          ],
        ),
      ],
    );
  },
)
```

## 播放模式

支持四种播放模式：

1. **顺序播放 (sequence)**：按列表顺序播放，播完最后一首停止
2. **单曲循环 (repeatOne)**：单曲循环播放当前歌曲
3. **列表循环 (repeatAll)**：列表循环播放，播完最后一首回到第一首
4. **随机播放 (shuffle)**：随机播放列表中的歌曲

## 媒体通知

媒体通知功能通过原生Android实现，支持：

- 显示当前播放歌曲信息
- 提供播放/暂停、上一首、下一首控制按钮
- 支持锁屏界面控制
- 后台播放时保持通知

## 权限要求

应用需要以下权限：

```xml
<!-- 读取外部存储权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

## 依赖项

在`pubspec.yaml`中添加以下依赖：

```yaml
dependencies:
  audioplayers: ^6.1.0
  provider: ^6.1.2
```

## 使用示例

### 完整播放器页面
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PlayerPage(
      initialSong: selectedSong,
      playlist: songsList,
    ),
  ),
);
```

### 迷你播放器集成
```dart
// 在主页面底部添加迷你播放器
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const MiniPlayer(),
    NavigationBar(...),
  ],
)
```

## 注意事项

1. **权限处理**：确保在AndroidManifest.xml中声明所有必要权限
2. **文件格式**：支持常见音频格式（MP3, AAC, WAV, FLAC等）
3. **性能优化**：专辑封面图片已进行内存优化
4. **错误处理**：所有播放操作都有完善的错误处理
5. **状态管理**：使用ChangeNotifier确保状态同步更新

## 扩展功能建议

- 添加播放历史记录
- 支持创建和管理播放列表
- 添加均衡器功能
- 支持在线歌词显示
- 添加睡眠定时器
- 支持音频书签
- 添加分享功能

## 测试建议

1. **功能测试**：测试所有播放控制功能
2. **边界测试**：测试空列表、无效文件等边界情况
3. **性能测试**：测试大量歌曲的加载性能
4. **权限测试**：测试各种权限拒绝场景
5. **通知测试**：测试媒体通知的显示和交互

这个媒体播放功能已经实现了完整的本地音乐播放器，具有现代化的UI设计和良好的用户体验。