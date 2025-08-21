import 'package:flutter/material.dart';
import '../services/color_cache_service.dart';

/// 颜色缓存调试工具
/// 提供可视化的缓存管理界面
class ColorCacheDebugWidget extends StatelessWidget {
  const ColorCacheDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cacheService = ColorCacheService();
    final stats = cacheService.getCacheStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '颜色缓存调试',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('缓存歌曲数: ${stats['cached_songs'] ?? 0}'),
            Text('总颜色数: ${stats['total_colors'] ?? 0}'),
            if (stats['oldest_cache'] != null)
              Text('最早缓存: ${stats['oldest_cache']}'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    cacheService.clearAllCache();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('颜色缓存已清除')));
                  },
                  child: const Text('清除缓存'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final newStats = cacheService.getCacheStats();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('缓存统计: ${newStats.toString()}')),
                    );
                  },
                  child: const Text('刷新统计'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
