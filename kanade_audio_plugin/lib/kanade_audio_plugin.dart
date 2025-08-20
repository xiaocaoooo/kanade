
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'kanade_audio_plugin_platform_interface.dart';

/// 音频播放状态枚举
enum PlayerState { stopped, playing, paused, loading, error }

/// 播放模式枚举
enum PlayMode {
  sequence, // 顺序播放
  repeatOne, // 单曲循环
  repeatAll, // 列表循环
  shuffle, // 随机播放
}

/// 歌曲模型类
class PluginSong {
  final int id;
  final String title;
  final String? artist;
  final String? album;
  final Duration duration;
  final String path;
  final int? size;
  final Uint8List? albumArt;
  final int? albumId;
  final DateTime? dateAdded;
  final DateTime? dateModified;

  const PluginSong({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.duration,
    required this.path,
    this.size,
    this.albumArt,
    this.albumId,
    this.dateAdded,
    this.dateModified,
  });

  /// 从 Map 创建 PluginSong 对象
  factory PluginSong.fromMap(Map<String, dynamic> map) {
    return PluginSong(
      id: map['id'] as int,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      duration: Duration(milliseconds: map['duration'] as int),
      path: map['path'] as String,
      size: map['size'] as int?,
      albumArt: map['albumArt'] as Uint8List?,
      albumId: map['albumId'] as int?,
      dateAdded: map['dateAdded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateAdded'] as int)
          : null,
      dateModified: map['dateModified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateModified'] as int)
          : null,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration.inMilliseconds,
      'path': path,
      'size': size,
      'albumArt': albumArt,
      'albumId': albumId,
      'dateAdded': dateAdded?.millisecondsSinceEpoch,
      'dateModified': dateModified?.millisecondsSinceEpoch,
    };
  }
}

/// 音频播放插件主类
/// 提供完整的音频播放功能，包括播放控制、进度管理、音量控制等
class KanadeAudioPlugin {
  /// 获取平台版本
  Future<String?> getPlatformVersion() {
    return KanadeAudioPluginPlatform.instance.getPlatformVersion();
  }

  /// 初始化音频播放器
  Future<void> initialize() {
    return KanadeAudioPluginPlatform.instance.initialize();
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<PluginSong> songs, {int initialIndex = 0}) {
    return KanadeAudioPluginPlatform.instance.setPlaylist(
      songs.map((song) => song.toMap()).toList(),
      initialIndex: initialIndex,
    );
  }

  /// 播放指定歌曲
  Future<void> playSong(PluginSong song) {
    return KanadeAudioPluginPlatform.instance.playSong(song.toMap());
  }

  /// 播放当前歌曲
  Future<void> play() {
    return KanadeAudioPluginPlatform.instance.play();
  }

  /// 暂停播放
  Future<void> pause() {
    return KanadeAudioPluginPlatform.instance.pause();
  }

  /// 停止播放
  Future<void> stop() {
    return KanadeAudioPluginPlatform.instance.stop();
  }

  /// 上一首
  Future<void> previous() {
    return KanadeAudioPluginPlatform.instance.previous();
  }

  /// 下一首
  Future<void> next() {
    return KanadeAudioPluginPlatform.instance.next();
  }

  /// 设置播放进度
  Future<void> seek(Duration position) {
    return KanadeAudioPluginPlatform.instance.seek(position.inMilliseconds);
  }

  /// 设置音量
  Future<void> setVolume(double volume) {
    return KanadeAudioPluginPlatform.instance.setVolume(volume);
  }

  /// 切换播放模式
  Future<void> togglePlayMode() {
    return KanadeAudioPluginPlatform.instance.togglePlayMode();
  }

  /// 获取当前播放状态
  Future<PlayerState> getPlayerState() async {
    final stateIndex = await KanadeAudioPluginPlatform.instance.getPlayerState();
    return PlayerState.values[stateIndex];
  }

  /// 获取当前播放歌曲
  Future<PluginSong?> getCurrentSong() async {
    final songMap = await KanadeAudioPluginPlatform.instance.getCurrentSong();
    return songMap != null ? PluginSong.fromMap(songMap) : null;
  }

  /// 获取播放进度
  Future<Duration> getPosition() async {
    final milliseconds = await KanadeAudioPluginPlatform.instance.getPosition();
    return Duration(milliseconds: milliseconds);
  }

  /// 获取音频时长
  Future<Duration> getDuration() async {
    final milliseconds = await KanadeAudioPluginPlatform.instance.getDuration();
    return Duration(milliseconds: milliseconds);
  }

  /// 获取音量
  Future<double> getVolume() {
    return KanadeAudioPluginPlatform.instance.getVolume();
  }

  /// 获取播放模式
  Future<PlayMode> getPlayMode() async {
    final modeIndex = await KanadeAudioPluginPlatform.instance.getPlayMode();
    return PlayMode.values[modeIndex];
  }

  /// 获取播放列表
  Future<List<PluginSong>> getPlaylist() async {
    final songs = await KanadeAudioPluginPlatform.instance.getPlaylist();
    return songs.map((song) => PluginSong.fromMap(song as Map<String, dynamic>)).toList();
  }

  /// 获取专辑封面
  Future<Uint8List?> getAlbumArt(int songId) {
    return KanadeAudioPluginPlatform.instance.getAlbumArt(songId);
  }

  /// 加载专辑封面
  Future<void> loadAlbumArt(int songId) {
    return KanadeAudioPluginPlatform.instance.loadAlbumArt(songId);
  }

  /// 释放资源
  Future<void> dispose() {
    return KanadeAudioPluginPlatform.instance.dispose();
  }

  /// 获取设备中所有歌曲
  Future<List<PluginSong>> getAllSongs() async {
    final songsJson = await KanadeAudioPluginPlatform.instance.getAllSongs();
    final songsList = List.from(songsJson as List);
    return songsList.map((song) => PluginSong.fromMap(Map<String, dynamic>.from(song as Map))).toList();
  }

  /// 获取专辑封面
  Future<Uint8List?> getAlbumArtByAlbumId(int albumId) async {
    return await KanadeAudioPluginPlatform.instance.getAlbumArtByAlbumId(albumId);
  }

  /// 监听播放状态变化
  Stream<PlayerState> get onPlayerStateChanged {
    return KanadeAudioPluginPlatform.instance.onPlayerStateChanged.map((state) => PlayerState.values[state]);
  }

  /// 监听播放进度变化
  Stream<Duration> get onPositionChanged {
    return KanadeAudioPluginPlatform.instance.onPositionChanged.map((ms) => Duration(milliseconds: ms));
  }

  /// 监听当前歌曲变化
  Stream<PluginSong?> get onCurrentSongChanged {
    return KanadeAudioPluginPlatform.instance.onCurrentSongChanged.map(
      (songMap) => songMap != null ? PluginSong.fromMap(songMap) : null
    );
  }
}
