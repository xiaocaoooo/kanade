# just_audio_background 集成指南

## 概述
本项目已成功集成 `just_audio_background` 包，实现了完整的后台音频播放功能。

## 集成步骤

### 1. 添加依赖
在 `pubspec.yaml` 中添加：
```yaml
just_audio_background: ^0.0.1-beta.11
```

### 2. 初始化
在 `main.dart` 中初始化 just_audio_background：
```dart
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const KanadeApp());
}
```

### 3. 权限配置
确保 `AndroidManifest.xml` 包含以下权限：
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

### 4. 使用 ConcatenatingAudioSource
为了支持后台播放队列，使用 `ConcatenatingAudioSource`：

```dart
final playlist = ConcatenatingAudioSource(
  children: songs.map((song) => AudioSource.uri(
    Uri.file(song.path),
    tag: MediaItem(
      id: song.id.toString(),
      album: song.album ?? 'Unknown Album',
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      artUri: song.albumArt != null 
          ? Uri.dataFromBytes(song.albumArt!, mimeType: 'image/jpeg')
          : null,
    ),
  )).toList(),
);
```

### 5. 功能特性

#### ✅ 已实现功能
- 后台音频播放
- 通知栏控制（播放/暂停/上一首/下一首）
- 锁屏控制
- 播放队列管理
- 专辑封面显示
- 播放进度同步
- 播放模式支持（顺序、循环、随机）

#### ✅ 播放控制
- 播放/暂停
- 上一首/下一首
- 进度调整
- 音量控制
- 播放模式切换

#### ✅ 通知功能
- 显示当前播放歌曲信息
- 显示专辑封面
- 提供播放控制按钮
- 支持锁屏显示

## 使用示例

### 设置播放列表
```dart
final audioService = AudioPlayerService();
await audioService.setPlaylist(songs, initialIndex: 0);
```

### 播放指定歌曲
```dart
await audioService.playSong(song);
```

### 后台播放测试
1. 启动应用
2. 播放任意歌曲
3. 按返回键回到桌面
4. 验证音频是否继续播放
5. 检查通知栏是否有播放控制
6. 锁屏后验证是否有播放控制

## 注意事项

1. **权限要求**：确保在 Android 10+ 上请求必要的权限
2. **通知图标**：可以自定义通知栏图标
3. **音频格式**：支持常见音频格式（MP3, AAC, FLAC等）
4. **性能优化**：大播放列表建议使用分页加载

## 常见问题

### Q: 后台播放不工作？
A: 检查以下几点：
- 确认权限已授予
- 确认通知通道已正确设置
- 检查日志是否有错误信息

### Q: 通知栏不显示？
A: 确保：
- MediaItem 信息完整
- 专辑封面图片大小适中
- 通知权限已开启

### Q: 锁屏控制无效？
A: 检查：
- 系统锁屏权限
- 媒体会话配置
- Android 版本兼容性

## 技术实现

### 架构设计
- 使用 `AudioPlayer` 作为主播放器
- 通过 `ConcatenatingAudioSource` 管理播放队列
- 使用 `MediaItem` 提供媒体元数据
- 利用 `just_audio_background` 处理后台播放逻辑

### 状态管理
- 全局单例模式确保播放连续性
- ChangeNotifier 提供状态更新
- Stream 监听实现实时同步

## 后续优化

- [ ] 支持自定义通知样式
- [ ] 添加播放历史记录
- [ ] 支持播放速度调节
- [ ] 添加音频均衡器
- [ ] 支持蓝牙耳机控制
