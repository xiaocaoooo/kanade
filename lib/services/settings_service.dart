import 'package:shared_preferences/shared_preferences.dart';

/// 设置服务类
/// 管理应用的各种用户设置，包括艺术家分隔符配置
class SettingsService {
  static const String _artistSeparatorsKey = 'artist_separators';
  static const String _artistWhitelistKey = 'artist_whitelist';

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

  /// 初始化设置服务
  static Future<void> init() async {
    _cachedSeparators = await getArtistSeparators();
    _cachedWhitelist = await getArtistWhitelist();
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
        for (int i = 0; i < parts.length; i++) {
          final currentPart = parts[i].trim();
          if (currentPart.isEmpty) continue;
          
          // 检查当前部分是否属于白名单
          bool isInWhitelist = false;
          String matchedWhitelistArtist = currentPart;
          
          for (final whiteArtist in whitelist) {
            if (currentPart.toLowerCase() == whiteArtist.toLowerCase()) {
              isInWhitelist = true;
              matchedWhitelistArtist = whiteArtist;
              break;
            }
          }
          
          if (isInWhitelist) {
            result.add(matchedWhitelistArtist);
            continue;
          }
          
          // 检查从当前部分开始的连续部分是否组成白名单艺术家
          String combinedPart = currentPart;
          for (int j = i + 1; j < parts.length; j++) {
            combinedPart += separator + parts[j].trim();
            bool combinedInWhitelist = false;
            String matchedCombinedArtist = combinedPart;
            
            for (final whiteArtist in whitelist) {
              if (combinedPart.toLowerCase() == whiteArtist.toLowerCase()) {
                combinedInWhitelist = true;
                matchedCombinedArtist = whiteArtist;
                break;
              }
            }
            
            if (combinedInWhitelist) {
              result.add(matchedCombinedArtist);
              i = j; // 跳过已处理的部分
              isInWhitelist = true;
              break;
            }
          }
          
          if (!isInWhitelist) {
            result.add(currentPart);
          }
        }
        
        return result.where((artist) => artist.isNotEmpty).toList();
      }
    }

    // 如果没有找到任何分隔符，返回原字符串
    return [trimmedArtist];
  }
}
