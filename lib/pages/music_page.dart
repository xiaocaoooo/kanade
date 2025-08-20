import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:kanade/pages/folder_page.dart';
import 'package:kanade/pages/artist_page.dart';
import 'package:kanade/pages/album_page.dart';
import 'package:kanade/pages/songs_page.dart';
import 'package:kanade/services/music_service.dart';
import 'package:kanade/models/song.dart';

/// 音乐分类页面
/// 提供按文件夹、艺术家、专辑等多种分类方式
/// 支持实时统计和智能推荐功能
class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  /// 音乐统计信息
  late Future<MusicStats> _musicStats;
  
  /// 加载状态
  bool _isLoading = true;
  
  /// 错误信息
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMusicStats();
  }

  /// 加载音乐统计信息
  Future<void> _loadMusicStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _musicStats = _calculateMusicStats();
      await _musicStats;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// 计算音乐统计信息
  Future<MusicStats> _calculateMusicStats() async {
    final songs = await MusicService.getAllSongsWithoutArt();
    
    // 按不同维度分类统计
    final folderGroups = _groupByFolder(songs);
    final artistGroups = _groupByArtist(songs);
    final albumGroups = _groupByAlbum(songs);
    
    return MusicStats(
      totalSongs: songs.length,
      totalArtists: artistGroups.length,
      totalAlbums: albumGroups.length,
      totalFolders: folderGroups.length,
      totalDuration: songs.fold(0, (sum, song) => sum + song.duration),
      songs: songs,
    );
  }

  /// 按文件夹分组
  Map<String, List<Song>> _groupByFolder(List<Song> songs) {
    final groups = <String, List<Song>>{};
    for (final song in songs) {
      final folder = _extractFolderPath(song.path);
      groups.putIfAbsent(folder, () => []).add(song);
    }
    return groups;
  }

  /// 按艺术家分组
  Map<String, List<Song>> _groupByArtist(List<Song> songs) {
    final groups = <String, List<Song>>{};
    for (final song in songs) {
      if (song.artists.isEmpty) {
        // 如果艺术家列表为空，使用未知艺术家
        final unknownArtist = '未知艺术家';
        groups.putIfAbsent(unknownArtist, () => []).add(song);
      } else {
        // 使用分割后的每个艺术家作为独立的艺术家
        for (final artist in song.artists) {
          final artistName = artist.isNotEmpty ? artist : '未知艺术家';
          groups.putIfAbsent(artistName, () => []).add(song);
        }
      }
    }
    return groups;
  }

  /// 按专辑分组
  Map<String, List<Song>> _groupByAlbum(List<Song> songs) {
    final groups = <String, List<Song>>{};
    for (final song in songs) {
      final album = song.album.isNotEmpty ? song.album : '未知专辑';
      groups.putIfAbsent(album, () => []).add(song);
    }
    return groups;
  }

  /// 提取文件夹路径（Android平台专用）
  String _extractFolderPath(String filePath) {
    final parts = filePath.split('/');
    if (parts.length > 1) {
      return parts.sublist(0, parts.length - 1).join('/');
    }
    return '根目录';
  }

  /// 格式化时长显示
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('音乐')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMusicStats,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMusicStats,
            tooltip: '刷新统计',
          ),
        ],
      ),
      body: FutureBuilder<MusicStats>(
        future: _musicStats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('错误: ${snapshot.error}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMusicStats,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data!;
          return _buildMusicContent(stats);
        },
      ),
    );
  }

  /// 构建音乐内容
  Widget _buildMusicContent(MusicStats stats) {
    return RefreshIndicator(
      onRefresh: _loadMusicStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(stats),
            const SizedBox(height: 24),
            const Text(
              '音乐分类',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCategoryGrid(stats),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息区域
  Widget _buildStatsSection(MusicStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '音乐库统计',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.music_note, stats.totalSongs, '歌曲'),
                _buildStatItem(Icons.person, stats.totalArtists, '艺术家'),
                _buildStatItem(Icons.album, stats.totalAlbums, '专辑'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.folder, stats.totalFolders, '文件夹'),
                _buildStatItem(Icons.timer, _formatDuration(stats.totalDuration~/1000), '总时长'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(IconData icon, dynamic value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  /// 构建分类网格
  Widget _buildCategoryGrid(MusicStats stats) {
    final categories = [
      _CategoryInfo(
        icon: Icons.folder,
        title: '文件夹',
        subtitle: '按文件夹浏览音乐',
        count: stats.totalFolders,
        color: Colors.blue,
        onTap: () => _navigateToFolderPage(context),
      ),
      _CategoryInfo(
        icon: Icons.person,
        title: '艺术家',
        subtitle: '按艺术家浏览音乐',
        count: stats.totalArtists,
        color: Colors.green,
        onTap: () => _navigateToArtistPage(context),
      ),
      _CategoryInfo(
        icon: Icons.album,
        title: '专辑',
        subtitle: '按专辑浏览音乐',
        count: stats.totalAlbums,
        color: Colors.orange,
        onTap: () => _navigateToAlbumPage(context),
      ),
      _CategoryInfo(
        icon: Icons.list,
        title: '全部歌曲',
        subtitle: '浏览所有本地歌曲',
        count: stats.totalSongs,
        color: Colors.purple,
        onTap: () => _navigateToSongsPage(context),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: categories.map((category) => _buildCategoryCard(category)).toList(),
    );
  }

  /// 构建分类卡片
  Widget _buildCategoryCard(_CategoryInfo category) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: category.onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0), // 减少内边距
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // 限制最小高度
            children: [
              Icon(
                category.icon,
                size: 26, // 减小图标尺寸
                color: category.color,
              ),
              const SizedBox(height: 2), // 减少间距
              Text(
                category.title,
                style: const TextStyle(
                  fontSize: 14, // 减小字体大小
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${category.count} ${category.count == 1 ? '首' : '首'}', // 简化文本
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                maxLines: 1,
              ),
              Text(
                category.subtitle,
                style: const TextStyle(
                  fontSize: 10, // 减小字体大小
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到文件夹页面
  void _navigateToFolderPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FolderPage(),
      ),
    );
  }

  /// 导航到艺术家页面
  void _navigateToArtistPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ArtistPage(),
      ),
    );
  }

  /// 导航到专辑页面
  void _navigateToAlbumPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AlbumPage(),
      ),
    );
  }

  /// 导航到歌曲页面
  void _navigateToSongsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SongsPage(),
      ),
    );
  }
}

/// 音乐统计信息类
class MusicStats {
  final int totalSongs;
  final int totalArtists;
  final int totalAlbums;
  final int totalFolders;
  final int totalDuration;
  final List<Song> songs;

  const MusicStats({
    required this.totalSongs,
    required this.totalArtists,
    required this.totalAlbums,
    required this.totalFolders,
    required this.totalDuration,
    required this.songs,
  });
}

/// 分类信息类
class _CategoryInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _CategoryInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.onTap,
  });
}
