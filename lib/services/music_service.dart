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

  /// 获取所有本地歌曲
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
