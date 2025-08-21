import 'package:flutter/material.dart';
import 'package:kanade_audio_plugin/kanade_audio_plugin.dart';

/// 媒体服务测试页面
/// 用于测试kanade_audio_plugin的媒体服务功能
class MediaServiceTestPage extends StatefulWidget {
  const MediaServiceTestPage({super.key});

  @override
  State<MediaServiceTestPage> createState() => _MediaServiceTestPageState();
}

class _MediaServiceTestPageState extends State<MediaServiceTestPage> {
  final KanadeAudioPlugin _audioPlugin = KanadeAudioPlugin();
  List<Song> _songs = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  /// 加载设备中的歌曲
  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final songs = await _audioPlugin.getAllSongs();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载歌曲失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// 加载专辑封面
  Future<void> _loadAlbumArt(int albumId) async {
    try {
      final albumArt = await _audioPlugin.getAlbumArt(albumId);
      if (albumArt != null) {
        // 显示专辑封面
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('专辑封面'),
            content: Image.memory(albumArt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载专辑封面失败: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('媒体服务测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSongs,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSongs,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_songs.isEmpty) {
      return const Center(child: Text('没有找到歌曲'));
    }

    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return ListTile(
          leading: song.albumId != null
              ? GestureDetector(
                  onTap: () => _loadAlbumArt(song.albumId!),
                  child: const Icon(Icons.album),
                )
              : const Icon(Icons.music_note),
          title: Text(song.title),
          subtitle: Text('${song.artist ?? '未知艺术家'} - ${song.album ?? '未知专辑'}'),
          trailing: Text(
            _formatDuration(song.duration),
          ),
        );
      },
    );
  }

  /// 格式化时长显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
