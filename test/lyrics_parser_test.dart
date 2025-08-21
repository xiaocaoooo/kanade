import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/lyrics_service.dart';

void main() {
  group('歌词解析测试', () {
    test('测试标准LRC解析', () {
      final lrcContent = '''
[00:10.00]这是第一句歌词
[00:20.50]这是第二句歌词
[00:30.00]这是第三句歌词
[01:00.00]这是第四句歌词
'''.trim();

      final lyrics = LyricsService.parseLrcContent(lrcContent);
      
      expect(lyrics, isNotNull);
      expect(lyrics.length, 4);
      expect(lyrics[0].text, '这是第一句歌词');
      expect(lyrics[0].startTime.inMilliseconds, 10000);
      expect(lyrics[0].endTime.inMilliseconds, 20500);
      expect(lyrics[1].text, '这是第二句歌词');
      expect(lyrics[1].startTime.inMilliseconds, 20500);
    });

    test('测试逐字LRC解析', () {
      final lrcContent = '''
[00:10.00]<00:10.00>这<00:10.20>是<00:10.40>逐<00:10.60>字<00:10.80>歌<00:11.00>词<00:12.00>
[00:20.00]普通歌词
'''.trim();

      final lyrics = LyricsService.parseLrcContent(lrcContent);
      
      expect(lyrics, isNotNull);
      expect(lyrics.length, 2);
      
      final timedLyric = lyrics[0];
      expect(timedLyric.text, '这是逐字歌词');
      expect(timedLyric.wordTimings, isNotNull);
      expect(timedLyric.endTime.inMilliseconds, 12000);
      expect(timedLyric.wordTimings!.length, 6);
      
      expect(timedLyric.wordTimings![0].word, '这');
      expect(timedLyric.wordTimings![0].startTime.inMilliseconds, 10000);
      expect(timedLyric.wordTimings![0].endTime.inMilliseconds, 10020);
    });

    test('测试空内容解析', () {
      final lyrics = LyricsService.parseLrcContent('');
      expect(lyrics, isEmpty);
    });

    test('测试当前歌词索引', () {
      final lrcContent = '''
[00:10.00]第一句
[00:20.00]第二句
[00:30.00]第三句
[00:40.00]第四句
'''.trim();

      final lyrics = LyricsService.parseLrcContent(lrcContent);
      
      expect(LyricsService.getCurrentLyricIndex(lyrics, const Duration(seconds: 5)), 0);
      expect(LyricsService.getCurrentLyricIndex(lyrics, const Duration(seconds: 10)), 0);
      expect(LyricsService.getCurrentLyricIndex(lyrics, const Duration(seconds: 15)), 0);
      expect(LyricsService.getCurrentLyricIndex(lyrics, const Duration(seconds: 25)), 1);
      expect(LyricsService.getCurrentLyricIndex(lyrics, const Duration(seconds: 45)), 0);
    });

    test('测试翻译歌词解析', () {
      final lrcContent = '''
[00:10.00]这是中文歌词
[00:10.00]This is Chinese lyrics
[00:20.00]这是第二行中文
[00:20.00]This is second line Chinese
[00:30.00]只有主歌词的行
'''.trim();

      final lyrics = LyricsService.parseLrcContent(lrcContent);
      
      expect(lyrics, isNotNull);
      expect(lyrics.length, 3);
      
      // 测试第一行（有翻译）
      expect(lyrics[0].text, '这是中文歌词');
      expect(lyrics[0].translation, 'This is Chinese lyrics');
      expect(lyrics[0].startTime.inMilliseconds, 10000);
      expect(lyrics[0].endTime.inMilliseconds, 20000);
      
      // 测试第二行（有翻译）
      expect(lyrics[1].text, '这是第二行中文');
      expect(lyrics[1].translation, 'This is second line Chinese');
      expect(lyrics[1].startTime.inMilliseconds, 20000);
      expect(lyrics[1].endTime.inMilliseconds, 30000);
      
      // 测试第三行（无翻译）
      expect(lyrics[2].text, '只有主歌词的行');
      expect(lyrics[2].translation, isNull);
      expect(lyrics[2].startTime.inMilliseconds, 30000);
    });
  });
}
