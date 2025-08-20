import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/media_notification_service.dart';

/// 音乐播放器页面
/// 提供完整的播放控制界面，包括播放/暂停、进度条、音量控制等
class PlayerPage extends StatefulWidget {
  final Song? initialSong;
  final List<Song>? playlist;

  const PlayerPage({
    Key? key,
    this.initialSong,
    this.playlist,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late AudioPlayerService _playerService;

  @override
  void initState() {
    super.initState();    
    // 使用Provider提供的全局音频服务
    _playerService = Provider.of<AudioPlayerService>(context, listen: false);
    
    // 延迟初始化，避免在构建过程中调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  void _initializePlayer() {
    // 设置播放列表并播放初始歌曲
    if (widget.playlist != null && widget.initialSong != null) {
      // 找到初始歌曲在播放列表中的索引
      final initialIndex = widget.playlist!.indexWhere(
        (song) => song.id == widget.initialSong!.id
      );
      
      // 设置播放列表并指定初始索引
      _playerService.setPlaylist(
        widget.playlist!,
        initialIndex: initialIndex != -1 ? initialIndex : 0
      );
      
      // 播放当前歌曲
      _playerService.play();
    } else if (widget.playlist != null) {
      // 只设置播放列表，不自动播放
      _playerService.setPlaylist(widget.playlist!);
    } else if (widget.initialSong != null) {
      // 只有单首歌曲，创建包含该歌曲的播放列表
      _playerService.setPlaylist([widget.initialSong!]);
      _playerService.play();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _playerService,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('正在播放'),
          actions: [
            IconButton(
              icon: const Icon(Icons.queue_music),
              onPressed: () => _showPlaylistDialog(),
            ),
          ],
        ),
        body: Consumer<AudioPlayerService>(
          builder: (context, player, child) {
            if (player.currentSong == null) {
              return const Center(
                child: Text('暂无播放歌曲'),
              );
            }

            return Column(
              children: [
                // 专辑封面区域
                _buildAlbumCover(player.currentSong!),
                
                // 歌曲信息
                _buildSongInfo(player.currentSong!),
                
                // 播放进度
                _buildProgressControls(),
                
                // 播放控制
                _buildPlaybackControls(),
                
                // 音量控制
                _buildVolumeControls(),
                
                // 播放模式控制
                _buildModeControls(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 构建专辑封面
  Widget _buildAlbumCover(Song song) {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        final albumArt = player.getAlbumArtForSong(song);
        
        // 异步加载封面
        if (albumArt == null && song.albumId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            player.loadAlbumArtForSong(song);
          });
        }
        
        return Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Hero(
              tag: 'album-${song.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: albumArt != null
                      ? Image.memory(
                          albumArt,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.music_note,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建歌曲信息
  Widget _buildSongInfo(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text(
            song.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            song.artist,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            song.album,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建进度控制
  Widget _buildProgressControls() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Theme.of(context).colorScheme.primary,
                  overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                ),
                child: Slider(
                  value: player.progress,
                  onChanged: (value) {
                    final newPosition = Duration(
                      milliseconds: (value * player.duration.inMilliseconds).toInt(),
                    );
                    player.seek(newPosition);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(player.position),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      _formatDuration(player.duration),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建播放控制
  Widget _buildPlaybackControls() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 32,
              onPressed: player.previous,
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                player.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
                color: Colors.white,
              ),
              onPressed: () {
                if (player.isPlaying) {
                  player.pause();
                } else {
                  player.play();
                }
              },
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 32,
              onPressed: player.next,
            ),
          ],
        );
      },
    );
  }

  /// 构建音量控制
  Widget _buildVolumeControls() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            children: [
              const Icon(Icons.volume_down, size: 20),
              Expanded(
                child: Slider(
                  value: player.volume,
                  onChanged: (value) => player.setVolume(value),
                  min: 0.0,
                  max: 1.0,
                ),
              ),
              const Icon(Icons.volume_up, size: 20),
            ],
          ),
        );
      },
    );
  }

  /// 构建播放模式控制
  Widget _buildModeControls() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(player.playModeIcon),
              onPressed: player.togglePlayMode,
              tooltip: _getPlayModeTooltip(player.playMode),
            ),
          ],
        );
      },
    );
  }

  /// 显示播放列表对话框
  void _showPlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('播放列表'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _playerService.playlist.length,
              itemBuilder: (context, index) {
                final song = _playerService.playlist[index];
                final albumArt = _playerService.getAlbumArtForSong(song);
                
                // 异步加载封面
                if (albumArt == null && song.albumId != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _playerService.loadAlbumArtForSong(song);
                  });
                }
                
                return ListTile(
                  leading: albumArt != null
                      ? Image.memory(albumArt, width: 40, height: 40)
                      : const Icon(Icons.music_note),
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  selected: index == _playerService.currentIndex,
                  onTap: () {
                    _playerService.setPlaylist(_playerService.playlist, initialIndex: index);
                    _playerService.play();
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  /// 获取播放模式提示
  String _getPlayModeTooltip(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return '顺序播放';
      case PlayMode.repeatOne:
        return '单曲循环';
      case PlayMode.repeatAll:
        return '列表循环';
      case PlayMode.shuffle:
        return '随机播放';
    }
  }
}
