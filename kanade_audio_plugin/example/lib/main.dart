import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:kanade_audio_plugin/kanade_audio_plugin.dart';
import 'media_service_test.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final KanadeAudioPlugin _audioPlugin = KanadeAudioPlugin();
  
  PlayerState _playerState = PlayerState.stopped;
  Song? _currentSong;
  int _position = 0;
  int _duration = 0;
  double _volume = 1.0;
  PlayMode _playMode = PlayMode.sequence;
  
  List<Song> _playlist = [];
  Uint8List? _albumArt;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _audioPlugin.initialize();
    
    // 创建示例播放列表
    _playlist = [
      Song(
        id: 1,
        title: '示例歌曲 1',
        artist: '艺术家 1',
        album: '专辑 1',
        path: '/storage/emulated/0/Music/sample1.mp3',
        duration: 180000,
        albumId: 1,
      ),
      Song(
        id: 2,
        title: '示例歌曲 2',
        artist: '艺术家 2',
        album: '专辑 2',
        path: '/storage/emulated/0/Music/sample2.mp3',
        duration: 240000,
        albumId: 2,
      ),
    ];

    // 监听状态变化
    _audioPlugin.onPlayerStateChanged.listen((data) {
      if (mounted) {
        setState(() {
          _playerState = data['state'] as PlayerState;
          _position = data['position'] as int;
          _duration = data['duration'] as int;
        });
      }
    });

    _audioPlugin.onPositionChanged.listen((data) {
      if (mounted) {
        setState(() {
          _position = data['position'] as int;
          _duration = data['duration'] as int;
        });
      }
    });

    _audioPlugin.onCurrentSongChanged.listen((song) async {
      if (mounted && song != null) {
        setState(() {
          _currentSong = song;
        });
        
        // 加载专辑封面
        final albumArt = await _audioPlugin.getAlbumArt(song.id);
        if (mounted) {
          setState(() {
            _albumArt = albumArt;
          });
        }
      }
    });

    // 设置播放列表
    await _audioPlugin.setPlaylist(_playlist, initialIndex: 0);
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getPlayModeText() {
    switch (_playMode) {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kanade Audio Plugin Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.library_music),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MediaServiceTestPage(),
                  ),
                );
              },
              tooltip: '媒体服务测试',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_albumArt != null)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: MemoryImage(_albumArt!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, size: 100),
                ),
              const SizedBox(height: 20),
              Text(
                _currentSong?.title ?? '未选择歌曲',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                _currentSong?.artist ?? '未知艺术家',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Slider(
                value: _duration > 0 ? _position.toDouble() : 0,
                max: _duration.toDouble(),
                onChanged: (value) {
                  _audioPlugin.seek(value.toInt());
                },
              ),
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 40,
                    onPressed: () => _audioPlugin.previous(),
                  ),
                  IconButton(
                    icon: Icon(
                      _playerState == PlayerState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    iconSize: 50,
                    onPressed: () {
                      if (_playerState == PlayerState.playing) {
                        _audioPlugin.pause();
                      } else {
                        _audioPlugin.play();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 40,
                    onPressed: () => _audioPlugin.next(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('音量:'),
                  Slider(
                    value: _volume,
                    max: 1.0,
                    onChanged: (value) {
                      setState(() {
                        _volume = value;
                      });
                      _audioPlugin.setVolume(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _audioPlugin.togglePlayMode();
                  final mode = await _audioPlugin.getPlayMode();
                  setState(() {
                    _playMode = mode;
                  });
                },
                child: Text('播放模式: ${_getPlayModeText()}'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _playlist.length,
                  itemBuilder: (context, index) {
                    final song = _playlist[index];
                    return ListTile(
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _audioPlugin.playSong(song),
                      ),
                      selected: _currentSong?.id == song.id,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
