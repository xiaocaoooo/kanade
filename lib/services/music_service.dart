import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kanade_audio_plugin/kanade_audio_plugin.dart' as plugin;
import '../models/song.dart';

/// 音乐服务类
/// 负责访问设备媒体库，获取和管理本地歌曲数据
/// 
/// 使用kanade_audio_plugin实现媒体库访问
class MusicService {
  /// 使用kanade_audio_plugin实现媒体库访问
  static final plugin.KanadeAudioPlugin _audioPlugin = plugin.KanadeAudioPlugin();

  /// 获取所有本地歌曲（包含封面）
  /// 从设备媒体库查询音频文件并转换为Song对象列表
  /// 获取所有本地歌曲
  static Future<List<Song>> getAllSongs() async {
    try {
      debugPrint('正在获取本地歌曲...');
      
      final pluginSongs = await _audioPlugin.getAllSongs();
      debugPrint('成功获取歌曲数据，数量: ${pluginSongs.length}');
      
      // 将 plugin.PluginSong 转换为 Song
      final songs = pluginSongs.map((pluginSong) => Song(
        id: pluginSong.id.toString(),
        title: pluginSong.title,
        artist: pluginSong.artist ?? '',
        album: pluginSong.album ?? '',
        duration: pluginSong.duration.inMilliseconds,
        path: pluginSong.path,
        size: pluginSong.size ?? 0,
        albumArt: pluginSong.albumArt,
        albumId: pluginSong.albumId?.toString() ?? '',
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      )).toList();
      
      // 并行获取所有专辑封面
      final songsWithArt = await Future.wait(
        songs.map((song) async {
          if (song.albumId?.isNotEmpty == true) {
            final albumId = int.tryParse(song.albumId!);
            if (albumId != null) {
              final albumArt = await _audioPlugin.getAlbumArtByAlbumId(albumId);
              return song.copyWith(albumArt: albumArt);
            }
          }
          return song;
        }),
      );
      
      return songsWithArt;
    } catch (e) {
      debugPrint('获取歌曲列表时出错: $e');
      return [];
    }
  }

  /// 获取所有本地歌曲（不包含封面）
  /// 先获取歌曲基本信息，提高加载速度
  static Future<List<Song>> getAllSongsWithoutArt() async {
    debugPrint('正在获取本地歌曲基本信息...');
    
    final pluginSongs = await _audioPlugin.getAllSongs();
    return pluginSongs.map((pluginSong) => Song(
      id: pluginSong.id.toString(),
      title: pluginSong.title,
      artist: pluginSong.artist ?? '',
      album: pluginSong.album ?? '',
      duration: pluginSong.duration.inMilliseconds,
      path: pluginSong.path,
      size: pluginSong.size ?? 0,
      albumArt: pluginSong.albumArt,
      albumId: pluginSong.albumId?.toString() ?? '',
      dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
    )).toList();
  }

  /// 为歌曲列表异步加载封面图片（实时更新）
  static Future<void> loadAlbumArtsWithCallback(
    List<Song> songs, 
    Function(List<Song>) onSongUpdated
  ) async {
    try {
      debugPrint('开始异步加载专辑封面...');
      
      final updatedSongs = List<Song>.from(songs);
      final albumIdsToLoad = <int, int>{};
      
      // 收集需要加载封面的歌曲索引和albumId
      for (int i = 0; i < updatedSongs.length; i++) {
        final albumId = updatedSongs[i].albumId;
        if (albumId != null && albumId.isNotEmpty) {
          final intAlbumId = int.tryParse(albumId);
          if (intAlbumId != null) {
            albumIdsToLoad[i] = intAlbumId;
          }
        }
      }
      
      if (albumIdsToLoad.isEmpty) return;
      
      // 使用Future.wait并行加载，但限制并发数量
      final batchSize = 3; // 每次并行加载3个封面
      final batches = <List<MapEntry<int, int>>>[];
      
      // 分批处理
      final entries = albumIdsToLoad.entries.toList();
      for (int i = 0; i < entries.length; i += batchSize) {
        batches.add(
          entries.skip(i).take(batchSize).toList(),
        );
      }
      
      // 逐批并行加载
      for (final batch in batches) {
        final futures = batch.map((entry) async {
          final index = entry.key;
          final albumId = entry.value;
          
          try {
            final albumArt = await _audioPlugin.getAlbumArtByAlbumId(albumId);
            if (albumArt != null && albumArt.isNotEmpty) {
              updatedSongs[index] = updatedSongs[index].copyWith(albumArt: albumArt);
              
              // 每获取到一个封面就立即回调更新UI
              onSongUpdated(List.from(updatedSongs));
            }
          } catch (e) {
            debugPrint('加载单个封面失败: $e');
            // 单个封面加载失败不影响其他封面
          }
        });
        
        await Future.wait(futures);
      }
      
      debugPrint('专辑封面加载完成');
    } catch (e) {
      debugPrint('加载专辑封面时出错: $e');
    }
  }

  /// 根据专辑ID获取专辑封面
  /// 返回专辑封面的字节数据
  static Future<Uint8List?> getAlbumArt(String albumId) async {
    try {
      debugPrint('正在获取专辑封面: $albumId');
      
      final intId = int.tryParse(albumId);
      if (intId == null) return null;
      
      final Uint8List? result = await _audioPlugin.getAlbumArtByAlbumId(intId);
      return result;
    } catch (e) {
      debugPrint('获取专辑封面时出错: $e');
      return null;
    }
  }

  /// 为单个歌曲加载专辑封面
  static Future<Uint8List?> loadAlbumArtForSong(Song song) async {
    if (song.albumId == null || song.albumId!.isEmpty) {
      return null;
    }
    
    return await getAlbumArt(song.albumId!);
  }

  /// 按艺术家分组歌曲
  /// 返回Map，key为艺术家名称，value为该艺术家的歌曲列表
  static Map<String, List<Song>> groupSongsByArtist(List<Song> songs) {
    final Map<String, List<Song>> artistMap = {};
    for (final song in songs) {
      final artist = song.artist.trim();
      if (artist.isEmpty) continue;
      
      if (!artistMap.containsKey(artist)) {
        artistMap[artist] = [];
      }
      artistMap[artist]!.add(song);
    }
    return artistMap;
  }

  /// 按专辑分组歌曲
  /// 返回Map，key为专辑名称，value为该专辑的歌曲列表
  static Map<String, List<Song>> groupSongsByAlbum(List<Song> songs) {
    final Map<String, List<Song>> albumMap = {};
    for (final song in songs) {
      final album = song.album.trim();
      if (album.isEmpty) continue;
      
      if (!albumMap.containsKey(album)) {
        albumMap[album] = [];
      }
      albumMap[album]!.add(song);
    }
    return albumMap;
  }

  /// 搜索歌曲
  /// 根据关键词在标题、艺术家、专辑中搜索匹配的歌曲
  static List<Song> searchSongs(List<Song> songs, String query) {
    if (query.isEmpty) return songs;
    
    final lowerQuery = query.toLowerCase();
    return songs.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
             song.artist.toLowerCase().contains(lowerQuery) ||
             song.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
