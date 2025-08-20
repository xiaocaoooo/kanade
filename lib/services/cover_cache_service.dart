import 'dart:typed_data';

/// 全局封面缓存管理器
/// 使用单例模式确保整个应用中只有一个缓存实例
class CoverCacheManager {
  static final CoverCacheManager _instance = CoverCacheManager._internal();
  
  /// 获取全局单例实例
  factory CoverCacheManager() => _instance;
  
  /// 全局访问点
  static CoverCacheManager get instance => _instance;
  
  CoverCacheManager._internal();

  final Map<String, Uint8List> _cache = {};
  final Map<String, bool> _loading = {};

  /// 获取封面数据
  Uint8List? getCover(String albumId) {
    return _cache[albumId];
  }

  /// 检查是否正在加载
  bool isLoading(String albumId) {
    return _loading[albumId] ?? false;
  }

  /// 设置封面数据
  void setCover(String albumId, Uint8List? cover) {
    if (cover != null) {
      _cache[albumId] = cover;
    }
    _loading[albumId] = false;
  }

  /// 标记为加载中
  void markAsLoading(String albumId) {
    _loading[albumId] = true;
  }

  /// 标记为加载完成（兼容旧代码）
  void markLoaded(String albumId) {
    _loading[albumId] = false;
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
    _loading.clear();
  }

  /// 获取缓存大小
  int get cacheSize => _cache.length;

  /// 检查是否包含指定专辑封面
  bool contains(String albumId) {
    return _cache.containsKey(albumId);
  }
}