import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';

/// 后台音频播放服务
/// 基于 just_audio_background 实现完整的后台播放功能
class BackgroundAudioService extends ChangeNotifier {
  late just_audio.AudioPlayer _audioPlayer;

  // 当前播放状态
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // 当前播放的歌曲
  Song? _currentSong;
  Song? get currentSong => _currentSong;

  // 播放列表
  List<Song> _playlist = [];
  List<Song> get playlist => _playlist;

  // 当前播放索引
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // 播放进度
  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  // 播放进度监听
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _currentIndexSubscription;

  BackgroundAudioService() {
    _init();
  }

  /// 初始化音频播放器
  void _init() {
    _audioPlayer = just_audio.AudioPlayer();

    // 监听播放进度
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      _position = position ?? Duration.zero;
      notifyListeners();
    });

    // 监听音频时长
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    // 监听播放状态变化
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == just_audio.ProcessingState.completed) {
        _onPlayComplete();
      }

      _isPlaying = state.playing;
      notifyListeners();
    });

    // 监听播放/暂停状态
    _playingSubscription = _audioPlayer.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    // 监听当前播放索引变化
    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
        _currentSong = _playlist[index];
        notifyListeners();
      }
    });
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _playlist = List.from(songs);
    _currentIndex = initialIndex.clamp(0, _playlist.length - 1);
    if (_playlist.isNotEmpty) {
      _currentSong = _playlist[_currentIndex];
    }

    await _setupBackgroundPlaylist();
    notifyListeners();
  }

  /// 设置后台播放队列
  Future<void> _setupBackgroundPlaylist() async {
    if (_playlist.isEmpty) return;

    try {
      final playlist = ConcatenatingAudioSource(
        children:
            _playlist
                .map(
                  (song) => AudioSource.uri(
                    Uri.file(song.path),
                    tag: MediaItem(
                      id: song.id.toString(),
                      album: song.album ?? 'Unknown Album',
                      title: song.title,
                      artist: song.artist ?? 'Unknown Artist',
                      artUri: song.albumArtUri,
                    ),
                  ),
                )
                .toList(),
      );

      await _audioPlayer.setAudioSource(playlist);
    } catch (e) {
      debugPrint('设置后台播放队列失败: $e');
    }
  }

  /// 播放指定歌曲
  Future<void> playSong(Song song) async {
    if (song.path.isEmpty) return;

    try {
      final songIndex = _playlist.indexWhere((s) => s.id == song.id);
      if (songIndex != -1) {
        _currentIndex = songIndex;
        _currentSong = song;
        await _audioPlayer.seek(Duration.zero, index: songIndex);
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('播放失败: $e');
    }
  }

  /// 播放当前歌曲
  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('播放失败: $e');
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('暂停失败: $e');
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('停止失败: $e');
    }
  }

  /// 上一首
  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    int newIndex = _currentIndex - 1;
    if (newIndex < 0) {
      newIndex = _playlist.length - 1;
    }

    _currentIndex = newIndex;
    _currentSong = _playlist[_currentIndex];
    await _audioPlayer.seek(Duration.zero, index: newIndex);
    if (!isPlaying) {
      await _audioPlayer.play();
    }
  }

  /// 下一首
  Future<void> next() async {
    if (_playlist.isEmpty) return;

    int newIndex = _currentIndex + 1;
    if (newIndex >= _playlist.length) {
      newIndex = 0;
    }

    _currentIndex = newIndex;
    _currentSong = _playlist[_currentIndex];
    await _audioPlayer.seek(Duration.zero, index: newIndex);
    if (!isPlaying) {
      await _audioPlayer.play();
    }
  }

  /// 设置播放进度
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('调整进度失败: $e');
    }
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0.0, 1.0);
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      debugPrint('设置音量失败: $e');
    }
  }

  /// 播放完成时的处理
  void _onPlayComplete() {
    // 播放完成后自动播放下一首
    if (_currentIndex < _playlist.length - 1) {
      next();
    }
  }

  /// 获取播放进度百分比
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  /// 释放资源
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _playingSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
