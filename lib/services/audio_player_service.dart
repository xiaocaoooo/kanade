import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';
import 'music_service.dart';
import 'settings_service.dart';

/// 音频播放状态枚举
enum PlayerState { stopped, playing, paused, loading, error }

/// 播放模式枚举
enum PlayMode {
  sequence, // 顺序播放
  repeatOne, // 单曲循环
  repeatAll, // 列表循环
  shuffle, // 随机播放
}

/// 音频播放服务类
/// 提供完整的音频播放功能，包括播放控制、进度管理、音量控制等
/// 这是一个全局单例服务，确保音频播放在应用生命周期内保持连续性
class AudioPlayerService extends ChangeNotifier {
  late just_audio.AudioPlayer _audioPlayer;

  // 当前播放状态
  PlayerState _playerState = PlayerState.stopped;
  PlayerState get playerState => _playerState;

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

  // 音量控制 (0.0 - 1.0)
  double _volume = 1.0;
  double get volume => _volume;

  // 播放模式
  PlayMode _playMode = PlayMode.repeatAll;
  PlayMode get playMode => _playMode;

  // 播放进度监听
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _currentIndexSubscription;

  // 专辑封面缓存
  final Map<String, Uint8List?> _albumArtCache = {};
  
  // 保存状态的防抖计时器
  Timer? _saveStateTimer;

  AudioPlayerService() {
    _init();
  }

  /// 初始化音频播放器
  void _init() {
    _audioPlayer = just_audio.AudioPlayer();

    _audioPlayer.setLoopMode(just_audio.LoopMode.all);
    _audioPlayer.setShuffleModeEnabled(false);

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

      // 更新播放状态
      if (state.playing) {
        _playerState = PlayerState.playing;
      } else if (state.processingState == just_audio.ProcessingState.loading) {
        _playerState = PlayerState.loading;
      } else if (state.processingState == just_audio.ProcessingState.ready) {
        if (_playerState != PlayerState.playing) {
          _playerState = PlayerState.paused;
        }
      } else {
        // 处理错误状态和其他状态
        if (state.processingState == just_audio.ProcessingState.idle ||
            state.processingState == just_audio.ProcessingState.completed) {
          // 正常状态，不做处理
        } else {
          _playerState = PlayerState.error;
        }
      }
      notifyListeners();
      
      // 播放状态变化时保存状态
      _saveStateDebounced();
    });

    // 监听播放/暂停状态
    _playingSubscription = _audioPlayer.playingStream.listen((playing) {
      if (playing) {
        _playerState = PlayerState.playing;
      } else {
        _playerState = PlayerState.paused;
      }
      notifyListeners();
      
      // 播放/暂停状态变化时保存状态
      _saveStateDebounced();
    });

    // 监听当前播放索引变化
    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
        _currentSong = _playlist[index];
        notifyListeners();
        
        // 播放索引变化时保存状态
        _saveStateDebounced();
      }
    });
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    _playlist = List.from(songs);
    _currentIndex = initialIndex.clamp(0, _playlist.length - 1);
    if (_currentIndex >= _playlist.length) {
      _currentIndex = 0;
    }

    if (_playlist.isNotEmpty) {
      _currentSong = _playlist[_currentIndex];
    }

    try {
      await _setupBackgroundPlaylist(initialIndex: _currentIndex);
      notifyListeners();
      _saveStateImmediately(); // 播放列表变化时立即保存
    } catch (e) {
      debugPrint('设置播放列表失败: $e');
      _playerState = PlayerState.error;
      notifyListeners();
    }
  }

  /// 设置后台播放队列
  Future<void> _setupBackgroundPlaylist({int initialIndex = 0}) async {
    if (_playlist.isEmpty) return;

    try {
      final playlist = just_audio.ConcatenatingAudioSource(
        children:
            _playlist
                .map(
                  (song) => just_audio.AudioSource.uri(
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

      await _audioPlayer.setAudioSource(playlist, initialIndex: initialIndex);
    } catch (e) {
      debugPrint('设置后台播放队列失败: $e');
    }
  }

  /// 播放指定歌曲
  Future<void> playSong(Song song) async {
    // if (song.path.isEmpty) {
    //   _playerState = PlayerState.error;
    //   notifyListeners();
    //   return;
    // }

    try {
      _playerState = PlayerState.loading;
      notifyListeners();

      // 找到歌曲在播放列表中的索引
      final songIndex = _playlist.indexWhere((s) => s.id == song.id);
      if (songIndex != -1) {
        _currentIndex = songIndex;
        _currentSong = song;

        // 确保音频播放器处于正确的索引位置
        if (_audioPlayer.currentIndex != songIndex) {
          await _audioPlayer.seek(Duration.zero, index: songIndex);
        } else {
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.play();
        _playerState = PlayerState.playing;
      }

      notifyListeners();
    } catch (e) {
      _playerState = PlayerState.error;
      debugPrint('播放失败: $e');
      notifyListeners();
    }
  }

  /// 播放当前歌曲
  Future<void> play() async {
    if (_currentSong == null) return;

    try {
      if (_playerState == PlayerState.paused) {
        await _audioPlayer.play();
        _playerState = PlayerState.playing;
      } else {
        await playSong(_currentSong!);
      }
      notifyListeners();
    } catch (e) {
      _playerState = PlayerState.error;
      debugPrint('播放失败: $e');
      notifyListeners();
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    if (_playerState != PlayerState.playing) return;

    try {
      await _audioPlayer.pause();
      _playerState = PlayerState.paused;
      notifyListeners();
    } catch (e) {
      debugPrint('暂停失败: $e');
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint('停止失败: $e');
    }
  }

  /// 上一首
  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    int newIndex;
    switch (_playMode) {
      case PlayMode.shuffle:
        newIndex = _getRandomIndex();
        break;
      default:
        newIndex = _currentIndex - 1;
        if (newIndex < 0) {
          newIndex = _playlist.length - 1;
        }
        break;
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

    int newIndex;
    switch (_playMode) {
      case PlayMode.shuffle:
        newIndex = _getRandomIndex();
        break;
      case PlayMode.repeatOne:
        newIndex = _currentIndex;
        break;
      default:
        newIndex = _currentIndex + 1;
        if (newIndex >= _playlist.length) {
          newIndex = 0;
        }
        break;
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
      _position = position;
      notifyListeners();
      _saveStateDebounced(); // 播放进度变化时保存状态
    } catch (e) {
      debugPrint('调整进度失败: $e');
    }
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0.0, 1.0);
    try {
      await _audioPlayer.setVolume(volume);
      _volume = volume;
      notifyListeners();
      _saveStateDebounced(); // 音量变化时保存状态
    } catch (e) {
      debugPrint('设置音量失败: $e');
    }
  }

  /// 切换播放模式（列表循环 -> 单曲循环 -> 随机播放 -> 列表循环）
  void togglePlayMode() {
    const modes = [PlayMode.repeatAll, PlayMode.repeatOne, PlayMode.shuffle];
    final currentIndex = modes.indexOf(_playMode);
    _playMode = modes[(currentIndex + 1) % modes.length];
    // 将状态同时设置到 _audioPlayer
    _audioPlayer.setLoopMode(
      _playMode == PlayMode.repeatOne
          ? just_audio.LoopMode.one
          : just_audio.LoopMode.all,
    );
    _audioPlayer.setShuffleModeEnabled(_playMode == PlayMode.shuffle);

    notifyListeners();
    _saveStateImmediately(); // 播放模式变化立即保存
  }

  /// 切换随机播放模式
  void toggleShuffleMode() {
    if (_playMode == PlayMode.shuffle) {
      _playMode = PlayMode.sequence;
    } else {
      _playMode = PlayMode.shuffle;
    }
    notifyListeners();
  }

  /// 检查是否处于随机播放模式
  bool get isShuffleMode => _playMode == PlayMode.shuffle;

  /// 播放完成时的处理
  void _onPlayComplete() async {
    switch (_playMode) {
      case PlayMode.repeatOne:
        // 单曲循环，重新播放当前歌曲
        await playSong(_currentSong!);
        break;
      case PlayMode.repeatAll:
        // 列表循环，播放下一首
        await next();
        break;
      case PlayMode.sequence:
        // 顺序播放，如果到最后一首则停止
        if (_currentIndex < _playlist.length - 1) {
          await next();
        } else {
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
          notifyListeners();
        }
        break;
      case PlayMode.shuffle:
        // 随机播放
        await next();
        break;
    }
  }

  /// 获取随机索引（用于随机播放）
  int _getRandomIndex() {
    if (_playlist.length <= 1) return 0;

    int randomIndex;
    do {
      randomIndex =
          (DateTime.now().millisecondsSinceEpoch % _playlist.length).toInt();
    } while (randomIndex == _currentIndex);

    return randomIndex;
  }

  /// 获取播放进度百分比
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  /// 是否正在播放
  bool get isPlaying => _playerState == PlayerState.playing;

  /// 是否已暂停
  bool get isPaused => _playerState == PlayerState.paused;

  /// 是否已停止
  bool get isStopped => _playerState == PlayerState.stopped;

  /// 获取播放模式图标
  IconData get playModeIcon {
    switch (_playMode) {
      case PlayMode.repeatAll:
        return Icons.repeat;
      case PlayMode.repeatOne:
        return Icons.repeat_one;
      case PlayMode.shuffle:
        return Icons.shuffle;
      default:
        return Icons.repeat;
    }
  }

  /// 检查是否有保存的播放状态
  static Future<bool> hasSavedPlaylistState() async {
    final state = await SettingsService.loadPlaylistState();
    return state != null && state['playlist'] != null && (state['playlist'] as List).isNotEmpty;
  }

  /// 保存当前播放状态
  Future<void> savePlaylistState() async {
    if (_playlist.isEmpty || _currentSong == null) {
      // 如果播放列表为空，清除保存的状态
      await SettingsService.clearPlaylistState();
      return;
    }

    try {
      // 获取当前播放进度
      final currentPosition = _position.inMilliseconds;
      
      // 构建播放状态数据
      final state = {
        'playlist': _playlist.map((song) => song.toJson()).toList(),
        'currentIndex': _currentIndex,
        'playMode': _playMode.toString().split('.').last,
        'position': currentPosition,
        'isPlaying': isPlaying,
        'volume': _volume,
      };

      await SettingsService.savePlaylistState(state);
      debugPrint('播放状态已保存: ${_playlist.length}首歌曲，当前索引: $_currentIndex');
    } catch (e) {
      debugPrint('保存播放状态失败: $e');
    }
  }

  /// 恢复播放状态
  Future<bool> restorePlaylistState() async {
    try {
      final state = await SettingsService.loadPlaylistState();
      if (state == null) {
        debugPrint('没有找到保存的播放状态');
        return false;
      }

      // 解析播放列表
      final playlistData = List<Map<String, dynamic>>.from(state['playlist'] as List);
      final restoredPlaylist = playlistData.map((data) => Song.fromJson(data)).toList();

      if (restoredPlaylist.isEmpty) {
        debugPrint('恢复的播放列表为空');
        return false;
      }

      // 解析其他状态
      final currentIndex = (state['currentIndex'] as int).clamp(0, restoredPlaylist.length - 1);
      final playModeStr = state['playMode'] as String;
      final position = state['position'] as int;
      final isPlaying = state['isPlaying'] as bool;
      final volume = (state['volume'] as num).toDouble();

      // 设置播放模式
      switch (playModeStr) {
        case 'sequence':
          _playMode = PlayMode.sequence;
          break;
        case 'repeatOne':
          _playMode = PlayMode.repeatOne;
          break;
        case 'repeatAll':
          _playMode = PlayMode.repeatAll;
          break;
        case 'shuffle':
          _playMode = PlayMode.shuffle;
          break;
        default:
          _playMode = PlayMode.repeatAll;
      }

      // 设置播放列表和状态
      _playlist = restoredPlaylist;
      _currentIndex = currentIndex;
      _currentSong = _playlist[_currentIndex];
      _volume = volume.clamp(0.0, 1.0);

      // 设置音频播放器
      await _setupBackgroundPlaylist(initialIndex: currentIndex);
      await _audioPlayer.setVolume(_volume);
      
      // 设置播放模式
      _audioPlayer.setLoopMode(
        _playMode == PlayMode.repeatOne ? just_audio.LoopMode.one : just_audio.LoopMode.all,
      );
      _audioPlayer.setShuffleModeEnabled(_playMode == PlayMode.shuffle);

      // 设置播放进度
      if (position > 0) {
        await _audioPlayer.seek(Duration(milliseconds: position));
      }

      // 如果需要继续播放
      if (isPlaying) {
        await _audioPlayer.play();
      }

      notifyListeners();
      debugPrint('播放状态已恢复: ${_playlist.length}首歌曲，当前索引: $_currentIndex');
      return true;
    } catch (e) {
      debugPrint('恢复播放状态失败: $e');
      return false;
    }
  }

  /// 防抖保存播放状态
  void _saveStateDebounced() {
    _saveStateTimer?.cancel();
    _saveStateTimer = Timer(const Duration(seconds: 1), () {
      savePlaylistState();
    });
  }

  /// 立即保存播放状态（不防抖）
  void _saveStateImmediately() {
    _saveStateTimer?.cancel();
    savePlaylistState();
  }

  /// 释放资源
  @override
  void dispose() {
    // 在释放资源前保存播放状态
    _saveStateImmediately();
    
    _saveStateTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _playingSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 获取歌曲的专辑封面
  Uint8List? getAlbumArtForSong(Song song) {
    if (song.albumId == null) {
      final albumArtUri = song.albumArtUri;
      final file = File.fromUri(albumArtUri!);
      if (file.existsSync()) {
        return file.readAsBytesSync();
      }
    }
    return _albumArtCache[song.albumId];
  }

  /// 异步加载歌曲的专辑封面
  Future<void> loadAlbumArtForSong(Song song) async {
    if (song.albumId == null || _albumArtCache.containsKey(song.albumId)) {
      return;
    }

    try {
      final albumArt = await MusicService.loadAlbumArtForSong(song);
      _albumArtCache[song.albumId!] = albumArt;

      debugPrint('缓存专辑封面: ${song.albumId} (${albumArt?.length ?? 0} bytes)');

      // 如果这是当前播放的歌曲，更新封面
      if (_currentSong?.id == song.id) {
        // 创建一个新的Song对象，包含加载的封面
        _currentSong = Song(
          id: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album,
          duration: song.duration,
          path: song.path,
          size: song.size,
          // albumArt: albumArt ?? song.albumArt,
          albumId: song.albumId,
          dateAdded: song.dateAdded,
          dateModified: song.dateModified,
        );

        // 更新播放列表中的对应歌曲
        final index = _playlist.indexWhere((s) => s.id == song.id);
        if (index != -1) {
          _playlist[index] = _currentSong!;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载专辑封面失败: ${song.title} - $e');
      _albumArtCache[song.albumId!] = null; // 缓存null避免重复尝试
    }
  }
}
