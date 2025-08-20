import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_service.dart';
import '../services/audio_player_service.dart';
import '../models/song.dart';
import '../widgets/song_item.dart';

/// 专辑页面
/// 显示设备中的所有专辑，点击专辑可查看其中的歌曲
class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  List<Map<String, dynamic>> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  /// 加载专辑数据
  Future<void> _loadAlbums() async {
    try {
      final songs = await MusicService.getAllSongsWithoutArt();
      final albumMap = <String, List<Song>>{};

      // 按专辑分组歌曲
      for (final song in songs) {
        final album = song.album.isNotEmpty ? song.album : '未知专辑';
        albumMap.putIfAbsent(album, () => []).add(song);
      }

      // 转换为专辑列表
      final albums = albumMap.entries.map((entry) => {
        'title': entry.key,
        'artist': _getAlbumArtist(entry.value),
        'year': _getAlbumYear(entry.value),
        'songs': entry.value,
        'count': entry.value.length,
      }).toList();

      // 按歌曲数量排序
      albums.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载专辑失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 获取专辑艺术家（取第一首歌的艺术家）
  String _getAlbumArtist(List<Song> songs) {
    if (songs.isEmpty) return '未知艺术家';
    return songs.first.artist.isNotEmpty ? songs.first.artist : '未知艺术家';
  }

  /// 获取专辑年份（从文件路径或元数据推断）
  int _getAlbumYear(List<Song> songs) {
    if (songs.isEmpty) return 0;
    // 这里可以扩展为从音频文件的元数据中获取年份
    // 目前返回一个默认值
    return 2024;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('专辑')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_albums.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('专辑')),
        body: const Center(child: Text('没有找到专辑')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('专辑')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _albums.length,
        itemBuilder: (context, index) {
          final album = _albums[index];
          return Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumSongsPage(
                      albumName: album['title'] as String,
                      artistName: album['artist'] as String,
                      songs: album['songs'] as List<Song>,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.album,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          album['artist'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${album['year']} · ${album['count']} 首',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 专辑歌曲页面
/// 显示特定专辑中的所有歌曲
class AlbumSongsPage extends StatefulWidget {
  final String albumName;
  final String artistName;
  final List<Song> songs;

  const AlbumSongsPage({
    super.key,
    required this.albumName,
    required this.artistName,
    required this.songs,
  });

  @override
  State<AlbumSongsPage> createState() => _AlbumSongsPageState();
}

class _AlbumSongsPageState extends State<AlbumSongsPage> {
  late List<Song> _songs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _songs = widget.songs;
    _loadAlbumArts();
  }

  /// 异步加载专辑封面
  Future<void> _loadAlbumArts() async {
    if (_songs.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await MusicService.loadAlbumArtsWithCallback(
      _songs,
      (updatedSongs) {
        if (mounted) {
          setState(() {
            _songs = updatedSongs;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.albumName),
            Text(
              widget.artistName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading && _songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(child: Text('该专辑中没有歌曲'))
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return SongItem(
                      song: song,
                      playlist: _songs,
                      play: true,
                      onLongPress: () => _showSongMenu(context, song),
                    );
                  },
                ),
    );
  }



  void _showSongMenu(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('播放'),
              onTap: () {
                Navigator.pop(context);
                // SongItem会自动处理播放和跳转
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_to_queue),
              title: const Text('添加到播放队列'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现添加到队列功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('歌曲信息'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现查看歌曲信息
              },
            ),
          ],
        ),
      ),
    );
  }
}
