import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../utils/permission_helper.dart';
import '../widgets/song_item.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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

    // 加载歌曲
    setState(() {
      _songsFuture = MusicService.getAllSongs();
    });

    final songs = await _songsFuture ?? [];
    setState(() {
      _allSongs = songs;
      _filteredSongs = songs;
    });
  }

  /// 处理搜索变化
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _filteredSongs = MusicService.searchSongs(_allSongs, query);
    });
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
              controller: _scrollController,
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongItem(song: song, playlist: songs, play: true);
              },
            );
          },
        ),
      ),
    );
  }
}
