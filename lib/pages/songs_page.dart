import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../utils/permission_helper.dart';
import 'player_page.dart';

/// 歌曲列表页面
/// 展示设备中所有本地歌曲的完整信息
class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  Future<List<Song>>? _songsFuture;
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  bool _isSearching = false;
  bool _isLoadingCovers = false;
  int _loadedCoversCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载本地歌曲数据
  Future<void> _loadSongs() async {
    // 检查并请求权限
    final hasPermission = await PermissionHelper.checkMediaPermissions();
    if (!hasPermission) {
      final granted = await PermissionHelper.requestMediaPermissions();
      if (!granted) {
        if (mounted) {
          PermissionHelper.showPermissionDeniedDialog(context);
        }
        setState(() {
          _songsFuture = Future.value([]);
        });
        return;
      }
    }

    // 先加载歌曲基本信息（不包含封面）
    setState(() {
      _songsFuture = MusicService.getAllSongsWithoutArt();
    });

    final songs = await _songsFuture ?? [];
    setState(() {
      _allSongs = songs;
      _filteredSongs = songs;
    });

    // 异步加载专辑封面
    _loadAlbumArts();
  }

  /// 异步加载专辑封面（实时更新）
  Future<void> _loadAlbumArts() async {
    if (_allSongs.isEmpty) return;

    setState(() {
      _isLoadingCovers = true;
      _loadedCoversCount = 0;
    });

    await MusicService.loadAlbumArtsWithCallback(
      _allSongs,
      (updatedSongs) {
        if (mounted) {
          setState(() {
            _allSongs = updatedSongs;
            _filteredSongs = MusicService.searchSongs(_allSongs, _searchController.text.trim());
            _loadedCoversCount = updatedSongs.where((song) => song.albumArt != null).length;
            if (_loadedCoversCount >= _allSongs.length) {
              _isLoadingCovers = false;
            }
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isLoadingCovers = false;
      });
    }
  }

  /// 处理搜索变化
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _filteredSongs = MusicService.searchSongs(_allSongs, query);
    });
  }

  /// 播放歌曲
  void _playSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerPage(
          initialSong: song,
          playlist: _allSongs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: '搜索歌曲、艺术家或专辑...',
                    border: InputBorder.none,
                  ),
                  autofocus: true,
                )
                : const Text('本地音乐'),
        actions: [
          if (_isLoadingCovers && !_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_loadedCoversCount/${_allSongs.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _isSearching = false;
                  _filteredSongs = _allSongs;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSongs,
        child: FutureBuilder<List<Song>>(
          future: _songsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '加载失败: ${snapshot.error}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSongs,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }

            final songs = _filteredSongs;
            if (songs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isEmpty ? '没有找到本地音乐' : '没有找到匹配的结果',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (_searchController.text.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '请确保设备中有音乐文件',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return _buildSongItem(song);
              },
            );
          },
        ),
      ),
    );
  }

  /// 构建歌曲列表项
  Widget _buildSongItem(Song song) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        child: song.albumArt != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(
                  song.albumArt!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.music_note, size: 24);
                  },
                ),
              )
            : const Icon(Icons.music_note, size: 24),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${song.artist} • ${song.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            song.formattedDuration,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            song.formattedSize,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
      onTap: () {
        _playSong(song);
      },
    );
  }
}
