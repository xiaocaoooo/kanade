import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 设置服务类
/// 管理应用的各种用户设置，包括艺术家分隔符配置
class SettingsService {
  static const String _artistSeparatorsKey = 'artist_separators';
  static const String _artistWhitelistKey = 'artist_whitelist';
  static const String _folderWhitelistKey = 'folder_whitelist';
  static const String _playlistStateKey = 'playlist_state';

  /// 默认艺术家分隔符列表，按优先级排序
  static const List<String> _defaultSeparators = [
    '/',
    '、',
    '&',
    ',',
    '，',
    ';',
    '；',
  ];

  /// 默认艺术家白名单
  static const List<String> _defaultWhitelist = [
    'Leo/need',
    'YOASOBI',
    '40mP',
    'DECO*27',
    'kemu',
  ];

  /// 缓存的分隔符列表
  static List<String> _cachedSeparators = [];

  /// 缓存的艺术家白名单
  static List<String> _cachedWhitelist = [];

  /// 缓存的文件夹白名单
  static Map<String, bool> _cachedFolderWhitelist = {};

  /// 初始化设置服务
  static Future<void> init() async {
    _cachedSeparators = await getArtistSeparators();
    _cachedWhitelist = await getArtistWhitelist();
    _cachedFolderWhitelist = await getFolderWhitelist();
  }

  /// 获取配置的艺术家分隔符列表
  static Future<List<String>> getArtistSeparators() async {
    final prefs = await SharedPreferences.getInstance();
    final separatorsString = prefs.getString(_artistSeparatorsKey);

    if (separatorsString == null || separatorsString.isEmpty) {
      return List.from(_defaultSeparators);
    }

    return separatorsString.split('|');
  }

  /// 同步获取艺术家分隔符列表（用于Song构造函数）
  static List<String> getArtistSeparatorsSync() {
    if (_cachedSeparators.isEmpty) {
      return List.from(_defaultSeparators);
    }
    return List.from(_cachedSeparators);
  }

  /// 保存艺术家分隔符列表
  static Future<void> setArtistSeparators(List<String> separators) async {
    final prefs = await SharedPreferences.getInstance();
    if (separators.isEmpty) {
      await prefs.remove(_artistSeparatorsKey);
    } else {
      await prefs.setString(_artistSeparatorsKey, separators.join('|'));
    }

    // 更新缓存
    _cachedSeparators = List.from(separators);
  }

  /// 获取默认艺术家分隔符列表
  static List<String> getDefaultSeparators() {
    return List.from(_defaultSeparators);
  }

  /// 获取配置的艺术家白名单
  static Future<List<String>> getArtistWhitelist() async {
    final prefs = await SharedPreferences.getInstance();
    final whitelistString = prefs.getString(_artistWhitelistKey);

    if (whitelistString == null || whitelistString.isEmpty) {
      return List.from(_defaultWhitelist);
    }

    return whitelistString.split('|');
  }

  /// 同步获取艺术家白名单（用于Song构造函数）
  static List<String> getArtistWhitelistSync() {
    if (_cachedWhitelist.isEmpty) {
      return List.from(_defaultWhitelist);
    }
    return List.from(_cachedWhitelist);
  }

  /// 保存艺术家白名单
  static Future<void> setArtistWhitelist(List<String> whitelist) async {
    final prefs = await SharedPreferences.getInstance();
    if (whitelist.isEmpty) {
      await prefs.remove(_artistWhitelistKey);
    } else {
      await prefs.setString(_artistWhitelistKey, whitelist.join('|'));
    }

    // 更新缓存
    _cachedWhitelist = List.from(whitelist);
  }

  /// 获取默认艺术家白名单
  static List<String> getDefaultWhitelist() {
    return List.from(_defaultWhitelist);
  }

  /// 获取文件夹白名单
  static Future<Map<String, bool>> getFolderWhitelist() async {
    final prefs = await SharedPreferences.getInstance();
    final whitelistString = prefs.getString(_folderWhitelistKey);

    if (whitelistString == null || whitelistString.isEmpty) {
      return {};
    }

    try {
      final Map<String, dynamic> decoded = 
          Map<String, dynamic>.from(jsonDecode(whitelistString));
      return decoded.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      return {};
    }
  }

  /// 同步获取文件夹白名单
  static Map<String, bool> getFolderWhitelistSync() {
    if (_cachedFolderWhitelist.isEmpty) {
      return {};
    }
    return Map.from(_cachedFolderWhitelist);
  }

  /// 保存文件夹白名单
  static Future<void> setFolderWhitelist(Map<String, bool> whitelist) async {
    final prefs = await SharedPreferences.getInstance();
    if (whitelist.isEmpty) {
      await prefs.remove(_folderWhitelistKey);
    } else {
      await prefs.setString(_folderWhitelistKey, jsonEncode(whitelist));
    }

    // 更新缓存
    _cachedFolderWhitelist = Map.from(whitelist);
  }

  /// 检查文件夹是否在白名单中
  static bool isFolderWhitelisted(String folderPath) {
    if (_cachedFolderWhitelist.isEmpty) {
      return true; // 默认包含所有文件夹
    }
    return _cachedFolderWhitelist[folderPath] ?? true;
  }

  /// 使用配置的分隔符分割艺术家字符串
  static List<String> splitArtists(String artistString) {
    final separators = getArtistSeparatorsSync();
    final whitelist = getArtistWhitelistSync();
    return splitArtistsWithSeparators(artistString, separators, whitelist);
  }

  /// 使用指定的分隔符分割艺术家字符串，并考虑白名单
  static List<String> splitArtistsWithSeparators(
    String artistString,
    List<String> separators,
    List<String> whitelist,
  ) {
    if (artistString.isEmpty) return ['未知艺术家'];

    final trimmedArtist = artistString.trim();

    // 首先检查整个字符串是否在白名单中（精确匹配，忽略大小写）
    for (final whiteArtist in whitelist) {
      if (whiteArtist.toLowerCase() == trimmedArtist.toLowerCase()) {
        return [whiteArtist];
      }
    }

    // 使用第一个找到的分隔符进行分割
    for (final separator in separators) {
      if (trimmedArtist.contains(separator)) {
        final parts = trimmedArtist.split(separator);
        final result = <String>[];
        
        // 遍历分割后的部分，检查是否属于白名单
        for (var part in parts) {
          final trimmedPart = part.trim();
          if (trimmedPart.isNotEmpty) {
            bool isInWhitelist = false;
            for (final whiteArtist in whitelist) {
              if (whiteArtist.toLowerCase() == trimmedPart.toLowerCase()) {
                result.add(whiteArtist);
                isInWhitelist = true;
                break;
              }
            }
            if (!isInWhitelist) {
              result.add(trimmedPart);
            }
          }
        }
        
        return result.isNotEmpty ? result : ['未知艺术家'];
      }
    }
    
    // 没有找到分隔符，返回原字符串
    return [trimmedArtist];
  }

  /// 保存播放状态
  static Future<void> savePlaylistState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playlistStateKey, jsonEncode(state));
  }

  /// 加载播放状态
  static Future<Map<String, dynamic>?> loadPlaylistState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateString = prefs.getString(_playlistStateKey);
    
    if (stateString == null || stateString.isEmpty) {
      return null;
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(stateString));
    } catch (e) {
      debugPrint('加载播放状态失败: $e');
      return null;
    }
  }

  /// 清除播放状态
  static Future<void> clearPlaylistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playlistStateKey);
  }
}
