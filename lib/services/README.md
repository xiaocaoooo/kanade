# 服务层文档

## CoverCacheManager 全局缓存管理器

### 使用方式

现在CoverCacheManager已经改为全局单例模式，可以通过以下方式使用：

```dart
// 导入服务
import 'package:kanade/services/cover_cache_service.dart';

// 使用全局实例
final cover = CoverCacheManager.instance.getCover(albumId);
CoverCacheManager.instance.setCover(albumId, coverData);

// 或者使用传统的工厂构造函数（效果相同）
final coverManager = CoverCacheManager();
final cover = coverManager.getCover(albumId);
```

### 全局访问点

- `CoverCacheManager.instance` - 推荐的全局访问方式
- `CoverCacheManager()` - 传统的工厂构造函数，返回同一个实例

### 主要功能

- `getCover(String albumId)` - 获取专辑封面
- `setCover(String albumId, Uint8List? cover)` - 设置专辑封面
- `isLoading(String albumId)` - 检查是否正在加载
- `clearCache()` - 清除所有缓存
- `cacheSize` - 获取当前缓存大小
- `contains(String albumId)` - 检查是否包含指定专辑封面