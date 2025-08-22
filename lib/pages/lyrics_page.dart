import 'package:flutter/material.dart';
import 'package:kanade/services/services.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/lyrics_service.dart';
import '../services/color_cache_service.dart';
import '../widgets/color_blender.dart';

/// 歌词显示页面
/// 支持逐行歌词和逐字歌词显示
class LyricsPage extends StatefulWidget {
  final Song song;

  const LyricsPage({super.key, required this.song});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  late AudioPlayerService _playerService;
  List<LyricLine> _lyrics = [];
  bool _isLoading = true;
  bool _hasLyrics = false;
  final ScrollController _scrollController = ScrollController();
  int _currentLyricIndex = -1;
  List<Color> _extractedColors = [Colors.black];
  final double _blendIntensity = 8;
  bool _isLoadingColors = false;
  String? _lastSongId;
  late Song song;
  List<double> _lyricsLineHeights = [];
  List<double> _prefixSumHeights = []; // 前缀和数组，用于快速计算累积高度
  final List<GlobalKey> _lyricLineKeys = []; // 存储每行歌词的GlobalKey
  double _offset = 0;
  double _screenHeight = 0;

  @override
  void initState() {
    super.initState();
    song = widget.song;
    _playerService = Provider.of<AudioPlayerService>(context, listen: false);
    _loadLyrics();
    _playerService.addListener(_onPositionChanged);

    // 延迟初始化，避免在构建过程中调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenHeight = MediaQuery.of(context).size.height;
      _extractColorsFromCurrentSong();
    });
  }

  @override
  void didUpdateWidget(covariant LyricsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song != widget.song) {
      song = widget.song;
      _loadLyrics();
      _extractColorsFromCurrentSong();
    }
  }

  @override
  void dispose() {
    _playerService.removeListener(_onPositionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载歌词
  Future<void> _loadLyrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 优先从音频文件元数据读取歌词
      List<LyricLine>? lyrics;

      if (song.path.isNotEmpty) {
        lyrics = await LyricsService.getLyricsFromMetadata(song.path);
      }

      // 如果元数据中没有歌词，尝试从LRC文件读取
      if (lyrics == null || lyrics.isEmpty) {
        lyrics = await LyricsService.getLyricsForSong(song);
      }

      setState(() {
        _lyrics = lyrics ?? [];
        _hasLyrics = lyrics != null && lyrics.isNotEmpty;
        _isLoading = false;
        // 初始化GlobalKey列表
        _lyricLineKeys.clear();
        _lyricLineKeys.addAll(
          List.generate(_lyrics.length, (index) => GlobalKey()),
        );
      });

      // 延迟计算高度，确保Widget已经渲染
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateLyricsLineHeightsWithGlobalKey();
      });
    } catch (e) {
      print('加载歌词失败: $e');
      setState(() {
        _isLoading = false;
        _hasLyrics = false;
      });
    }
  }

  /// 监听播放位置变化
  void _onPositionChanged() {
    if (_lyrics.isEmpty) return;

    final currentIndex = LyricsService.getCurrentLyricIndex(
      _lyrics,
      _playerService.position,
    );

    if (currentIndex != _currentLyricIndex) {
      setState(() {
        _currentLyricIndex = currentIndex;
      });
      _scrollToCurrentLyric();
    }
  }

  /// 使用GlobalKey精确计算每行歌词的高度
  ///
  /// 通过GlobalKey获取每行歌词的实际渲染高度，然后构建前缀和数组
  /// 这种方法比TextPainter估算更准确，因为它使用实际渲染结果
  void _calculateLyricsLineHeightsWithGlobalKey() {
    if (_lyrics.isEmpty || !mounted) return;

    final List<double> lineHeights = [];
    final List<double> prefixSum = [0.0]; // 前缀和数组，第一个元素为0

    // 遍历所有歌词行，使用GlobalKey获取实际高度
    for (int i = 0; i < _lyrics.length; i++) {
      double lineHeight = 0.0;

      // 使用GlobalKey获取当前行的RenderBox
      if (i < _lyricLineKeys.length &&
          _lyricLineKeys[i].currentContext != null) {
        final renderBox =
            _lyricLineKeys[i].currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          lineHeight = renderBox.size.height;
        } else {
          // 如果无法获取实际高度，使用估算值
          lineHeight = _estimateLineHeight(_lyrics[i]);
        }
      } else {
        // 如果没有GlobalKey，使用估算值
        lineHeight = _estimateLineHeight(_lyrics[i]);
      }

      lineHeights.add(lineHeight);
      prefixSum.add(prefixSum[i] + lineHeight); // 构建前缀和
    }

    setState(() {
      _lyricsLineHeights = lineHeights;
      _prefixSumHeights = prefixSum;
    });

    // 高度计算完成后，重新滚动到当前歌词
    if (_currentLyricIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentLyric();
      });
    }
  }

  /// 估算行高（作为GlobalKey失效时的后备方案）
  double _estimateLineHeight(LyricLine lyric) {
    final screenWidth = MediaQuery.of(context).size.width - 48; // 减去水平边距
    double lineHeight = 0.0;

    // 基础高度（主歌词）
    final textStyle = TextStyle(
      fontSize:
          (lyric.wordTimings != null && lyric.wordTimings!.isNotEmpty)
              ? 20
              : 18,
      fontWeight:
          (lyric.wordTimings != null && lyric.wordTimings!.isNotEmpty)
              ? FontWeight.bold
              : FontWeight.normal,
      height: 1.5,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: lyric.text, style: textStyle),
      maxLines: null,
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
    );

    textPainter.layout(maxWidth: screenWidth);
    lineHeight = textPainter.height + 24; // 加上垂直边距

    // 如果有翻译文本，增加额外高度
    if (lyric.translation != null) {
      final translationPainter = TextPainter(
        text: TextSpan(
          text: lyric.translation,
          style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.3),
        ),
        maxLines: null,
        textDirection: TextDirection.ltr,
        textWidthBasis: TextWidthBasis.longestLine,
      );

      translationPainter.layout(maxWidth: screenWidth);
      lineHeight += translationPainter.height + 16; // 翻译文本高度 + 间距
    }

    return lineHeight;
  }

  /// 使用前缀和算法获取指定索引的累积高度
  ///
  /// @param index 歌词行索引
  /// @return 从第0行到第index行的累积高度
  double _getCumulativeHeight(int index) {
    if (index < 0 || index >= _prefixSumHeights.length - 1) {
      return 0.0;
    }
    return _prefixSumHeights[index + 1]; // 因为prefixSum[0] = 0.0
  }

  /// 使用前缀和算法获取指定范围的累积高度
  ///
  /// @param startIndex 起始索引（包含）
  /// @param endIndex 结束索引（包含）
  /// @return 从startIndex到endIndex的累积高度
  double _getRangeCumulativeHeight(int startIndex, int endIndex) {
    if (startIndex < 0 ||
        endIndex >= _lyricsLineHeights.length ||
        startIndex > endIndex) {
      return 0.0;
    }

    return _prefixSumHeights[endIndex + 1] - _prefixSumHeights[startIndex];
  }

  /// 滚动到当前歌词 - 使用GlobalKey计算的精确高度
  void _scrollToCurrentLyric() {
    // if (_currentLyricIndex < 0) return;

    // 如果高度还未计算，延迟计算
    if (_prefixSumHeights.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateLyricsLineHeightsWithGlobalKey();
      });
      return;
    }

    final currentLineHeight =
        _currentLyricIndex < _lyricsLineHeights.length
            ? _lyricsLineHeights[_currentLyricIndex]
            : 60.0;

    final targetOffset = _getCumulativeHeight(_currentLyricIndex - 1);

    // _scrollController.animateTo(
    //   targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
    //   duration: const Duration(milliseconds: 300),
    //   curve: Curves.easeOut,
    // );
    setState(() {
      _offset = targetOffset;
      print('targetOffset: $targetOffset');
    });
  }

  /// 获取当前歌词行的精确高度
  double _getCurrentLineHeight(int index) {
    if (index < 0 || index >= _lyricsLineHeights.length) {
      return 60.0; // 默认高度
    }
    return _lyricsLineHeights[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
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
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              _buildInfo(),
              Expanded(
                child: ShaderMask(
                  // 关键：使用线性渐变作为遮罩
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
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
                  child: ClipRect(child: _buildLyricsContent()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建歌曲信息
  Widget _buildInfo() {
    final cover =
        song.albumId != null
            ? CoverCacheManager.instance.getCover(song.albumId!)
            : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Hero(
            tag: 'album-${song.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.white.withValues(alpha: .8),
                child:
                    cover != null
                        ? Image.memory(cover, width: 75, height: 75)
                        : const Icon(Icons.music_note, size: 50),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建歌词内容
  Widget _buildLyricsContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (!_hasLyrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lyrics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '暂无歌词',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '请确保歌曲目录下有对应的.lrc文件',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Stack(
          children: List.generate(_lyrics.length, (index) {
            final lyric = _lyrics[index];
            final isCurrent = index == _currentLyricIndex;
            final top = _getCumulativeHeight(index - 1) - _offset + 48;
            final height = _getCurrentLineHeight(index);
            final bottom = top + height;
            if (bottom < 0 || top > _screenHeight) {
              return Container();
            }
            final duration = Duration(
              milliseconds: (300 + 400 * (index - _currentLyricIndex) ~/ 4)
                  .clamp(50, 800),
            );

            return AnimatedPositioned(
              key: ValueKey('lyric-$index'),
              duration: duration,
              curve: Curves.easeOut,
              top: top,
              left: 0,
              right: 0,
              child: _buildLyricLine(lyric, isCurrent, index),
            );
          }),
        );
      },
    );
  }

  /// 构建单行歌词
  Widget _buildLyricLine(LyricLine lyric, bool isCurrent, int index) {
    return Container(
      key: _lyricLineKeys[index],
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLyricsLine(lyric, isCurrent),
          // 翻译文本（如果有）
          if (lyric.translation != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                lyric.translation!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建逐字歌词
  Widget _buildLyricsLine(LyricLine lyric, bool isCurrent) {
    final player = Provider.of<AudioPlayerService>(context, listen: true);
    final currentPosition = player.position;

    if (lyric.wordTimings != null && lyric.wordTimings!.isNotEmpty) {
      return Wrap(
        children:
            lyric.wordTimings!.map((wordTiming) {
              final isWordActive =
                  isCurrent && currentPosition >= wordTiming.startTime;
              final progress =
                  isWordActive
                      ? (currentPosition - wordTiming.startTime)
                              .inMilliseconds /
                          (wordTiming.endTime - wordTiming.startTime)
                              .inMilliseconds
                      : null;
              return _buildLyricsWorld(
                wordTiming.word,
                isWordActive,
                progress: progress,
              );
            }).toList(),
      );
    }
    return _buildLyricsWorld(lyric.text, isCurrent, progress: null);
  }

  Widget _buildLyricsWorld(String world, bool isActive, {double? progress}) {
    return Text(
      world,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isActive ? Colors.white : Colors.grey,
      ),
    );
  }

  /// 从当前歌曲的专辑封面提取颜色
  /// 优先使用缓存，无缓存时提取并缓存
  Future<void> _extractColorsFromCurrentSong() async {
    final currentSong = song;
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
}
