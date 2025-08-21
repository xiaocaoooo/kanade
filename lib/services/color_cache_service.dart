import 'package:flutter/material.dart';

/// 全局颜色缓存服务
/// 用于存储歌曲ID对应的封面颜色，避免重复提取
class ColorCacheService {
  static final ColorCacheService _instance = ColorCacheService._internal();
  factory ColorCacheService() => _instance;
  ColorCacheService._internal();

  static ColorCacheService get instance => _instance;

  /// 存储歌曲ID到颜色列表的映射
  final Map<String, List<Color>> _colorCache = {};

  /// 存储歌曲ID到缓存时间的映射（用于过期检测）
  final Map<String, DateTime> _cacheTime = {};

  /// 默认缓存有效期（24小时）
  static const Duration _cacheValidity = Duration(hours: 24);

  /// 获取缓存的颜色
  List<Color>? getColors(String songId) {
    if (!_colorCache.containsKey(songId)) {
      return null;
    }

    // 检查缓存是否过期
    final cacheTime = _cacheTime[songId];
    if (cacheTime != null &&
        DateTime.now().difference(cacheTime) > _cacheValidity) {
      // 缓存过期，移除缓存
      _colorCache.remove(songId);
      _cacheTime.remove(songId);
      return null;
    }

    return _colorCache[songId];
  }

  /// 缓存颜色
  void cacheColors(String songId, List<Color> colors) {
    _colorCache[songId] = List.from(colors);
    _cacheTime[songId] = DateTime.now();
  }

  /// 清除特定歌曲的缓存
  void clearCacheForSong(String songId) {
    _colorCache.remove(songId);
    _cacheTime.remove(songId);
  }

  /// 清除所有缓存
  void clearAllCache() {
    _colorCache.clear();
    _cacheTime.clear();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_songs': _colorCache.length,
      'total_colors': _colorCache.values.fold<int>(
        0,
        (sum, colors) => sum + colors.length,
      ),
      'oldest_cache':
          _cacheTime.values.isEmpty
              ? null
              : _cacheTime.values.reduce((a, b) => a.isBefore(b) ? a : b),
    };
  }

  /// 检查歌曲是否已缓存
  bool isCached(String songId) {
    return _colorCache.containsKey(songId) &&
        _cacheTime.containsKey(songId) &&
        DateTime.now().difference(_cacheTime[songId]!) <= _cacheValidity;
  }
}
