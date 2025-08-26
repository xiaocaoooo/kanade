import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kanade/services/services.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
// 移除不必要的导入
// import '../services/lyrics_service.dart';
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
  String? _lastSongId;
  late Song song;
  List<double> _lyricsLineHeights = [];
  List<double> _prefixSumHeights = []; // 前缀和数组，用于快速计算累积高度
  final List<GlobalKey> _lyricLineKeys = []; // 存储每行歌词的GlobalKey
  final List<bool> _lyricBuilded = []; // 存储每行歌词是否已经构建
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

      _lyrics = lyrics ?? [];
      _hasLyrics = lyrics != null && lyrics.isNotEmpty;
      _isLoading = false;
      // 初始化GlobalKey列表
      _lyricLineKeys.clear();
      _lyricLineKeys.addAll(
        List.generate(_lyrics.length, (index) => GlobalKey()),
      );
      // 初始化构建状态列表
      _lyricBuilded.clear();
      _lyricBuilded.addAll(List.generate(_lyrics.length, (index) => false));

      // 延迟计算高度，确保Widget已经渲染
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateLyricsLineHeightsWithGlobalKey();
      });
    } catch (e) {
      debugPrint('加载歌词失败: $e');
      _isLoading = false;
      _hasLyrics = false;
    }
    setState(() {});
  }

  /// 监听播放位置变化
  void _onPositionChanged() {
    if (_lyrics.isEmpty) return;

    final currentIndex = LyricsService.getCurrentLyricIndex(
      _lyrics,
      _playerService.position,
    );

    if (currentIndex != _currentLyricIndex) {
      _currentLyricIndex = currentIndex;
      _scrollToCurrentLyric();
    }
  }

  /// 使用GlobalKey精确计算每行歌词的高度
  ///
  /// 通过GlobalKey获取每行歌词的实际渲染高度，然后构建前缀和数组
  /// 这种方法比TextPainter估算更准确，因为它使用实际渲染结果
  void _calculateLyricsLineHeightsWithGlobalKey() {
    if (_lyrics.isEmpty || !mounted || !_lyricBuilded.every((e)=>e)) return;

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
          debugPrint('无法获取歌词行 $i 的实际高度，使用估算值');
          lineHeight = _estimateLineHeight(_lyrics[i]);
        }
      } else {
        // 如果没有GlobalKey，使用估算值
        debugPrint('歌词行 $i 没有GlobalKey，使用估算值');
        lineHeight = _estimateLineHeight(_lyrics[i]);
      }

      lineHeights.add(lineHeight);
      prefixSum.add(prefixSum[i] + lineHeight); // 构建前缀和
    }

    _lyricsLineHeights = lineHeights;
    _prefixSumHeights = prefixSum;

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
          style: TextStyle(fontSize: 14, color: LyricsColors.secondaryColor, height: 1.3),
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
    return _prefixSumHeights[index + 1];
  }

  // 移除未使用的方法
  // double _getRangeCumulativeHeight(int startIndex, int endIndex) {
  //   if (startIndex < 0 ||
  //       endIndex >= _lyricsLineHeights.length ||
  //       startIndex > endIndex) {
  //     return 0.0;
  //   }
  //
  //   return _prefixSumHeights[endIndex + 1] - _prefixSumHeights[startIndex];
  // }

  /// 滚动到当前歌词 - 使用GlobalKey计算的精确高度
  void _scrollToCurrentLyric() {
    // 如果高度还未计算，延迟计算
    if (_prefixSumHeights.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateLyricsLineHeightsWithGlobalKey();
      });
      return;
    }

    final targetOffset = _getCumulativeHeight(_currentLyricIndex - 1);
    _offset = targetOffset;
    setState(() {});
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
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.5),
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
                color: LyricsColors.primaryColor,
                child:
                    cover != null
                        ? Image.memory(cover, width: 75, height: 75)
                        : const Icon(Icons.music_note, size: 50),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LyricsColors.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: LyricsColors.secondaryColor,
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
      return Center(
        child: CircularProgressIndicator(color: LyricsColors.primaryColor),
      );
    }

    if (!_hasLyrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics_outlined, size: 64, color: LyricsColors.secondaryColor),
            const SizedBox(height: 16),
            Text(
              '暂无歌词',
              style: TextStyle(color: LyricsColors.secondaryColor, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '请确保歌曲目录下有对应的.lrc文件',
              style: TextStyle(color: LyricsColors.secondaryColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

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
          milliseconds: (300 + 400 * (index - _currentLyricIndex) ~/ 4).clamp(
            50,
            800,
          ),
        );
        _lyricBuilded[index] = true;
        
        return AnimatedPositioned(
          key: _lyricLineKeys[index],
          duration: duration,
          curve: Curves.easeInOut,
          top: top,
          left: 0,
          right: 0,
          child: _buildLyricLine(lyric, isCurrent, index),
        );
      }),
    );
  }

  /// 构建单行歌词
  Widget _buildLyricLine(LyricLine lyric, bool isCurrent, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: LyricLineWithTranslationWidget(
        lyric: lyric,
        isCurrent: isCurrent,
        player: _playerService,
      ),
    );
  }

  /// 从当前歌曲的专辑封面提取颜色
  Future<void> _extractColorsFromCurrentSong() async {
    // 移除不必要的null检查
    final currentSong = song;
    // if (currentSong == null) return; // 这行可以移除，因为song总是非null

    if (_lastSongId == currentSong.id) {
      return;
    }

    _lastSongId = currentSong.id;

    final cachedColors = ColorCacheService.instance.getColors(currentSong.id);
    if (cachedColors != null) {
      _extractedColors = cachedColors;
      return;
    }

    try {
      final albumArt = _playerService.getAlbumArtForSong(currentSong);
      List<Color> extractedColors = [];

      if (albumArt != null) {
        final imageProvider = MemoryImage(albumArt);
        final palette = await PaletteGenerator.fromImageProvider(imageProvider);

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

      ColorCacheService.instance.cacheColors(currentSong.id, extractedColors);
      _extractedColors = extractedColors;
    } catch (e) {
      debugPrint('颜色提取失败: $e');
    }
  }
}

class LyricLineWithTranslationWidget extends StatefulWidget {
  final LyricLine lyric;
  final bool isCurrent;
  final AudioPlayerService player;

  const LyricLineWithTranslationWidget({
    super.key,
    required this.lyric,
    required this.isCurrent,
    required this.player,
  });

  @override
  State<LyricLineWithTranslationWidget> createState() =>
      _LyricLineWithTranslationWidgetState();
}

class _LyricLineWithTranslationWidgetState
    extends State<LyricLineWithTranslationWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LyricLineWithTranslationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrent != widget.isCurrent) {
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (widget.isCurrent) {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LyricLineWidget(
          lyric: widget.lyric,
          isCurrent: widget.isCurrent,
          position: widget.player.position,
        ),
        // 翻译文本（如果有）
        if (widget.lyric.translation != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.lyric.translation!,
              style: TextStyle(
                fontSize: 14,
                color: LyricsColors.secondaryColor,
                height: 1.3,
              ),
            ),
          ),
      ],
    );
  }
}

class LyricLineWidget extends StatelessWidget {
  final LyricLine lyric;
  final bool isCurrent;
  final Duration position;

  const LyricLineWidget({
    super.key,
    required this.lyric,
    required this.isCurrent,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    if (lyric.wordTimings != null && lyric.wordTimings!.isNotEmpty) {
      return _OptimizedWordLyrics(
        wordTimings: lyric.wordTimings!,
        isCurrent: isCurrent,
        position: position,
      );
    }
    
    return LyricsWorldWidget(
      word: lyric.text,
      isActive: isCurrent,
    );
  }
}

/// 支持上升动画的逐字歌词文字组件
class LyricsWorldWidget extends StatelessWidget {
  final String word;
  final bool isActive;
  final double? progress;

  const LyricsWorldWidget({
    super.key,
    required this.word,
    required this.isActive,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // 使用Transform和AnimatedSwitcher实现上升动画
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // 使用SlideTransition实现上升效果
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0),
            end: isActive ? const Offset(0, -0.1) : const Offset(0, 0),
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Builder(
        key: ValueKey('${word}_$isActive'),
        builder: (context) {
          if (progress != null && isActive) {
            // 使用平滑动画组件实现流畅的进度过渡
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 基础文字（灰色背景）
                Text(
                  word,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: LyricsColors.secondaryColor,
                  ),
                ),
                // 渐变覆盖层（高亮进度）
                ClipRect(
                  child: _SmoothProgressAnimation(
                    progress: progress!,
                    child: Text(
                      word,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: LyricsColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          
          // 普通文字显示
          return Text(
            word,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isActive ? LyricsColors.primaryColor : LyricsColors.secondaryColor,
            ),
          );
        },
      ),
    );
  }
}

/// 自定义裁剪器，实现硬渐变效果
class _ProgressClipper extends CustomClipper<Rect> {
  final double progress;

  const _ProgressClipper({required this.progress});

  @override
  Rect getClip(Size size) {
    // 创建从左到右的硬渐变裁剪区域
    return Rect.fromLTWH(
      0,
      0,
      size.width * progress.clamp(0.0, 1.0),
      size.height,
    );
  }

  @override
  bool shouldReclip(_ProgressClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

/// 平滑进度动画组件
class _SmoothProgressAnimation extends StatelessWidget {
  final double progress;
  final Widget child;
  final Duration duration;

  const _SmoothProgressAnimation({
    required this.progress,
    required this.child,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return ClipRect(
          clipper: _ProgressClipper(progress: value),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// 优化的逐字歌词组件，使用动画实现流畅过渡
class _OptimizedWordLyrics extends StatefulWidget {
  final List<WordTiming> wordTimings;
  final bool isCurrent;
  final Duration position;

  const _OptimizedWordLyrics({
    required this.wordTimings,
    required this.isCurrent,
    required this.position,
  });

  @override
  State<_OptimizedWordLyrics> createState() => _OptimizedWordLyricsState();
}

class _OptimizedWordLyricsState extends State<_OptimizedWordLyrics>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(_OptimizedWordLyrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.wordTimings != widget.wordTimings ||
        oldWidget.isCurrent != widget.isCurrent) {
      _disposeAnimations();
      _initializeAnimations();
    } else {
      _updateAnimations();
    }
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.wordTimings.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();

    _updateAnimations();
  }

  void _updateAnimations() {
    if (!widget.isCurrent) return;

    for (int i = 0; i < widget.wordTimings.length; i++) {
      final wordTiming = widget.wordTimings[i];
      final controller = _controllers[i];
      
      double targetProgress;
      bool shouldAnimate = false;
      
      if (widget.position >= wordTiming.startTime && 
          widget.position <= wordTiming.endTime) {
        targetProgress = (widget.position - wordTiming.startTime).inMilliseconds /
                         (wordTiming.endTime - wordTiming.startTime).inMilliseconds;
        shouldAnimate = true;
      } else if (widget.position > wordTiming.endTime) {
        targetProgress = 1.0;
        shouldAnimate = true;
      } else {
        targetProgress = 0.0;
      }

      if (shouldAnimate && controller.value != targetProgress) {
        controller.animateTo(targetProgress);
      } else if (!shouldAnimate && controller.value != 0.0) {
        controller.animateTo(0.0);
      }
    }
  }

  void _disposeAnimations() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: List.generate(widget.wordTimings.length, (index) {
        final wordTiming = widget.wordTimings[index];
        
        bool isWordActive = false;
        if (widget.isCurrent) {
          if (widget.position >= wordTiming.startTime || 
              widget.position > wordTiming.endTime) {
            isWordActive = true;
          }
        }
        
        return KeyedSubtree(
          key: ValueKey('${wordTiming.word}_$index'),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return LyricsWorldWidget(
                word: wordTiming.word,
                isActive: isWordActive,
                progress: isWordActive ? _animations[index].value : null,
              );
            },
          ),
        );
      }),
    );
  }
}

/// 歌词页面颜色定义类
/// 提供歌词页面使用的标准颜色常量
class LyricsColors {
  /// 主要文字颜色 - 高亮白色
  static Color primaryColor = Colors.white.withValues(alpha: 0.9);
  
  /// 次要文字颜色 - 半透明白色
  static Color secondaryColor = Colors.white.withValues(alpha: 0.4);
}
