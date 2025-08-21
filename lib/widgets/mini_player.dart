import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:palette_generator/palette_generator.dart';

import '../services/audio_player_service.dart';
import '../services/color_cache_service.dart';
import '../models/song.dart';
import '../pages/player_page.dart';

/// 迷你播放器小部件
/// 显示当前播放信息和基本控制
class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  late final AudioPlayerService _playerService;
  late final ColorCacheService _colorCache;
  String? _lastSongId;

  @override
  void initState() {
    super.initState();
    _playerService = Provider.of<AudioPlayerService>(context, listen: false);
    _colorCache = ColorCacheService();
    _lastSongId = _playerService.currentSong?.id;
    
    // 监听歌曲变化
    _playerService.addListener(_onSongChanged);
    
    // 初始化时检查当前歌曲
    if (_playerService.currentSong != null) {
      _precomputeColorsForSong(_playerService.currentSong!);
    }
  }

  @override
  void dispose() {
    _playerService.removeListener(_onSongChanged);
    super.dispose();
  }

  /// 歌曲变化时的处理
  void _onSongChanged() {
    final currentSong = _playerService.currentSong;
    if (currentSong != null && currentSong.id != _lastSongId) {
      _lastSongId = currentSong.id;
      _precomputeColorsForSong(currentSong);
    }
  }

  /// 预计算歌曲颜色并缓存
  Future<void> _precomputeColorsForSong(Song song) async {
    try {
      // 检查是否已缓存
      if (_colorCache.isCached(song.id)) {
        debugPrint('歌曲 ${song.id} 的颜色已缓存，跳过计算');
        return;
      }

      debugPrint('开始预计算歌曲 ${song.id} 的颜色');
      
      // 获取专辑封面
      final albumArt = _playerService.getAlbumArtForSong(song);
      if (albumArt == null) {
        debugPrint('歌曲 ${song.id} 无专辑封面，跳过');
        return;
      }

      // 从字节数据创建图片
      final image = MemoryImage(albumArt);
      
      // 生成调色板
      final palette = await PaletteGenerator.fromImageProvider(
        image,
        maximumColorCount: 20,
      );

      // 提取主要颜色
      final colors = <Color>[];
      
      // 添加主要颜色
      if (palette.dominantColor?.color != null) {
        colors.add(palette.dominantColor!.color);
      }
      
      // 添加鲜艳的颜色
      final vibrant = palette.vibrantColor?.color;
      if (vibrant != null && !colors.contains(vibrant)) {
        colors.add(vibrant);
      }
      
      // 添加其他显著颜色
      final sortedColors = palette.colors.toList()
        ..sort((a, b) {
          final aSat = HSLColor.fromColor(a).saturation;
          final bSat = HSLColor.fromColor(b).saturation;
          return bSat.compareTo(aSat);
        });
      
      // 最多取5个颜色
      colors.addAll(sortedColors.take(5 - colors.length));

      if (colors.isNotEmpty) {
        // 缓存颜色
        _colorCache.cacheColors(song.id, colors);
        debugPrint('已缓存歌曲 ${song.id} 的颜色：${colors.length} 种');
      }
    } catch (e) {
      debugPrint('预计算歌曲 ${song.id} 颜色失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        if (player.currentSong == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlayerPage()),
            );
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // 专辑封面
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Hero(
                    tag: 'album-${player.currentSong!.id}',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: () {
                        final albumArt = player.getAlbumArtForSong(
                          player.currentSong!,
                        );
                        if (albumArt != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.memory(albumArt, fit: BoxFit.cover),
                          );
                        } else {
                          // 异步加载封面
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            player.loadAlbumArtForSong(player.currentSong!);
                          });
                          return const Icon(Icons.music_note, size: 24);
                        }
                      }(),
                    ),
                  ),
                ),

                // 歌曲信息
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.currentSong?.title ?? '未知歌曲',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        player.currentSong?.artist ?? '未知艺术家',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),

                // 播放控制
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 20),
                      onPressed: player.previous,
                    ),
                    IconButton(
                      icon: Icon(
                        player.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 24,
                      ),
                      onPressed: () {
                        if (player.isPlaying) {
                          player.pause();
                        } else {
                          player.play();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 20),
                      onPressed: player.next,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
