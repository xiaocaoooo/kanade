import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/cover_cache_service.dart';
import '../services/music_service.dart';
import '../services/audio_player_service.dart';
import '../pages/player_page.dart';

/// 歌曲项组件
/// 用于统一展示歌曲信息，支持封面显示和点击事件
/// 支持自动加载专辑封面图片和播放跳转功能
class SongItem extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  final bool play;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SongItem({
    super.key,
    required this.song,
    required this.playlist,
    this.play = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<SongItem> createState() => _SongItemState();
}

class _SongItemState extends State<SongItem> {

  @override
  void initState() {
    super.initState();
    _loadCoverIfNeeded();
  }

  @override
  void didUpdateWidget(SongItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.albumId != widget.song.albumId) {
      _loadCoverIfNeeded();
    }
  }

  /// 如果需要，自动加载封面图片
  Future<void> _loadCoverIfNeeded() async {
    final albumId = widget.song.albumId;
    if (albumId == null || albumId.isEmpty) {
      return;
    }

    // 如果缓存中已有，不需要加载
    if (CoverCacheManager.instance.contains(albumId)) {
      return;
    }

    // 如果正在加载中，不需要重复加载
    if (CoverCacheManager.instance.isLoading(albumId)) {
      return;
    }

    // 标记为加载中
    CoverCacheManager.instance.markAsLoading(albumId);
    
    try {
      final coverData = await MusicService.getAlbumArt(albumId);
      if (coverData != null) {
        CoverCacheManager.instance.setCover(albumId, coverData);
        if (mounted) {
          setState(() {}); // 刷新UI显示新加载的封面
        }
      } else {
        // 加载失败，标记为已加载（避免重复尝试）
        CoverCacheManager.instance.setCover(albumId, null);
      }
    } catch (e) {
      // 加载失败，标记为已加载（避免重复尝试）
      CoverCacheManager.instance.setCover(albumId, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final albumId = widget.song.albumId;
    final hasAlbumId = albumId != null && albumId.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildCoverWidget(context, hasAlbumId ? albumId : ''),
      title: Text(
        widget.song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: _buildSubtitle(),
      trailing: _buildTrailing(),
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          _handleSongTap(context);
        }
      },
      onLongPress: widget.onLongPress,
    );
  }

  /// 处理歌曲点击事件
  /// 如果play为true，则播放歌曲并跳转到播放器页面
  void _handleSongTap(BuildContext context) {
    // 使用延迟执行避免构建期间的setState问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.play) {
        // 使用Provider获取音频服务并设置播放列表
        final playerService = Provider.of<AudioPlayerService>(context, listen: false);
        final songIndex = widget.playlist.indexWhere((s) => s.id == widget.song.id);
        
        if (songIndex != -1) {
          playerService.setPlaylist(widget.playlist, initialIndex: songIndex);
          playerService.play();
        }
      }

      // 无论是否播放，都跳转到播放器页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerPage(
            initialSong: widget.song,
            playlist: widget.playlist,
          ),
        ),
      );
    });
  }

  /// 构建封面组件
  Widget _buildCoverWidget(BuildContext context, String albumId) {
    if (albumId.isEmpty) {
      return _buildDefaultCover();
    }

    final cover = CoverCacheManager.instance.getCover(albumId);
    final isLoading = CoverCacheManager.instance.isLoading(albumId);

    if (cover != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          cover,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
        ),
      );
    }

    if (isLoading) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return _buildDefaultCover();
  }

  /// 构建默认封面
  Widget _buildDefaultCover() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, size: 28, color: Colors.grey),
    );
  }

  /// 构建副标题
  Widget _buildSubtitle() {
    final artist = widget.song.artist;
    final album = widget.song.album;
    
    if (artist.isNotEmpty && album.isNotEmpty) {
      return Text(
        '$artist · $album',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      );
    } else if (artist.isNotEmpty) {
      return Text(
        artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      );
    } else if (album.isNotEmpty) {
      return Text(
        album,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      );
    } else {
      return const Text(
        '未知艺术家',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12),
      );
    }
  }

  /// 构建尾部信息
  Widget _buildTrailing() {
    final duration = widget.song.duration;
    if (duration <= 0) return const SizedBox();

    final minutes = duration ~/ 60000;
    final seconds = (duration % 60000) ~/ 1000;
    
    return Text(
      '$minutes:${seconds.toString().padLeft(2, '0')}',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    );
  }
}
