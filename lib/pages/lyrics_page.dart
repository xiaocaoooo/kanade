import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/lyrics_service.dart';

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

  @override
  void initState() {
    super.initState();
    _playerService = Provider.of<AudioPlayerService>(context, listen: false);
    _loadLyrics();
    _playerService.addListener(_onPositionChanged);
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
      
      if (widget.song.path.isNotEmpty) {
        lyrics = await LyricsService.getLyricsFromMetadata(widget.song.path);
      }
      
      // 如果元数据中没有歌词，尝试从LRC文件读取
      if (lyrics == null || lyrics.isEmpty) {
        lyrics = await LyricsService.getLyricsForSong(widget.song);
      }

      setState(() {
        _lyrics = lyrics ?? [];
        _hasLyrics = lyrics != null && lyrics.isNotEmpty;
        _isLoading = false;
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

  /// 滚动到当前歌词
  void _scrollToCurrentLyric() {
    if (_currentLyricIndex < 0 || !_scrollController.hasClients) return;

    final itemHeight = 60.0; // 估计每行高度
    final screenHeight = MediaQuery.of(context).size.height;
    final targetOffset = _currentLyricIndex * itemHeight - screenHeight / 2 + itemHeight;

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.song.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.song.artist,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildLyricsContent(),
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
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 100),
          itemCount: _lyrics.length,
          itemBuilder: (context, index) {
            final lyric = _lyrics[index];
            final isCurrent = index == _currentLyricIndex;
            
            return _buildLyricLine(lyric, isCurrent);
          },
        );
      },
    );
  }

  /// 构建单行歌词
  Widget _buildLyricLine(LyricLine lyric, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 逐字歌词显示
          if (lyric.wordTimings != null && lyric.wordTimings!.isNotEmpty)
            _buildWordByWordLyrics(lyric, isCurrent),
          
          // 整行歌词
          if (lyric.wordTimings == null || lyric.wordTimings!.isEmpty) Text(
            lyric.text,
            style: TextStyle(
              fontSize: isCurrent ? 22 : 18,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? Colors.white : Colors.grey,
              height: 1.5,
            ),
          ),
          
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
  Widget _buildWordByWordLyrics(LyricLine lyric, bool isCurrent) {
    final player = Provider.of<AudioPlayerService>(context, listen: true);
    final currentPosition = player.position;
    
    return RichText(
      text: TextSpan(
        children: lyric.wordTimings!.map((wordTiming) {
          final isWordActive = isCurrent && currentPosition >= wordTiming.startTime;
          return TextSpan(
            text: wordTiming.word,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isWordActive ? Colors.blue : Colors.grey,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 检查是否有翻译
  bool _hasTranslation(String text) {
    // 这里可以根据需要实现翻译检测逻辑
    // 暂时返回false，后续可以扩展
    return false;
  }

  /// 获取翻译文本
  String _getTranslation(String text) {
    // 这里可以根据需要实现翻译获取逻辑
    // 暂时返回空字符串，后续可以扩展
    return '';
  }
}
