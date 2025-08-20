import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../models/song.dart';
import '../widgets/song_item.dart';

/// 艺术家页面
/// 显示设备中的所有艺术家，点击艺术家可查看其所有歌曲
class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  List<Map<String, dynamic>> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  /// 加载艺术家数据
  Future<void> _loadArtists() async {
    try {
      final songs = await MusicService.getAllSongsWithoutArt();
      final artistMap = <String, List<Song>>{};

      // 按艺术家分组歌曲
      for (final song in songs) {
        final artist = song.artist.isNotEmpty ? song.artist : '未知艺术家';
        artistMap.putIfAbsent(artist, () => []).add(song);
      }

      // 转换为艺术家列表
      final artists = artistMap.entries.map((entry) => {
        'name': entry.key,
        'songs': entry.value,
        'count': entry.value.length,
        'albums': _countUniqueAlbums(entry.value),
      }).toList();

      // 按歌曲数量排序
      artists.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      setState(() {
        _artists = artists;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载艺术家失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 计算艺术家的专辑数量
  int _countUniqueAlbums(List<Song> songs) {
    final albums = <String>{};
    for (final song in songs) {
      if (song.album.isNotEmpty) {
        albums.add(song.album);
      }
    }
    return albums.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('歌手')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_artists.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('歌手')),
        body: const Center(child: Text('没有找到艺术家')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('歌手')),
      body: ListView.builder(
        itemCount: _artists.length,
        itemBuilder: (context, index) {
          final artist = _artists[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (artist['name'] as String).substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              artist['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${artist['albums']} 张专辑 · ${artist['count']} 首歌曲',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtistSongsPage(
                    artistName: artist['name'] as String,
                    songs: artist['songs'] as List<Song>,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 艺术家歌曲页面
/// 显示特定艺术家的所有歌曲
class ArtistSongsPage extends StatefulWidget {
  final String artistName;
  final List<Song> songs;

  const ArtistSongsPage({
    super.key,
    required this.artistName,
    required this.songs,
  });

  @override
  State<ArtistSongsPage> createState() => _ArtistSongsPageState();
}

class _ArtistSongsPageState extends State<ArtistSongsPage> {
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
        title: Text(widget.artistName),
      ),
      body: _isLoading && _songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(child: Text('该艺术家没有歌曲'))
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return SongItem(
                      song: song,
                      onTap: () {
                        // TODO: 实现播放功能
                      },
                    );
                  },
                ),
    );
  }
}
