import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kanade_audio_plugin/kanade_audio_plugin.dart' as plugin;
import '../models/song.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _initialize();
  }

  final plugin.KanadeAudioPlugin _audioPlugin = plugin.KanadeAudioPlugin();

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  List<Song> _playlist = [];
  Song? _currentSong;
  plugin.PlayerState _playerState = plugin.PlayerState.stopped;
  Duration _position = Duration.zero;
  final Duration _duration = Duration.zero;
  double _volume = 1.0;
  plugin.PlayMode _playMode = plugin.PlayMode.sequence;

  List<Song> get playlist => _playlist;
  Song? get currentSong => _currentSong;
  plugin.PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  plugin.PlayMode get playMode => _playMode;

  bool get isPlaying => _playerState == plugin.PlayerState.playing;
  bool get isPaused => _playerState == plugin.PlayerState.paused;
  bool get isStopped => _playerState == plugin.PlayerState.stopped;

  Future<void> _initialize() async {
    await _audioPlugin.initialize();

    // 监听状态变化
    _audioPlugin.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    _audioPlugin.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    // _durationSubscription = // 不需要单独的duration监听，duration会在状态变化时一起提供

    _audioPlugin.onCurrentSongChanged.listen((song) {
      if (song != null) {
        _currentSong = Song(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist ?? '',
          album: song.album ?? '',
          duration: song.duration.inMilliseconds,
          path: song.path,
          size: song.size ?? 0,
          albumId: song.albumId?.toString(),
          dateAdded: DateTime.now(),
          dateModified: DateTime.now(),
        );
      } else {
        _currentSong = null;
      }
      notifyListeners();
    });
  }

  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _playlist = List.from(songs);
    _currentSong = songs.isNotEmpty ? songs[initialIndex] : null;
    
    // 将Song列表转换为PluginSong列表
    final pluginSongs = songs.map((song) => plugin.PluginSong(
      id: int.tryParse(song.id) ?? 0,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      path: song.path,
      size: song.size,
      albumArt: null,
      albumId: song.albumId != null ? int.tryParse(song.albumId!) : null,
    )).toList();
    
    await _audioPlugin.setPlaylist(pluginSongs, initialIndex: initialIndex);
    notifyListeners();
  }

  Future<void> playSong(Song song) async {
    _currentSong = song;
    
    final pluginSong = plugin.PluginSong(
      id: int.tryParse(song.id) ?? 0,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      path: song.path,
      size: song.size,
      albumArt: null,
      albumId: song.albumId != null ? int.tryParse(song.albumId!) : null,
    );
    
    await _audioPlugin.playSong(pluginSong);
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

  Future<void> seek(Duration position) async {
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

  Future<Uint8List?> getAlbumArtForSong(Song song) async {
    return await _audioPlugin.getAlbumArt(int.tryParse(song.id) ?? 0);
  }

  Future<void> loadAlbumArtForSong(Song song) async {
    await _audioPlugin.loadAlbumArt(int.tryParse(song.id) ?? 0);
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }
}
