import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/color_cache_service.dart';
import '../widgets/color_blender.dart';

/// 音乐播放器页面
/// 提供完整的播放控制界面，包括播放/暂停、进度条、音量控制等
class PlayerPage extends StatefulWidget {
  final Song? initialSong;
  final List<Song>? playlist;

  const PlayerPage({super.key, this.initialSong, this.playlist});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late AudioPlayerService _playerService;
  List<Color> _extractedColors = [Colors.black];
  double _blendIntensity = 8;
  bool _isLoadingColors = false;
  String? _lastSongId;

  @override
  void initState() {
    super.initState();
    // 使用Provider提供的全局音频服务
    _playerService = Provider.of<AudioPlayerService>(context, listen: false);

    // 添加歌曲变化监听器
    _playerService.addListener(_onCurrentSongChanged);

    // 延迟初始化，避免在构建过程中调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
      _extractColorsFromCurrentSong();
    });
  }

  /// 当前歌曲变化时的回调
  void _onCurrentSongChanged() {
    if (mounted) {
      _extractColorsFromCurrentSong();
    }
  }

  void _initializePlayer() {
    // 设置播放列表并播放初始歌曲
    if (widget.playlist != null && widget.initialSong != null) {
      // 找到初始歌曲在播放列表中的索引
      final initialIndex = widget.playlist!.indexWhere(
        (song) => song.id == widget.initialSong!.id,
      );

      // 设置播放列表并指定初始索引
      _playerService.setPlaylist(
        widget.playlist!,
        initialIndex: initialIndex != -1 ? initialIndex : 0,
      );

      // 播放当前歌曲
      _playerService.play();
    } else if (widget.playlist != null) {
      // 只设置播放列表，不自动播放
      _playerService.setPlaylist(widget.playlist!);
    } else if (widget.initialSong != null) {
      // 只有单首歌曲，创建包含该歌曲的播放列表
      _playerService.setPlaylist([widget.initialSong!]);
      _playerService.play();
    }
  }

  @override
  void dispose() {
    // 移除监听器
    _playerService.removeListener(_onCurrentSongChanged);
    super.dispose();
  }

  /// 从当前歌曲的专辑封面提取颜色
  /// 优先使用缓存，无缓存时提取并缓存
  Future<void> _extractColorsFromCurrentSong() async {
    final currentSong = _playerService.currentSong;
    if (currentSong == null) return;

    // 如果歌曲没有变化，直接返回
    if (_lastSongId == currentSong.id) {
      return;
    }

    _lastSongId = currentSong.id;

    // 检查缓存
    final cachedColors = ColorCacheService.instance.getColors(currentSong.id);
    if (cachedColors != null) {
      setState(() {
        _extractedColors = cachedColors;
        _isLoadingColors = false;
      });
      return;
    }

    setState(() {
      _isLoadingColors = true;
    });

    try {
      final albumArt = _playerService.getAlbumArtForSong(currentSong);
      List<Color> extractedColors = [];

      if (albumArt != null) {
        // 从内存图片提取颜色
        final imageProvider = MemoryImage(albumArt);
        final palette = await PaletteGenerator.fromImageProvider(imageProvider);

        // 提取主要颜色
        final colors = <Color>[];

        if (palette.dominantColor != null) {
          colors.add(palette.dominantColor!.color);
        }
        if (palette.vibrantColor != null) {
          colors.add(palette.vibrantColor!.color);
        }
        if (palette.mutedColor != null) {
          colors.add(palette.mutedColor!.color);
        }
        if (palette.darkVibrantColor != null) {
          colors.add(palette.darkVibrantColor!.color);
        }
        if (palette.lightVibrantColor != null) {
          colors.add(palette.lightVibrantColor!.color);
        }

        extractedColors = colors.take(5).toList();
      } else if (currentSong.albumId != null) {
        // 异步加载封面并提取颜色
        await _playerService.loadAlbumArtForSong(currentSong);
        final loadedArt = _playerService.getAlbumArtForSong(currentSong);
        if (loadedArt != null) {
          final imageProvider = MemoryImage(loadedArt);
          final palette = await PaletteGenerator.fromImageProvider(
            imageProvider,
          );

          final colors = <Color>[];
          if (palette.dominantColor != null)
            colors.add(palette.dominantColor!.color);
          if (palette.vibrantColor != null)
            colors.add(palette.vibrantColor!.color);
          if (palette.mutedColor != null) colors.add(palette.mutedColor!.color);

          if (colors.length < 3) {
            colors.addAll([Colors.deepPurple, Colors.purple, Colors.indigo]);
          }

          extractedColors = colors.take(5).toList();
        }
      }

      // 如果没有提取到颜色，使用默认颜色
      if (extractedColors.isEmpty) {
        extractedColors = [Colors.deepPurple, Colors.purple, Colors.indigo];
      }

      // 缓存提取的颜色
      ColorCacheService.instance.cacheColors(currentSong.id, extractedColors);

      setState(() {
        _extractedColors = extractedColors;
        _isLoadingColors = false;
      });
    } catch (e) {
      debugPrint('颜色提取失败: $e');
      setState(() {
        _isLoadingColors = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _playerService,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Consumer<AudioPlayerService>(
          builder: (context, player, child) {
            if (player.currentSong == null) {
              return const Center(child: Text('暂无播放歌曲'));
            }

            return Stack(
              children: [
                // 动态颜色背景
                Positioned.fill(
                  child: ColorBlender(
                    colors: _extractedColors,
                    blendIntensity: _blendIntensity,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    shapeType: BlendShapeType.circle,
                    enableAnimation: true,
                  ),
                ),

                // 内容层 - 半透明遮罩
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),

                // 主要内容
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 专辑封面区域
                      _buildAlbumCover(player.currentSong!),

                      // 歌曲信息
                      _buildSongInfo(player.currentSong!),

                      // 播放进度
                      _buildProgressControls(),

                      // 播放控制
                      _buildPlaybackControls(),

                      // 音量控制
                      _buildVolumeControls(),

                      // 播放模式控制
                      _buildModeControls(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 构建专辑封面
  Widget _buildAlbumCover(Song song) {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        final albumArt = player.getAlbumArtForSong(song);

        // 异步加载封面并提取颜色
        if (albumArt == null && song.albumId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await player.loadAlbumArtForSong(song);
            // 封面加载完成后提取颜色
            if (mounted) {
              await _extractColorsFromCurrentSong();
            }
          });
        } else if (albumArt != null && _extractedColors.isEmpty) {
          // 如果已有封面但颜色未提取，则提取颜色
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              await _extractColorsFromCurrentSong();
            }
          });
        }

        final screenWidth = MediaQuery.of(context).size.width;

        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Hero(
            tag: 'album-${song.id}',
            child: Container(
              width: screenWidth * .8,
              height: screenWidth * .8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    albumArt != null
                        ? Image.memory(
                          albumArt,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                        : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.music_note,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建歌曲信息
  Widget _buildSongInfo(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text(
            song.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建进度控制
  Widget _buildProgressControls() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20.0,
                  ),
                ),
                child: Slider(
                  value: player.progress,
                  onChanged: (value) {
                    final newPosition = Duration(
                      milliseconds:
                          (value * player.duration.inMilliseconds).toInt(),
                    );
                    player.seek(newPosition);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(player.position),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDuration(player.duration),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建播放控制
  Widget _buildPlaybackControls() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              iconSize: 32,
              onPressed: player.previous,
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              backgroundColor: Colors.white.withOpacity(0.2),
              elevation: 4,
              child: Icon(
                player.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
                color: Colors.white,
              ),
              onPressed: () {
                if (player.isPlaying) {
                  player.pause();
                } else {
                  player.play();
                }
              },
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              iconSize: 32,
              onPressed: player.next,
            ),
          ],
        );
      },
    );
  }

  /// 构建音量控制
  Widget _buildVolumeControls() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            children: [
              const Icon(Icons.volume_down, size: 20, color: Colors.white),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: player.volume,
                    onChanged: (value) => player.setVolume(value),
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
              ),
              const Icon(Icons.volume_up, size: 20, color: Colors.white),
            ],
          ),
        );
      },
    );
  }

  /// 构建播放模式控制
  Widget _buildModeControls() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                player.playMode == PlayMode.repeatAll
                    ? Icons.repeat
                    : player.playMode == PlayMode.repeatOne
                    ? Icons.repeat_one
                    : Icons.shuffle,
                color: Colors.white,
                size: 28,
              ),
              onPressed: player.togglePlayMode,
              tooltip: _getPlayModeTooltip(player.playMode),
            ),
            IconButton(
              icon: const Icon(Icons.playlist_play, color: Colors.white),
              iconSize: 28,
              onPressed: _showPlaylistDialog,
              tooltip: '播放列表',
            ),
          ],
        );
      },
    );
  }

  /// 显示播放列表对话框
  void _showPlaylistDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final ScrollController scrollController = ScrollController();
        final GlobalKey firstItemKey = GlobalKey();

        // 在对话框构建完成后滚动到当前歌曲的下一个位置
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_playerService.playlist.isEmpty) return;

          // 获取第一个项目的高度
          double itemHeight = 64.0; // 默认值
          try {
            final RenderObject? renderObject =
                firstItemKey.currentContext?.findRenderObject();
            if (renderObject is RenderBox) {
              itemHeight = renderObject.size.height;
            }
          } catch (e) {
            debugPrint('获取项目高度失败，使用默认值: $e');
          }
          debugPrint('项目高度: $itemHeight');

          // 计算滚动位置：当前歌曲的下一个位置
          final int targetIndex = _playerService.currentIndex - 1;
          if (targetIndex < _playerService.playlist.length) {
            final double scrollOffset = targetIndex * itemHeight;

            // 确保滚动位置在有效范围内
            final double maxScrollExtent =
                scrollController.position.maxScrollExtent;
            final double finalOffset = scrollOffset.clamp(0.0, maxScrollExtent);

            scrollController.jumpTo(finalOffset);
          }
        });

        return SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            controller: scrollController,
            shrinkWrap: true,
            itemCount: _playerService.playlist.length,
            itemBuilder: (context, index) {
              final song = _playerService.playlist[index];
              final albumArt = _playerService.getAlbumArtForSong(song);

              // 异步加载封面
              if (albumArt == null && song.albumId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _playerService.loadAlbumArtForSong(song);
                });
              }

              final Widget listItem = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListTile(
                  leading:
                      albumArt != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.memory(albumArt, width: 40, height: 40, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.music_note),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: index == _playerService.currentIndex,
                  onTap: () {
                    _playerService.setPlaylist(
                      _playerService.playlist,
                      initialIndex: index,
                    );
                    _playerService.play();
                    Navigator.pop(context);
                  },
                ),
              );

              // 为第一项添加key以便测量高度
              if (index == 0) {
                return KeyedSubtree(key: firstItemKey, child: listItem);
              }

              return listItem;
            },
          ),
        );
      },
    );
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  /// 获取播放模式提示
  String _getPlayModeTooltip(PlayMode mode) {
    switch (mode) {
      case PlayMode.repeatAll:
        return '列表循环';
      case PlayMode.repeatOne:
        return '单曲循环';
      case PlayMode.shuffle:
        return '随机播放';
      default:
        return '列表循环';
    }
  }
}

/// 清除颜色缓存
void _clearColorCache() {
  ColorCacheService.instance.clearAllCache();
  debugPrint('颜色缓存已清除');
}

/// 显示缓存统计信息
void _showCacheStats() {
  final stats = ColorCacheService.instance.getCacheStats();
  debugPrint('颜色缓存统计: $stats');
}
