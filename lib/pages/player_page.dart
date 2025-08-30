import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/color_cache_service.dart';
import '../widgets/color_blender.dart';
// 在文件顶部添加导入
import 'lyrics_page.dart';

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
  final double _blendIntensity = 8;
  bool _isLoadingColors = false;
  String? _lastSongId;
  bool _showLyrics = false;
  bool _willShowControls = true;
  bool _showControls = true;

  GlobalKey _bigImageKey = GlobalKey();
  RenderBox? _bigImageBox;
  Offset? _bigImagePosition; // 存储大图片的全局位置
  GlobalKey _smallImageKey = GlobalKey();
  RenderBox? _smallImageBox;
  Offset? _smallImagePosition; // 存储小图片的全局位置

  // 标题文本的相关变量
  GlobalKey _bigTitleKey = GlobalKey();
  RenderBox? _bigTitleBox;
  Offset? _bigTitlePosition;
  GlobalKey _smallTitleKey = GlobalKey();
  RenderBox? _smallTitleBox;
  Offset? _smallTitlePosition;

  // 艺术家文本的相关变量
  GlobalKey _bigArtistKey = GlobalKey();
  RenderBox? _bigArtistBox;
  Offset? _bigArtistPosition;
  GlobalKey _smallArtistKey = GlobalKey();
  RenderBox? _smallArtistBox;
  Offset? _smallArtistPosition;

  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    // 使用Provider提供的全局音频服务
    _playerService = Provider.of<AudioPlayerService>(context, listen: false);

    // 添加歌曲变化监听器
    _playerService.addListener(_onCurrentSongChanged);
    // 添加播放状态变化监听器
    _playerService.addListener(_onPlayerStateChanged);

    // 延迟初始化，避免在构建过程中调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      screenWidth = MediaQuery.of(context).size.width;
      setState(() {});
      _initializePlayer();
      _extractColorsFromCurrentSong();

      // 启用屏幕唤醒锁
      _enableWakelock();

      // 再添加一个postFrameCallback，确保UI已经重新渲染后再计算位置
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calcImagePosition();
      });
    });
  }

  /// 启用屏幕唤醒锁
  void _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      debugPrint('屏幕唤醒锁已启用');
    } catch (e) {
      debugPrint('启用屏幕唤醒锁失败: $e');
    }
  }

  /// 禁用屏幕唤醒锁
  void _disableWakelock() async {
    try {
      await WakelockPlus.disable();
      debugPrint('屏幕唤醒锁已禁用');
    } catch (e) {
      debugPrint('禁用屏幕唤醒锁失败: $e');
    }
  }

  /// 播放状态变化时的回调
  void _onPlayerStateChanged() {
    if (_playerService.playerState == PlayerState.playing) {
      _enableWakelock();
    } else if (_playerService.playerState == PlayerState.paused ||
               _playerService.playerState == PlayerState.stopped) {
      // 即使暂停，播放器页面仍应保持屏幕唤醒
      // _disableWakelock();
    }
  }

  Future<void> _calcImagePosition() async {
    _bigImageBox =
        _bigImageKey.currentContext?.findRenderObject() as RenderBox?;
    // print(_bigImageBox?.size);
    // 获取大图片的全局位置
    _bigImagePosition = _bigImageBox?.localToGlobal(Offset.zero);
    // print('大图片全局位置: $_bigImagePosition');

    _smallImageBox =
        _smallImageKey.currentContext?.findRenderObject() as RenderBox?;
    // print(_smallImageBox?.size);
    // 获取小图片的全局位置
    _smallImagePosition = _smallImageBox?.localToGlobal(Offset.zero);
    // print('小图片全局位置: $_smallImagePosition');

    // 获取大标题的尺寸和位置
    _bigTitleBox =
        _bigTitleKey.currentContext?.findRenderObject() as RenderBox?;
    _bigTitlePosition = _bigTitleBox?.localToGlobal(Offset.zero);
    // print('大标题位置: $_bigTitlePosition');

    // 获取小标题的尺寸和位置
    _smallTitleBox =
        _smallTitleKey.currentContext?.findRenderObject() as RenderBox?;
    _smallTitlePosition = _smallTitleBox?.localToGlobal(Offset.zero);
    // print('小标题位置: $_smallTitlePosition');

    // 获取大艺术家文本的尺寸和位置
    _bigArtistBox =
        _bigArtistKey.currentContext?.findRenderObject() as RenderBox?;
    _bigArtistPosition = _bigArtistBox?.localToGlobal(Offset.zero);
    // print('大艺术家位置: $_bigArtistPosition');

    // 获取小艺术家文本的尺寸和位置
    _smallArtistBox =
        _smallArtistKey.currentContext?.findRenderObject() as RenderBox?;
    _smallArtistPosition = _smallArtistBox?.localToGlobal(Offset.zero);
    // print('小艺术家位置: $_smallArtistPosition');

    // 通知UI更新，以便AnimatedPositioned使用新的位置信息
    if (mounted) {
      setState(() {});
    }
  }

  /// 当前歌曲变化时的回调
  void _onCurrentSongChanged() {
    if (mounted) {
      _extractColorsFromCurrentSong();
      _calcImagePosition();
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
    _playerService.removeListener(_onPlayerStateChanged);
    
    // 禁用屏幕唤醒锁
    _disableWakelock();
    
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

        extractedColors = colors.toList();
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
          if (palette.dominantColor != null) {
            colors.add(palette.dominantColor!.color);
          }
          if (palette.vibrantColor != null) {
            colors.add(palette.vibrantColor!.color);
          }
          if (palette.mutedColor != null) colors.add(palette.mutedColor!.color);

          extractedColors = colors.toList();
        }
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
    final controlsWidget = Column(
      children: [
        // 播放进度
        _buildProgressControls(),

        // 播放控制
        _buildPlaybackControls(),

        // 音量控制
        _buildVolumeControls(),

        // 播放模式控制
        _buildModeControls(),
      ],
    );
    return ChangeNotifierProvider.value(
      value: _playerService,
      child: WillPopScope(
        // 监听返回键事件
        onWillPop: () async {
          if (_showLyrics) {
            if (!_showControls) {
              setState(() {
                _willShowControls = true;
                _setControlsVisible();
              });
              return false;
            }
            // 当显示歌词时，拦截返回键并关闭歌词显示
            setState(() {
              _showLyrics = false;
              _willShowControls = true;
              _setControlsVisible();
            });
            return false; // 不执行默认的返回操作
          }
          return true; // 执行默认的返回操作
        },
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

                  Positioned.fill(
                    child: GestureDetector(
                      child: Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  key: _smallImageKey,
                                  width: 75,
                                  height: 75,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        key: _smallTitleKey,
                                        player.currentSong!.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.transparent,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        key: _smallArtistKey,
                                        player.currentSong!.artist,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          color: Colors.transparent,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showLyrics)
                            Expanded(
                              child: ShaderMask(
                                // 关键：使用线性渐变作为遮罩
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: const [
                                      Colors.transparent, // 渐变开始
                                      Colors.transparent,
                                      Colors.black, // 底部完全不透明
                                    ],
                                    stops: [
                                      0.0,
                                      5 / bounds.height,
                                      50 / bounds.height,
                                    ], // 调整渐变区域
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.dstIn, // 使用目标输入混合模式
                                child: ClipRect(
                                  child: LyricsPage(
                                    key: ValueKey(player.currentSong!.id),
                                    song: player.currentSong!,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        // _willShowControls = true;
                        // _setControlsVisible();
                        _willShowControls = !_showControls;
                        _setControlsVisible();
                      },
                    ),
                  ),

                  // 主要内容
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 专辑封面区域
                        // _buildAlbumCover(player.currentSong!),
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: SizedBox(
                            key: _bigImageKey,
                            width: screenWidth * .8,
                            height: screenWidth * .8,
                          ),
                        ),

                        // 歌曲信息占位，用于获取大模式下的位置
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(
                                key: _bigTitleKey,
                                child: Text(
                                  player.currentSong!.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.transparent, // 透明文本
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                key: _bigArtistKey,
                                child: Text(
                                  player.currentSong!.artist,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: Colors.transparent, // 透明文本
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        AnimatedOpacity(
                          opacity: _showControls ? 1 : 0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child:
                              _showControls
                                  ? controlsWidget
                                  : IgnorePointer(child: controlsWidget),
                        ),
                      ],
                    ),
                  ),
                  _buildAlbumCover(player.currentSong!),
                  // 实际显示的歌曲信息，带有动画效果
                  ..._buildSongInfo(player.currentSong!),
                ],
              );
            },
          ),
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

        final RenderBox? renderBox =
            _showLyrics ? _smallImageBox : _bigImageBox;
        if (renderBox == null) {
          return Container();
        }

        // 根据当前显示模式选择对应的位置信息
        final Offset? targetPosition =
            _showLyrics ? _smallImagePosition : _bigImagePosition;

        return AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          // 使用全局位置信息，如果位置为null则使用默认值
          top: targetPosition?.dy ?? 0,
          left: targetPosition?.dx ?? 0,
          child: Hero(
            tag: 'album-${song.id}',
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: renderBox.size.width,
              height: renderBox.size.height,
              child: Center(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: renderBox.size.width * (player.isPlaying ? 1 : 0.85),
                  height: renderBox.size.height * (player.isPlaying ? 1 : 0.85),
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
            ),
          ),
        );
      },
    );
  }

  /// 构建歌曲信息 - 添加了歌词开关切换动画
  List<Widget> _buildSongInfo(Song song) {
    // 根据当前显示模式选择对应的位置信息
    final Offset? titlePosition =
        _showLyrics ? _smallTitlePosition : _bigTitlePosition;
    final Offset? artistPosition =
        _showLyrics ? _smallArtistPosition : _bigArtistPosition;
    final RenderBox? titleBox = _showLyrics ? _smallTitleBox : _bigTitleBox;
    final RenderBox? artistBox = _showLyrics ? _smallArtistBox : _bigArtistBox;

    // 如果位置信息还未获取，则显示默认的歌曲信息
    if (titlePosition == null || artistPosition == null) {
      return [
        Text(
          song.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          song.artist,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withOpacity(0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ];
    }

    return [
      AnimatedPositioned(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        top: titlePosition.dy,
        left: titlePosition.dx,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Text(
            song.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      const SizedBox(height: 4),
      AnimatedPositioned(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        top: artistPosition.dy,
        left: artistPosition.dx,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Text(
            song.artist,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];
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
              icon: Icon(
                _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
                color: Colors.white,
              ),
              iconSize: 28,
              onPressed: _showLyricsPage,
              tooltip: '查看歌词',
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

  /// 显示歌词页面
  void _showLyricsPage() {
    setState(() {
      _showLyrics = !_showLyrics;
      _willShowControls = !_showLyrics;
    });
    _setControlsVisible();
  }

  void _setControlsVisible() {
    if (_willShowControls) {
      setState(() {
        _showControls = true;
      });
    } else {
      setState(() {
        _showControls = false;
      });
      // Future.delayed(const Duration(milliseconds: 5000), () {
      //   if (!_willShowControls && mounted) {
      //     setState(() {
      //       _showControls = false;
      //     });
      //   }
      // });
    }
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
                            child: Image.memory(
                              albumArt,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
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
