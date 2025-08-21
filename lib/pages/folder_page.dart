import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../models/song.dart';
import '../widgets/song_item.dart';

/// 文件夹页面
/// 显示设备中的音乐文件夹结构，点击文件夹可查看其中的歌曲
class FolderPage extends StatefulWidget {
  const FolderPage({super.key});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<Map<String, dynamic>> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  /// 加载文件夹数据
  Future<void> _loadFolders() async {
    try {
      final songs = await MusicService.getAllSongsWithoutArt();
      final folderMap = <String, List<Song>>{};

      // 按文件夹路径分组歌曲
      for (final song in songs) {
        final path = song.path;
        final lastSlash = path.lastIndexOf('/');
        if (lastSlash > 0) {
          final folderPath = path.substring(0, lastSlash);
          folderMap.putIfAbsent(folderPath, () => []).add(song);
        }
      }

      // 转换为文件夹列表
      final folders =
          folderMap.entries
              .map(
                (entry) => {
                  'name': _getFolderName(entry.key),
                  'path': entry.key,
                  'count': entry.value.length,
                  'songs': entry.value,
                },
              )
              .toList();

      // 按歌曲数量排序
      folders.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载文件夹失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 获取文件夹显示名称
  String _getFolderName(String path) {
    final parts = path.split('/');
    // if (parts.length >= 2) {
    //   return '${parts[parts.length - 2]}/${parts.last}';
    // }
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('文件夹')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_folders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('文件夹')),
        body: const Center(child: Text('没有找到音乐文件夹')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('文件夹')),
      body: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final folder = _folders[index];
          return ListTile(
            leading: const Icon(Icons.folder, size: 40, color: Colors.amber),
            title: Text(
              folder['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${folder['count']} 首歌曲'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FolderSongsPage(
                        folderName: folder['name'] as String,
                        songs: folder['songs'] as List<Song>,
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

/// 文件夹歌曲页面
/// 显示特定文件夹中的所有歌曲
class FolderSongsPage extends StatelessWidget {
  final String folderName;
  final List<Song> songs;

  const FolderSongsPage({
    super.key,
    required this.folderName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(folderName)),
      body: songs.isEmpty
          ? const Center(child: Text('该文件夹暂无歌曲'))
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongItem(
                  song: song,
                  playlist: songs,
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
