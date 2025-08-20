import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'kanade_audio_plugin_platform_interface.dart';

/// An implementation of [KanadeAudioPluginPlatform] that uses method channels.
class MethodChannelKanadeAudioPlugin extends KanadeAudioPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kanade_audio_plugin');

  /// 事件通道用于监听播放状态变化
  final _playerStateChannel = const EventChannel('kanade_audio_plugin/player_state');
  
  /// 事件通道用于监听播放进度变化
  final _positionChannel = const EventChannel('kanade_audio_plugin/position');
  
  /// 事件通道用于监听当前歌曲变化
  final _currentSongChannel = const EventChannel('kanade_audio_plugin/current_song');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> initialize() async {
    await methodChannel.invokeMethod('initialize');
  }

  @override
  Future<void> setPlaylist(List<Map<String, dynamic>> songs, {int initialIndex = 0}) async {
    await methodChannel.invokeMethod('setPlaylist', {
      'songs': songs,
      'initialIndex': initialIndex,
    });
  }

  @override
  Future<void> playSong(Map<String, dynamic> song) async {
    await methodChannel.invokeMethod('playSong', song);
  }

  @override
  Future<void> play() async {
    await methodChannel.invokeMethod('play');
  }

  @override
  Future<void> pause() async {
    await methodChannel.invokeMethod('pause');
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod('stop');
  }

  @override
  Future<void> previous() async {
    await methodChannel.invokeMethod('previous');
  }

  @override
  Future<void> next() async {
    await methodChannel.invokeMethod('next');
  }

  @override
  Future<void> seek(int positionMilliseconds) async {
    await methodChannel.invokeMethod('seek', {'position': positionMilliseconds});
  }

  @override
  Future<void> setVolume(double volume) async {
    await methodChannel.invokeMethod('setVolume', {'volume': volume});
  }

  @override
  Future<void> togglePlayMode() async {
    await methodChannel.invokeMethod('togglePlayMode');
  }

  @override
  Future<int> getPlayerState() async {
    return await methodChannel.invokeMethod('getPlayerState') ?? 0;
  }

  @override
  Future<Map<String, dynamic>?> getCurrentSong() async {
    return await methodChannel.invokeMethod('getCurrentSong');
  }

  @override
  Future<int> getPosition() async {
    return await methodChannel.invokeMethod('getPosition') ?? 0;
  }

  @override
  Future<int> getDuration() async {
    return await methodChannel.invokeMethod('getDuration') ?? 0;
  }

  @override
  Future<double> getVolume() async {
    return await methodChannel.invokeMethod('getVolume') ?? 1.0;
  }

  @override
  Future<int> getPlayMode() async {
    return await methodChannel.invokeMethod('getPlayMode') ?? 0;
  }

  @override
  Future<List<dynamic>> getPlaylist() async {
    return await methodChannel.invokeMethod('getPlaylist') ?? [];
  }

  @override
  Future<Uint8List?> getAlbumArt(int songId) async {
    return await methodChannel.invokeMethod('getAlbumArt', {'songId': songId});
  }

  @override
  Future<void> loadAlbumArt(int songId) async {
    await methodChannel.invokeMethod('loadAlbumArt', {'songId': songId});
  }

  @override
  Future<void> dispose() async {
    await methodChannel.invokeMethod('dispose');
  }

  @override
  Future<List<dynamic>> getAllSongs() async {
    return await methodChannel.invokeMethod('getAllSongs') ?? [];
  }

  @override
  Future<Uint8List?> getAlbumArtByAlbumId(int albumId) async {
    return await methodChannel.invokeMethod('getAlbumArtByAlbumId', {'albumId': albumId.toString()});
  }

  @override
  Stream<int> get onPlayerStateChanged {
    return _playerStateChannel.receiveBroadcastStream().cast<int>();
  }

  @override
  Stream<int> get onPositionChanged {
    return _positionChannel.receiveBroadcastStream().cast<int>();
  }

  @override
  Stream<Map<String, dynamic>?> get onCurrentSongChanged {
    return _currentSongChannel.receiveBroadcastStream().cast<Map<String, dynamic>?>();
  }
}
