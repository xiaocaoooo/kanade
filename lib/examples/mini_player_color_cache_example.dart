import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/color_cache_service.dart';
import '../widgets/mini_player.dart';

/// 迷你播放器颜色缓存示例
/// 展示mini player如何自动预计算歌曲颜色
class MiniPlayerColorCacheExample extends StatelessWidget {
  const MiniPlayerColorCacheExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('颜色缓存示例'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showCacheInfo(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('迷你播放器会自动预计算歌曲颜色'),
                  const SizedBox(height: 20),
                  Consumer<AudioPlayerService>(
                    builder: (context, player, child) {
                      final currentSong = player.currentSong;
                      if (currentSong == null) {
                        return const Text('暂无播放');
                      }
                      
                      return Column(
                        children: [
                          Text('当前: ${currentSong.title}'),
                          Text('艺术家: ${currentSong.artist}'),
                          Consumer<ColorCacheService>(
                            builder: (context, cache, child) {
                              final cached = cache.isCached(currentSong.id);
                              return Text(
                                cached ? '颜色已缓存 ✅' : '正在计算颜色...',
                                style: TextStyle(
                                  color: cached ? Colors.green : Colors.orange,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  void _showCacheInfo(BuildContext context) {
    final cache = ColorCacheService();
    final stats = cache.getCacheStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('颜色缓存信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已缓存歌曲: ${stats['cached_songs']}'),
            Text('总颜色数: ${stats['total_colors']}'),
            if (stats['oldest_cache'] != null)
              Text('最早缓存: ${stats['oldest_cache']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              cache.clearAllCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清除所有缓存')),
              );
            },
            child: const Text('清除缓存'),
          ),
        ],
      ),
    );
  }
}