import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';

/// 音乐服务类
/// 负责访问设备媒体库，获取和管理本地歌曲数据
/// 
/// 使用原生Android MediaStore API实现真实的媒体库访问
class MusicService {
  static const MethodChannel _channel = MethodChannel('media_service');

  /// 获取所有本地歌曲（包含封面）
  /// 从设备媒体库查询音频文件并转换为Song对象列表
  /// 同时获取每个歌曲的专辑封面
  static Future<List<Song>> getAllSongs() async {
    try {
      debugPrint('正在获取本地歌曲...');
      
      final String result = await _channel.invokeMethod('getAllSongs');
      final List<dynamic> jsonList = jsonDecode(result);
      
      // 并行获取所有专辑封面
      final songs = await Future.wait(
        jsonList.map((json) async {
          final albumId = json['albumId']?.toString();
          Uint8List? albumArt;
          
          if (albumId != null && albumId.isNotEmpty) {
            albumArt = await getAlbumArt(albumId);
          }
          
          return Song.fromMap(json, albumArt: albumArt);
        }),
      );
      
      return songs;
    } on PlatformException catch (e) {
      debugPrint('获取歌曲列表时出错: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('获取歌曲列表时出错: $e');
      return [];
    }
  }

  /// 获取所有本地歌曲（不包含封面）
  /// 先获取歌曲基本信息，提高加载速度
  static Future<List<Song>> getAllSongsWithoutArt() async {
    try {
      debugPrint('正在获取本地歌曲基本信息...');
      
      final String result = await _channel.invokeMethod('getAllSongs');
      final List<dynamic> jsonList = jsonDecode(result);
      
      // 不获取专辑封面，直接创建Song对象（albumId已包含在fromMap中）
      final songs = jsonList.map((json) => Song.fromMap(json, albumArt: null)).toList();
      
      return songs;
    } on PlatformException catch (e) {
      debugPrint('获取歌曲列表时出错: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('获取歌曲列表时出错: $e');
      return [];
    }
  }

  /// 为歌曲列表异步加载封面图片（实时更新）
  static Future<void> loadAlbumArtsWithCallback(
    List<Song> songs, 
    Function(List<Song>) onSongUpdated
  ) async {
    try {
      debugPrint('开始异步加载专辑封面...');
      
      final updatedSongs = List<Song>.from(songs);
      final albumIdsToLoad = <int, String>{};
      
      // 收集需要加载封面的歌曲索引和albumId
      for (int i = 0; i < updatedSongs.length; i++) {
        final albumId = updatedSongs[i].albumId;
        if (albumId != null && albumId.isNotEmpty) {
          albumIdsToLoad[i] = albumId;
        }
      }
      
      if (albumIdsToLoad.isEmpty) return;
      
      // 使用Future.wait并行加载，但限制并发数量
      final batchSize = 3; // 每次并行加载3个封面
      final batches = <List<MapEntry<int, String>>>[];
      
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
            final albumArt = await getAlbumArt(albumId);
            if (albumArt != null && albumArt.isNotEmpty) {
              updatedSongs[index] = Song(
                id: updatedSongs[index].id,
                title: updatedSongs[index].title,
                artist: updatedSongs[index].artist,
                album: updatedSongs[index].album,
                duration: updatedSongs[index].duration,
                path: updatedSongs[index].path,
                size: updatedSongs[index].size,
                albumArt: albumArt,
                albumId: albumId,
                dateAdded: updatedSongs[index].dateAdded,
                dateModified: updatedSongs[index].dateModified,
              );
              
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
      
      final Uint8List? result = await _channel.invokeMethod(
        'getAlbumArt',
        {'albumId': albumId},
      );
      
      return result;
    } on PlatformException catch (e) {
      debugPrint('获取专辑封面时出错: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('获取专辑封面时出错: $e');
      return null;
    }
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
