import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'kanade_audio_plugin_method_channel.dart';

abstract class KanadeAudioPluginPlatform extends PlatformInterface {
  /// Constructs a KanadeAudioPluginPlatform.
  KanadeAudioPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static KanadeAudioPluginPlatform _instance = MethodChannelKanadeAudioPlugin();

  /// The default instance of [KanadeAudioPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelKanadeAudioPlugin].
  static KanadeAudioPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KanadeAudioPluginPlatform] when
  /// they register themselves.
  static set instance(KanadeAudioPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// 初始化音频播放器
  Future<void> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<Map<String, dynamic>> songs, {int initialIndex = 0}) {
    throw UnimplementedError('setPlaylist() has not been implemented.');
  }

  /// 播放指定歌曲
  Future<void> playSong(Map<String, dynamic> song) {
    throw UnimplementedError('playSong() has not been implemented.');
  }

  /// 播放当前歌曲
  Future<void> play() {
    throw UnimplementedError('play() has not been implemented.');
  }

  /// 暂停播放
  Future<void> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// 停止播放
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// 上一首
  Future<void> previous() {
    throw UnimplementedError('previous() has not been implemented.');
  }

  /// 下一首
  Future<void> next() {
    throw UnimplementedError('next() has not been implemented.');
  }

  /// 设置播放进度
  Future<void> seek(int positionMilliseconds) {
    throw UnimplementedError('seek() has not been implemented.');
  }

  /// 设置音量
  Future<void> setVolume(double volume) {
    throw UnimplementedError('setVolume() has not been implemented.');
  }

  /// 切换播放模式
  Future<void> togglePlayMode() {
    throw UnimplementedError('togglePlayMode() has not been implemented.');
  }

  /// 获取当前播放状态
  Future<int> getPlayerState() {
    throw UnimplementedError('getPlayerState() has not been implemented.');
  }

  /// 获取当前播放歌曲
  Future<Map<String, dynamic>?> getCurrentSong() {
    throw UnimplementedError('getCurrentSong() has not been implemented.');
  }

  /// 获取播放进度
  Future<int> getPosition() {
    throw UnimplementedError('getPosition() has not been implemented.');
  }

  /// 获取音频时长
  Future<int> getDuration() {
    throw UnimplementedError('getDuration() has not been implemented.');
  }

  /// 获取音量
  Future<double> getVolume() {
    throw UnimplementedError('getVolume() has not been implemented.');
  }

  /// 获取播放模式
  Future<int> getPlayMode() {
    throw UnimplementedError('getPlayMode() has not been implemented.');
  }

  /// 获取播放列表
  Future<List<dynamic>> getPlaylist() {
    throw UnimplementedError('getPlaylist() has not been implemented.');
  }

  /// 获取专辑封面（通过歌曲ID）
  Future<Uint8List?> getAlbumArt(int songId) {
    throw UnimplementedError('getAlbumArt() has not been implemented.');
  }

  /// 加载专辑封面
  Future<void> loadAlbumArt(int songId) {
    throw UnimplementedError('loadAlbumArt() has not been implemented.');
  }

  /// 释放资源
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  /// 获取设备中所有歌曲
  Future<List<dynamic>> getAllSongs() {
    throw UnimplementedError('getAllSongs() has not been implemented.');
  }

  /// 获取专辑封面（通过专辑ID）
  Future<Uint8List?> getAlbumArtByAlbumId(int albumId) {
    throw UnimplementedError('getAlbumArtByAlbumId() has not been implemented.');
  }

  /// 监听播放状态变化
  Stream<int> get onPlayerStateChanged {
    throw UnimplementedError('onPlayerStateChanged has not been implemented.');
  }

  /// 监听播放进度变化
  Stream<int> get onPositionChanged {
    throw UnimplementedError('onPositionChanged has not been implemented.');
  }

  /// 监听当前歌曲变化
  Stream<Map<String, dynamic>?> get onCurrentSongChanged {
    throw UnimplementedError('onCurrentSongChanged has not been implemented.');
  }
}
