import 'package:flutter/material.dart';
import '../services/color_cache_service.dart';

/// 颜色缓存使用示例
class ColorCacheExample extends StatefulWidget {
  const ColorCacheExample({super.key});

  @override
  State<ColorCacheExample> createState() => _ColorCacheExampleState();
}

class _ColorCacheExampleState extends State<ColorCacheExample> {
  final ColorCacheService _cacheService = ColorCacheService();
  final TextEditingController _songIdController = TextEditingController();
  final List<Color> _testColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];

  @override
  void dispose() {
    _songIdController.dispose();
    super.dispose();
  }

  void _cacheRandomColors() {
    final songId = _songIdController.text.trim();
    if (songId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入歌曲ID')));
      return;
    }

    // 随机选择3-5个颜色
    final randomColors =
        _testColors.take(3 + (DateTime.now().millisecond % 3)).toList();
    _cacheService.cacheColors(songId, randomColors);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已缓存颜色: ${randomColors.length}个')));

    setState(() {});
  }

  void _checkCache() {
    final songId = _songIdController.text.trim();
    if (songId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入歌曲ID')));
      return;
    }

    final colors = _cacheService.getColors(songId);
    if (colors != null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('缓存结果: $songId'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('已缓存的颜色:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        colors
                            .map(
                              (color) => Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('该歌曲ID无缓存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _cacheService.getCacheStats();

    return Scaffold(
      appBar: AppBar(title: const Text('颜色缓存示例')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '缓存统计',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('缓存歌曲数: ${stats['cached_songs'] ?? 0}'),
                    Text('总颜色数: ${stats['total_colors'] ?? 0}'),
                    if (stats['oldest_cache'] != null)
                      Text('最早缓存: ${stats['oldest_cache']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _songIdController,
              decoration: const InputDecoration(
                labelText: '歌曲ID',
                hintText: '输入歌曲ID来测试缓存',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _cacheRandomColors,
                  child: const Text('缓存随机颜色'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _checkCache,
                  child: const Text('检查缓存'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _cacheService.clearAllCache();
                setState(() {});
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('所有缓存已清除')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('清除所有缓存'),
            ),
          ],
        ),
      ),
    );
  }
}
