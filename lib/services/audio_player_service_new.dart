import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kanade_audio_plugin/kanade_audio_plugin.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final KanadeAudioPlugin _audioPlugin = KanadeAudioPlugin();

  List<Song> _playlist = [];
  Song? _currentSong;
  PlayerState _playerState = PlayerState.stopped;
  int _position = 0;
  int _duration = 0;
  double _volume = 1.0;
  PlayMode _playMode = PlayMode.sequence;

  List<Song> get playlist => _playlist;
  Song? get currentSong => _currentSong;
  PlayerState get playerState => _playerState;
  int get position => _position;
  int get duration => _duration;
  double get volume => _volume;
  PlayMode get playMode => _playMode;

  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isStopped => _playerState == PlayerState.stopped;

  AudioPlayerService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _audioPlugin.initialize();

    // 监听状态变化
    _audioPlugin.onPlayerStateChanged.listen((data) {
      _playerState = data['state'] as PlayerState;
      _position = data['position'] as int;
      _duration = data['duration'] as int;
      notifyListeners();
    });

    _audioPlugin.onPositionChanged.listen((data) {
      _position = data['position'] as int;
      _duration = data['duration'] as int;
      notifyListeners();
    });

    _audioPlugin.onCurrentSongChanged.listen((song) {
      _currentSong = song;
      notifyListeners();
    });
  }

  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _playlist = List.from(songs);
    await _audioPlugin.setPlaylist(
      songs.map((song) => song.toMap()).toList(),
      initialIndex: initialIndex,
    );
    notifyListeners();
  }

  Future<void> playSong(Song song) async {
    await _audioPlugin.playSong(song);
    notifyListeners();
  }

  Future<void> play() async {
    await _audioPlugin.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlugin.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioPlugin.stop();
    notifyListeners();
  }

  Future<void> previous() async {
    await _audioPlugin.previous();
    notifyListeners();
  }

  Future<void> next() async {
    await _audioPlugin.next();
    notifyListeners();
  }

  Future<void> seek(int position) async {
    await _audioPlugin.seek(position);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlugin.setVolume(_volume);
    notifyListeners();
  }

  Future<void> togglePlayMode() async {
    await _audioPlugin.togglePlayMode();
    _playMode = await _audioPlugin.getPlayMode();
    notifyListeners();
  }

  Future<Uint8List?> getAlbumArt(Song song) async {
    return await _audioPlugin.getAlbumArt(song.id);
  }

  Future<Uint8List?> loadAlbumArt(Song song) async {
    return await _audioPlugin.loadAlbumArt(song.id);
  }

  void dispose() {
    // 插件会自动处理清理
  }
}
