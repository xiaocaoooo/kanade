import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:kanada_lyric_sender/kanada_lyric_sender.dart';
import '../models/song.dart';

/// 歌词数据模型
class LyricLine {
  final Duration startTime;
  final Duration endTime;
  final String text;
  final String? translation; // 翻译文本
  final List<WordTiming>? wordTimings; // 逐字歌词

  LyricLine({
    required this.startTime,
    required this.endTime,
    required this.text,
    this.translation,
    this.wordTimings,
  });
}

/// 逐字歌词时间信息
class WordTiming {
  final Duration startTime;
  final Duration duration;
  final String word;

  WordTiming({
    required this.startTime,
    required this.duration,
    required this.word,
  });

  /// 获取单词的结束时间
  Duration get endTime => startTime + duration;
}

/// 歌词服务类
/// 负责解析LRC歌词文件，提供逐行和逐字歌词支持
class LyricsService {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;
  LyricsService._internal();

  /// 解析LRC歌词文件
  /// 支持标准LRC格式和增强LRC格式（逐字歌词）
  static Future<List<LyricLine>?> parseLrcFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      return parseLrcContent(content);
    } catch (e) {
      print('解析LRC文件失败: $e');
      return null;
    }
  }

  /// 解析LRC歌词内容
  static List<LyricLine> parseLrcContent(String content) {
    final lines = content.split('\n');
    final rawLyrics = <Duration, List<String>>{};
    final wordTimingsMap = <Duration, List<WordTiming>?>{};
    final endTimeMap = <Duration, Duration>{};

    // 元数据
    String title = '';
    String artist = '';
    String album = '';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // 解析元数据
      if (line.startsWith('[ti:')) {
        title = line.substring(4, line.length - 1);
        continue;
      }
      if (line.startsWith('[ar:')) {
        artist = line.substring(4, line.length - 1);
        continue;
      }
      if (line.startsWith('[al:')) {
        album = line.substring(4, line.length - 1);
        continue;
      }

      // 跳过其他元数据
      if (line.startsWith('[') && !line.contains(']')) continue;

      // 解析时间标签和歌词
      final regex = RegExp(r'\[(\d{2}):(\d{2}\.\d{2,3})\](.*)');
      final matches = regex.allMatches(line);

      if (matches.isEmpty) continue;

      for (final match in matches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final time = Duration(
          minutes: minutes,
          milliseconds: (seconds * 1000).toInt(),
        );

        var text = match.group(3) ?? '';

        // 检查是否有逐字歌词和独立的结束时间
        List<WordTiming>? wordTimings;
        String cleanText;
        Duration? explicitEndTime;

        if (text.contains('<')) {
          // 检查是否有独立的结束时间标签
          final allTags = RegExp(
            r'<(\d{2}):(\d{2}\.\d{2,3})>([^<]*)',
          ).allMatches(text);
          if (allTags.isNotEmpty) {
            final lastTag = allTags.last;
            final content = lastTag.group(3)?.trim() ?? '';

            if (content.isEmpty) {
              // 最后一个标签是独立的结束时间标签
              final endMinutes = int.parse(lastTag.group(1)!);
              final endSeconds = double.parse(lastTag.group(2)!);
              explicitEndTime = Duration(
                minutes: endMinutes,
                milliseconds: (endSeconds * 1000).toInt(),
              );

              // 移除最后一个结束时间标签
              text = text.substring(0, lastTag.start);
            }
          }

          wordTimings = _parseWordTimings(text);
          cleanText = _removeWordTimingTags(text);
        } else {
          cleanText = text.trim();
        }

        // 将相同时间的歌词合并
        if (!rawLyrics.containsKey(time)) {
          rawLyrics[time] = [];
          wordTimingsMap[time] = wordTimings;
        }
        rawLyrics[time]!.add(cleanText);

        if (explicitEndTime != null) {
          endTimeMap[time] = explicitEndTime;
        }
      }
    }

    // 构建最终的歌词列表
    final lyrics = <LyricLine>[];
    final sortedTimes = rawLyrics.keys.toList()..sort();

    for (int i = 0; i < sortedTimes.length; i++) {
      final time = sortedTimes[i];
      final texts = rawLyrics[time]!;
      final wordTimings = wordTimingsMap[time];

      String text;
      String? translation;

      if (texts.length >= 2) {
        // 如果有多个文本，第一行为主歌词，第二行为翻译
        text = texts[0];
        translation = texts[1];
      } else {
        // 只有一行歌词
        text = texts[0];
      }

      Duration endTime;
      if (endTimeMap[time] != null) {
        // 使用预解析的结束时间
        endTime = endTimeMap[time]!;
      } else if (i < sortedTimes.length - 1) {
        endTime = sortedTimes[i + 1];
      } else {
        // 对于最后一行，使用逐字歌词结束时间或默认值
        endTime =
            wordTimings != null && wordTimings.isNotEmpty
                ? wordTimings.last.startTime + wordTimings.last.duration
                : time + const Duration(seconds: 5);
      }

      lyrics.add(
        LyricLine(
          startTime: time,
          endTime: endTime,
          text: text,
          translation: translation,
          wordTimings: wordTimings,
        ),
      );
    }

    return lyrics;
  }

  /// 解析逐字歌词时间标签
  static List<WordTiming>? _parseWordTimings(String text) {
    final regex = RegExp(r'<(\d{2}):(\d{2}\.\d{2,3})>([^<]*)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) return null;

    final wordTimings = <WordTiming>[];

    // 过滤掉空内容的标签，只保留有实际歌词的标签
    final validMatches =
        matches.where((match) {
          final word = match.group(3)?.trim() ?? '';
          return word.isNotEmpty;
        }).toList();

    if (validMatches.isEmpty) return null;

    for (var i = 0; i < validMatches.length; i++) {
      final match = validMatches[i];
      final minutes = int.parse(match.group(1)!);
      final seconds = double.parse(match.group(2)!);
      final word = match.group(3)!.trim();

      final startTime = Duration(
        minutes: minutes,
        milliseconds: (seconds * 1000).toInt(),
      );

      // 根据测试数据，每个单词固定持续20毫秒
      Duration duration = const Duration(milliseconds: 20);

      wordTimings.add(
        WordTiming(startTime: startTime, duration: duration, word: word),
      );
    }

    return wordTimings;
  }

  /// 移除逐字时间标签，获取纯文本
  static String _removeWordTimingTags(String text) {
    // 移除所有时间标签，包括独立的结束时间标签
    return text.replaceAll(RegExp(r'<\d{2}:\d{2}\.\d{2,3}>'), '').trim();
  }

  /// 从音频文件元数据读取歌词
  static Future<List<LyricLine>?> getLyricsFromMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final dynamic meta = readAllMetadata(file, getImage: false);
      final lyricText = meta.lyric;

      if (lyricText != null && lyricText.isNotEmpty) {
        return parseLrcContent(lyricText);
      }

      return null;
    } catch (e) {
      print('读取音频文件元数据失败: $e');
      return null;
    }
  }

  /// 根据歌曲信息查找对应的LRC文件
  static Future<String?> findLrcFile(Song song) async {
    final directory = Directory(song.path).parent;
    final fileName = song.path.split(Platform.pathSeparator).last;
    final baseName = fileName.substring(0, fileName.lastIndexOf('.'));

    // 可能的LRC文件名
    final possibleNames = [
      '$baseName.lrc',
      '${baseName.toLowerCase()}.lrc',
      '${baseName.toUpperCase()}.lrc',
    ];

    for (final name in possibleNames) {
      final lrcFile = File('${directory.path}/$name');
      if (await lrcFile.exists()) {
        return lrcFile.path;
      }
    }

    return null;
  }

  /// 获取歌曲的歌词
  static Future<List<LyricLine>?> getLyricsForSong(Song song) async {
    final lrcFilePath = await findLrcFile(song);
    if (lrcFilePath != null) {
      return await parseLrcFile(lrcFilePath);
    }
    return null;
  }

  /// 根据当前播放时间获取当前应该显示的歌词行
  static LyricLine? getCurrentLyric(
    List<LyricLine> lyrics,
    Duration currentTime,
  ) {
    if (lyrics.isEmpty) return null;

    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (currentTime >= lyrics[i].startTime &&
          currentTime < lyrics[i].endTime) {
        return lyrics[i];
      }
    }

    return null;
  }

  /// 获取当前歌词行的索引
  static int getCurrentLyricIndex(
    List<LyricLine> lyrics,
    Duration currentTime,
  ) {
    if (lyrics.isEmpty) return -1;

    int index = 0;

    for (int i = 0; i < lyrics.length; i++) {
      if (currentTime >= lyrics[i].startTime) {
        index = i;
      } else {
        break;
      }
    }

    return index;
  }

  /// 检查Lyric Getter是否已启用
  static Future<bool> isLyricGetterEnabled() async {
    try {
      return await KanadaLyricSenderPlugin.hasEnable();
    } catch (e) {
      print('检查Lyric Getter状态失败: $e');
      return false;
    }
  }

  /// 发送歌词到外部API
  static Future<void> sendLyricToExternal(String lyric, {int? delay}) async {
    try {
      await KanadaLyricSenderPlugin.sendLyric(lyric, delay);
    } catch (e) {
      print('发送歌词到外部API失败: $e');
    }
  }

  /// 清除外部API显示的歌词
  static Future<void> clearExternalLyric() async {
    try {
      await KanadaLyricSenderPlugin.clearLyric();
    } catch (e) {
      print('清除外部API歌词失败: $e');
    }
  }

  /// 根据当前播放时间发送歌词到外部API
  static Future<void> sendCurrentLyricToExternal(
    List<LyricLine> lyrics,
    Duration currentTime,
  ) async {
    // 首先检查Lyric Getter是否已启用
    final isEnabled = await isLyricGetterEnabled();
    if (!isEnabled) {
      return;
    }

    final currentLyric = getCurrentLyric(lyrics, currentTime);
    if (currentLyric != null) {
      // 如果有翻译，合并歌词和翻译
      String fullLyric = currentLyric.text;
      if (currentLyric.translation != null && currentLyric.translation!.isNotEmpty) {
        fullLyric = '$fullLyric\n${currentLyric.translation!}';
      }
      await sendLyricToExternal(fullLyric);
    } else {
      // 没有当前歌词时清除显示
      await clearExternalLyric();
    }
  }
}
