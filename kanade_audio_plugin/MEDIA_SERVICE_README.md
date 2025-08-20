# 媒体服务功能说明

## 概述

媒体服务功能已从原始的 `MediaServicePlugin.kt` 迁移到 `kanade_audio_plugin` 模块中，现在作为插件的一部分提供设备媒体库访问功能。

## 新增功能

### 1. 获取所有歌曲
```dart
// 获取设备中所有歌曲
final songs = await KanadeAudioPlugin().getAllSongs();
```

### 2. 获取专辑封面
```dart
// 根据专辑ID获取专辑封面
final albumArt = await KanadeAudioPlugin().getAlbumArt(albumId);
```

## 使用示例

### 基本使用

```dart
import 'package:kanade_audio_plugin/kanade_audio_plugin.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final KanadeAudioPlugin _audioPlugin = KanadeAudioPlugin();
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _audioPlugin.getAllSongs();
      setState(() {
        _songs = songs;
      });
    } catch (e) {
      print('加载歌曲失败: $e');
    }
  }

  Future<void> _loadAlbumArt(int albumId) async {
    try {
      final albumArt = await _audioPlugin.getAlbumArt(albumId);
      if (albumArt != null) {
        // 显示专辑封面
        // ...
      }
    } catch (e) {
      print('加载专辑封面失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return ListTile(
          title: Text(song.title),
          subtitle: Text('${song.artist} - ${song.album}'),
          trailing: Text('${_formatDuration(song.duration)}'),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
```

## 权限要求

在AndroidManifest.xml中添加以下权限：

```xml
<!-- 读取外部存储权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Android 13及以上版本的媒体权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

## 测试

运行示例应用：

```bash
cd kanade_audio_plugin/example
flutter run
```

在示例应用中，点击右上角的"媒体服务测试"按钮即可进入媒体服务功能测试页面。

## 迁移说明

- 原始的 `MediaServicePlugin.kt` 已被删除
- 功能已集成到 `kanade_audio_plugin` 模块中
- 所有媒体相关功能现在通过 `KanadeAudioPlugin` 类统一提供
- 保持向后兼容性，无需修改现有代码

## 注意事项

1. 确保在Android 13及以上版本正确申请权限
2. 处理可能的异常和错误情况
3. 专辑封面加载可能需要一些时间，建议异步处理
4. 大量歌曲加载时可能需要分页处理