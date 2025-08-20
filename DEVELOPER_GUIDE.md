# Kanade 开发者指南

## 项目概述

Kanade是一个功能完整的本地音乐播放器，基于Flutter开发，专为Android平台优化。项目采用现代化的架构设计，支持最新的Android特性和音频播放技术。

## 技术栈

### 核心框架
- **Flutter**: 跨平台UI框架
- **Dart**: 编程语言
- **just_audio**: 音频播放引擎
- **just_audio_background**: 后台播放支持

### 状态管理
- **Provider**: 状态管理库
- **ChangeNotifier**: 状态通知机制
- **全局单例模式**: 确保服务一致性

### 数据存储
- **SharedPreferences**: 本地设置存储
- **JSON**: 数据序列化格式
- **文件系统**: 音频文件和缓存管理

## 项目架构

### 分层架构
```
┌─────────────────────────────────────────┐
│                UI层                      │
│  pages/  widgets/  utils/               │
├─────────────────────────────────────────┤
│              业务逻辑层                  │
│  services/  models/                    │
├─────────────────────────────────────────┤
│              数据访问层                  │
│  文件系统  SharedPreferences           │
└─────────────────────────────────────────┘
```

### 核心服务

#### AudioPlayerService
- **位置**: `lib/services/audio_player_service_new.dart`
- **功能**: 音频播放核心控制
- **模式**: 全局单例
- **状态**: 通过ChangeNotifier广播

#### MusicService
- **位置**: `lib/services/music_service.dart`
- **功能**: 音乐文件扫描和管理
- **依赖**: 文件系统访问、权限管理

#### SettingsService
- **位置**: `lib/services/settings_service.dart`
- **功能**: 用户设置管理
- **存储**: SharedPreferences

#### CoverCacheService
- **位置**: `lib/services/cover_cache_service.dart`
- **功能**: 专辑封面缓存管理
- **模式**: 全局单例

## 开发环境设置

### 前置要求
```bash
# Flutter版本
flutter --version  # 需要3.16.0+

# Dart版本
dart --version     # 需要3.2.0+

# Android SDK
# 需要API 21+ (Android 5.0)
```

### 环境配置
```bash
# 1. 克隆项目
git clone [项目地址]
cd kanade

# 2. 安装依赖
flutter pub get

# 3. 检查环境
flutter doctor

# 4. 运行测试
flutter test

# 5. 启动应用
flutter run
```

## 代码规范

### 命名规范
- **文件名**: 小写下划线命名 `example_file.dart`
- **类名**: 大驼峰命名 `ExampleClass`
- **变量名**: 小驼峰命名 `exampleVariable`
- **常量名**: 大写下划线命名 `EXAMPLE_CONSTANT`

### 代码风格
```dart
// 正确的导入顺序
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanade/services/audio_player_service.dart';

// 类注释
/// 音频播放服务的核心实现
/// 提供播放控制、状态管理等功能
class AudioPlayerService extends ChangeNotifier {
  // 代码实现
}
```

### 提交规范
```
type(scope): description

feat(audio): 添加新的播放模式
fix(ui): 修复播放器页面布局问题
docs(readme): 更新安装说明
style: 格式化代码
refactor(service): 重构音频服务架构
test: 添加音频播放测试
```

## 模块开发指南

### 添加新页面

1. **创建页面文件**
```dart
// lib/pages/new_page.dart
import 'package:flutter/material.dart';

class NewPage extends StatelessWidget {
  const NewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新页面')),
      body: const Center(child: Text('新页面内容')),
    );
  }
}
```

2. **添加路由**
```dart
// 在相关导航中添加页面跳转
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const NewPage()),
);
```

3. **更新主页面**
```dart
// 在home_page.dart中添加导航项
ListTile(
  title: const Text('新功能'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewPage()),
    );
  },
)
```

### 添加新服务

1. **创建服务类**
```dart
// lib/services/new_service.dart
import 'package:flutter/foundation.dart';

class NewService extends ChangeNotifier {
  static final NewService _instance = NewService._internal();
  factory NewService() => _instance;
  NewService._internal();

  // 服务实现
}
```

2. **注册服务**
```dart
// lib/main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
        ChangeNotifierProvider(create: (_) => NewService()),
      ],
      child: const KanadeApp(),
    ),
  );
}
```

### 添加新功能

以添加"收藏歌曲"功能为例：

1. **数据模型扩展**
```dart
// lib/models/song.dart
class Song {
  final int id;
  final String title;
  final bool isFavorite; // 新增字段
  
  Song({
    required this.id,
    required this.title,
    this.isFavorite = false,
  });
}
```

2. **服务层实现**
```dart
// lib/services/favorites_service.dart
class FavoritesService extends ChangeNotifier {
  final List<int> _favoriteIds = [];
  
  List<Song> getFavoriteSongs(List<Song> allSongs) {
    return allSongs.where((song) => _favoriteIds.contains(song.id)).toList();
  }
  
  void toggleFavorite(int songId) {
    if (_favoriteIds.contains(songId)) {
      _favoriteIds.remove(songId);
    } else {
      _favoriteIds.add(songId);
    }
    notifyListeners();
  }
}
```

3. **UI层集成**
```dart
// 在歌曲列表中添加收藏按钮
IconButton(
  icon: Icon(
    song.isFavorite ? Icons.favorite : Icons.favorite_border,
    color: song.isFavorite ? Colors.red : null,
  ),
  onPressed: () {
    context.read<FavoritesService>().toggleFavorite(song.id);
  },
)
```

## 调试指南

### 调试工具
```bash
# 调试命令
flutter run --debug
flutter attach

# 性能分析
flutter run --profile
flutter build apk --profile

# 内存分析
flutter run --profile --trace-systrace
```

### 日志调试
```dart
// 添加调试日志
import 'dart:developer' as developer;

developer.log('调试信息', name: 'AudioPlayerService');
developer.log('错误信息', error: error, stackTrace: stackTrace);

// 使用print调试
print('简单调试信息');
debugPrint('详细调试信息');
```

### 性能优化

#### 列表优化
```dart
// 使用ListView.builder优化长列表
ListView.builder(
  itemCount: songs.length,
  itemBuilder: (context, index) {
    return SongItem(song: songs[index]);
  },
)

// 添加key优化重绘
SongItem(
  key: ValueKey(song.id),
  song: song,
)
```

#### 图片优化
```dart
// 缓存网络图片
CachedNetworkImage(
  imageUrl: albumArtUrl,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.music_note),
  memCacheWidth: 200,
  memCacheHeight: 200,
)
```

## 测试指南

### 单元测试
```dart
// test/audio_player_service_test.dart
void main() {
  group('AudioPlayerService', () {
    late AudioPlayerService service;
    
    setUp(() {
      service = AudioPlayerService();
    });
    
    test('播放状态管理', () async {
      expect(service.isPlaying, false);
      await service.play();
      expect(service.isPlaying, true);
    });
  });
}
```

### 集成测试
```dart
// integration_test/app_test.dart
void main() {
  testWidgets('完整播放流程', (WidgetTester tester) async {
    await tester.pumpWidget(const KanadeApp());
    
    // 等待应用加载
    await tester.pumpAndSettle();
    
    // 点击第一首歌
    await tester.tap(find.byType(SongItem).first);
    await tester.pumpAndSettle();
    
    // 验证播放页面打开
    expect(find.byType(PlayerPage), findsOneWidget);
  });
}
```

## 发布指南

### 版本发布
```bash
# 1. 更新版本号
# 修改pubspec.yaml中的version字段

# 2. 创建发布分支
git checkout -b release/v2.0.0

# 3. 更新文档
# 更新CHANGELOG.md
# 更新README.md

# 4. 运行测试
flutter test
flutter analyze

# 5. 构建发布版本
flutter build apk --release
flutter build appbundle --release

# 6. 提交发布
git tag v2.0.0
git push origin v2.0.0
```

### 应用签名
```bash
# 生成密钥
keytool -genkey -v -keystore kanade-release-key.keystore -alias kanade -keyalg RSA -keysize 2048 -validity 10000

# 配置签名
# 在android/app/build.gradle中添加签名配置
```

## 常见问题

### Q: 音频播放不流畅？
A: 检查以下几点：
- 确认音频文件格式支持
- 检查设备存储空间
- 查看是否有其他应用占用音频焦点
- 检查网络连接（如果涉及在线功能）

### Q: 后台播放不稳定？
A: 确保：
- 授予所有必要的权限
- 检查电池优化设置
- 确认通知权限已开启
- 查看系统日志获取错误信息

### Q: 编译失败？
A: 尝试以下解决方案：
- 运行`flutter clean`和`flutter pub get`
- 检查Flutter和Dart版本
- 更新所有依赖到最新版本
- 查看详细的错误日志

## 资源链接

- [Flutter官方文档](https://flutter.dev/docs)
- [just_audio文档](https://pub.dev/packages/just_audio)
- [Provider文档](https://pub.dev/packages/provider)
- [Material Design指南](https://material.io/design)
- [Android音频开发指南](https://developer.android.com/guide/topics/media-apps)

## 联系支持

如有问题或建议，请通过以下方式联系：
- GitHub Issues: [创建Issue](https://github.com/kanade-team/kanade/issues)
- 邮件联系: dev@kanade.app
- 技术讨论: [加入Discord](https://discord.gg/kanade)