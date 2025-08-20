import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_service.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/cover_cache_service.dart';
import '../widgets/song_item.dart';

/// 搜索页面
/// 支持搜索歌曲、艺术家、专辑，使用分割后的艺术家数据
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _allSongs = [];
  List<Song> _searchResults = [];
  List<Map<String, dynamic>> _artistResults = [];
  List<Map<String, dynamic>> _albumResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
    _searchController.addListener(_onSearchChanged);
  }

  /// 加载所有歌曲数据用于搜索
  Future<void> _loadAllSongs() async {
    try {
      _allSongs = await MusicService.getAllSongsWithoutArt();
    } catch (e) {
      debugPrint('加载歌曲数据失败: $e');
    }
  }

  /// 搜索文本变化时的处理
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _artistResults.clear();
        _albumResults.clear();
        _hasSearched = false;
      });
      return;
    }
    _performSearch(query);
  }

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    if (_allSongs.isEmpty) {
      await _loadAllSongs();
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final lowerQuery = query.toLowerCase();

      // 搜索歌曲
      _searchResults = _allSongs.where((song) {
        return song.title.toLowerCase().contains(lowerQuery) ||
               song.artists.any((artist) => artist.toLowerCase().contains(lowerQuery)) ||
               song.album.toLowerCase().contains(lowerQuery);
      }).toList();

      // 搜索艺术家（使用分割后的艺术家数据）
      final artistMap = <String, List<Song>>{};
      for (final song in _allSongs) {
        for (final artist in song.artists) {
          if (artist.toLowerCase().contains(lowerQuery)) {
            artistMap.putIfAbsent(artist, () => []).add(song);
          }
        }
      }
      
      _artistResults = artistMap.entries
          .map((entry) => {
                'name': entry.key,
                'songs': entry.value,
                'count': entry.value.length,
                'albums': _countUniqueAlbums(entry.value),
              })
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // 搜索专辑
      final albumMap = <String, Map<String, dynamic>>{};
      for (final song in _allSongs) {
        if (song.album.toLowerCase().contains(lowerQuery)) {
          albumMap.putIfAbsent(song.album, () => {
            'name': song.album,
            'songs': <Song>[],
            'artists': <String>{},
          });
          albumMap[song.album]!['songs'].add(song);
          albumMap[song.album]!['artists'].addAll(song.artists);
        }
      }
      
      _albumResults = albumMap.entries
          .map((entry) => {
                'name': entry.key,
                'songs': entry.value['songs'],
                'count': entry.value['songs'].length,
                'artists': (entry.value['artists'] as Set<String>).toList()..sort(),
              })
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    } catch (e) {
      debugPrint('搜索失败: $e');
    } finally {
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

  /// 清除搜索
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _artistResults.clear();
      _albumResults.clear();
      _hasSearched = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索音乐'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: '搜索歌曲、艺术家、专辑...',
              leading: const Icon(Icons.search, color: Colors.grey),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: _clearSearch,
                  ),
              ],
              onChanged: (_) {},
              onSubmitted: (_) {},
            ),
          ),
          
          // 搜索结果
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('输入关键词开始搜索', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _artistResults.isEmpty && _albumResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('未找到匹配的内容', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 歌曲结果
          if (_searchResults.isNotEmpty) ...[
            const Text('歌曲', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._searchResults.take(5).map((song) => _buildSongItem(song)),
            if (_searchResults.length > 5)
              TextButton(
                onPressed: () => _showAllSongs(),
                child: Text('查看全部 ${_searchResults.length} 首歌曲'),
              ),
            const SizedBox(height: 24),
          ],

          // 艺术家结果
          if (_artistResults.isNotEmpty) ...[
            const Text('艺术家', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._artistResults.take(3).map((artist) => _buildArtistItem(artist)),
            if (_artistResults.length > 3)
              TextButton(
                onPressed: () => _showAllArtists(),
                child: Text('查看全部 ${_artistResults.length} 位艺术家'),
              ),
            const SizedBox(height: 24),
          ],

          // 专辑结果
          if (_albumResults.isNotEmpty) ...[
            const Text('专辑', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._albumResults.take(3).map((album) => _buildAlbumItem(album)),
            if (_albumResults.length > 3)
              TextButton(
                onPressed: () => _showAllAlbums(),
                child: Text('查看全部 ${_albumResults.length} 张专辑'),
              ),
          ],
        ],
      ),
    );
  }

  /// 构建歌曲项
  Widget _buildSongItem(Song song) {
    final albumId = song.albumId;
    final hasAlbumId = albumId != null && albumId.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildSongCover(song, hasAlbumId ? albumId : ''),
        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${song.artists.join(", ")} • ${song.album}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.play_arrow, color: Colors.grey),
        onTap: () => _playSong(song),
      ),
    );
  }

  /// 构建歌曲封面
  Widget _buildSongCover(Song song, String albumId) {
    if (albumId.isEmpty) {
      return _buildDefaultCover();
    }

    final cover = CoverCacheManager.instance.getCover(albumId);
    final isLoading = CoverCacheManager.instance.isLoading(albumId);

    if (cover != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          cover,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
        ),
      );
    }

    if (isLoading) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 如果缓存中没有且未在加载，异步加载封面
    _loadSongCover(song);
    return _buildDefaultCover();
  }

  /// 构建默认封面
  Widget _buildDefaultCover() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, size: 20, color: Colors.grey),
    );
  }

  /// 异步加载歌曲封面
  Future<void> _loadSongCover(Song song) async {
    final albumId = song.albumId;
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

  /// 构建艺术家项
  Widget _buildArtistItem(Map<String, dynamic> artist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            artist['name'].substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(artist['name']),
        subtitle: Text('${artist['count']} 首歌曲 • ${artist['albums']} 张专辑'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showArtistSongs(artist),
      ),
    );
  }

  /// 构建专辑项
  Widget _buildAlbumItem(Map<String, dynamic> album) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.album, color: Colors.grey),
        title: Text(album['name']),
        subtitle: Text('${album['count']} 首歌曲 • ${album['artists'].join(", ")}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAlbumSongs(album),
      ),
    );
  }

  /// 播放歌曲
  Future<void> _playSong(Song song) async {
    final audioPlayerService = Provider.of<AudioPlayerService>(context, listen: false);
    await audioPlayerService.setPlaylist(_searchResults);
    await audioPlayerService.playSong(song);
  }

  /// 显示艺术家歌曲
  void _showArtistSongs(Map<String, dynamic> artist) {
    // 这里可以导航到艺术家详情页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('显示 ${artist['name']} 的歌曲')),
    );
  }

  /// 显示专辑歌曲
  void _showAlbumSongs(Map<String, dynamic> album) {
    // 这里可以导航到专辑详情页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('显示 ${album['name']} 的歌曲')),
    );
  }

  /// 显示所有歌曲结果
  void _showAllSongs() {
    // 这里可以导航到完整歌曲列表页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('显示全部 ${_searchResults.length} 首歌曲')),
    );
  }

  /// 显示所有艺术家结果
  void _showAllArtists() {
    // 这里可以导航到完整艺术家列表页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('显示全部 ${_artistResults.length} 位艺术家')),
    );
  }

  /// 显示所有专辑结果
  void _showAllAlbums() {
    // 这里可以导航到完整专辑列表页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('显示全部 ${_albumResults.length} 张专辑')),
    );
  }
}
