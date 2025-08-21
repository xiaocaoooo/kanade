import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/color_cache_service.dart';

void main() {
  group('ColorCacheService Tests', () {
    late ColorCacheService colorCache;

    setUp(() {
      colorCache = ColorCacheService();
      colorCache.clearAllCache(); // 清理缓存
    });

    test('缓存和获取颜色', () {
      const songId = 'test_song_123';
      final colors = [Colors.red, Colors.blue, Colors.green];

      // 初始应该返回null
      expect(colorCache.getColors(songId), isNull);

      // 缓存颜色
      colorCache.cacheColors(songId, colors);

      // 应该能获取到缓存的颜色
      final cachedColors = colorCache.getColors(songId);
      expect(cachedColors, isNotNull);
      expect(cachedColors!.length, equals(3));
      expect(cachedColors[0], equals(Colors.red));
      expect(cachedColors[1], equals(Colors.blue));
      expect(cachedColors[2], equals(Colors.green));
    });

    test('检查缓存状态', () {
      const songId = 'test_song_456';
      final colors = [Colors.yellow, Colors.orange];

      // 初始应该未缓存
      expect(colorCache.isCached(songId), isFalse);

      // 缓存颜色
      colorCache.cacheColors(songId, colors);

      // 应该已缓存
      expect(colorCache.isCached(songId), isTrue);
    });

    test('清除特定缓存', () {
      const songId = 'test_song_789';
      final colors = [Colors.purple, Colors.pink];

      // 缓存颜色
      colorCache.cacheColors(songId, colors);
      expect(colorCache.isCached(songId), isTrue);

      // 清除缓存
      colorCache.clearCacheForSong(songId);
      expect(colorCache.isCached(songId), isFalse);
      expect(colorCache.getColors(songId), isNull);
    });

    test('清除所有缓存', () {
      // 缓存多个歌曲
      colorCache.cacheColors('song1', [Colors.red]);
      colorCache.cacheColors('song2', [Colors.blue]);
      colorCache.cacheColors('song3', [Colors.green]);

      // 验证都有缓存
      expect(colorCache.isCached('song1'), isTrue);
      expect(colorCache.isCached('song2'), isTrue);
      expect(colorCache.isCached('song3'), isTrue);

      // 清除所有缓存
      colorCache.clearAllCache();

      // 验证全部清除
      expect(colorCache.isCached('song1'), isFalse);
      expect(colorCache.isCached('song2'), isFalse);
      expect(colorCache.isCached('song3'), isFalse);
    });

    test('获取缓存统计', () {
      // 初始统计
      final initialStats = colorCache.getCacheStats();
      expect(initialStats['cached_songs'], equals(0));
      expect(initialStats['total_colors'], equals(0));

      // 缓存颜色
      colorCache.cacheColors('song1', [Colors.red, Colors.blue]);
      colorCache.cacheColors('song2', [Colors.green, Colors.yellow, Colors.orange]);

      // 验证统计
      final stats = colorCache.getCacheStats();
      expect(stats['cached_songs'], equals(2));
      expect(stats['total_colors'], equals(5));
      expect(stats['oldest_cache'], isNotNull);
    });

    test('单例模式验证', () {
      final instance1 = ColorCacheService();
      final instance2 = ColorCacheService();
      
      // 应该是同一个实例
      expect(identical(instance1, instance2), isTrue);
    });
  });
}