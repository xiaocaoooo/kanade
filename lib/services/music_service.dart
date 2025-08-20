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
      debugPrint('开始异步加载专辑封面... 共${songs.length}首歌曲');
      
      final updatedSongs = List<Song>.from(songs);
      final albumIdsToLoad = <int, int>{};
      
      // 收集需要加载封面的歌曲索引和albumId，并去重
      final loadedAlbumIds = <int>{}; // 避免重复加载相同的专辑
      for (int i = 0; i < updatedSongs.length; i++) {
        final albumId = updatedSongs[i].albumId;
        if (albumId != null && albumId.isNotEmpty) {
          final intAlbumId = int.tryParse(albumId);
          if (intAlbumId != null && !loadedAlbumIds.contains(intAlbumId)) {
            albumIdsToLoad[i] = intAlbumId;
            loadedAlbumIds.add(intAlbumId);
          }
        }
      }
      
      if (albumIdsToLoad.isEmpty) {
        debugPrint('没有需要加载的专辑封面');
        return;
      }
      
      debugPrint('需要加载${albumIdsToLoad.length}个专辑封面');
      
      // 使用更合理的并发控制
      final batchSize = 5; // 增加并发数量以提高速度
      final entries = albumIdsToLoad.entries.toList();
      
      // 分批处理，每批最多5个
      for (int i = 0; i < entries.length; i += batchSize) {
        final batch = entries.skip(i).take(batchSize).toList();
        
        // 并行处理当前批次
        final results = await Future.wait(
          batch.map((entry) async {
            final index = entry.key;
            final albumId = entry.value;
            
            try {
              final albumArt = await _audioPlugin.getAlbumArtByAlbumId(albumId);
              return MapEntry(index, albumArt);
            } catch (e) {
              debugPrint('加载专辑封面失败: albumId=$albumId, error=$e');
              return MapEntry(index, null);
            }
          }),
          eagerError: false, // 即使某些失败也继续
        );
        
        // 批量更新结果
        bool hasUpdates = false;
        for (final result in results) {
          final index = result.key;
          final albumArt = result.value;
          
          if (albumArt != null && albumArt.isNotEmpty) {
            updatedSongs[index] = updatedSongs[index].copyWith(albumArt: albumArt);
            hasUpdates = true;
          }
        }
        
        // 批量更新UI
        if (hasUpdates) {
          onSongUpdated(List.from(updatedSongs));
        }
        
        // 小延迟避免系统过载
        await Future.delayed(const Duration(milliseconds: 50));
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
      if (intId == null) {
        debugPrint('专辑ID格式无效: $albumId');
        return null;
      }
      
      final Uint8List? result = await _audioPlugin.getAlbumArtByAlbumId(intId);
      
      // 记录结果
      if (result != null) {
        debugPrint('成功获取专辑封面: $albumId (${result.length} bytes)');
      } else {
        debugPrint('专辑封面不存在: $albumId');
      }
      
      return result;
    } catch (e) {
      debugPrint('获取专辑封面时出错: $albumId - $e');
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
