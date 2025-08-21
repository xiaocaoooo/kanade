import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/lyrics_service.dart';

void main() {
  group('真实歌词文件测试', () {
    test('测试flos.lrc解析', () async {
      final lrcFile = File('2713560379.lrc');
      expect(await lrcFile.exists(), isTrue);
      
      final content = await lrcFile.readAsString();
      final lyrics = LyricsService.parseLrcContent(content);
      
      expect(lyrics, isNotNull);
      expect(lyrics.isNotEmpty, isTrue);
      
      // 检查是否有元数据
      print('解析到${lyrics.length}行歌词');
      print('第一行: ${lyrics.first.text}');
      print('最后一行: ${lyrics.last.text}');
    });

    test('测试携帯恋話.lrc解析', () async {
      final lrcFile = File('1864931358.lrc');
      expect(await lrcFile.exists(), isTrue);
      
      final content = await lrcFile.readAsString();
      final lyrics = LyricsService.parseLrcContent(content);
      
      expect(lyrics, isNotNull);
      expect(lyrics.isNotEmpty, isTrue);
      
      // 检查是否有逐字歌词
      final hasWordTimings = lyrics.any((l) => l.wordTimings != null && l.wordTimings!.isNotEmpty);
      print('${lrcFile.path} 包含逐字歌词: $hasWordTimings');
      if (hasWordTimings) {
        final timedLyric = lyrics.firstWhere((l) => l.wordTimings != null);
        print('逐字歌词示例: ${timedLyric.wordTimings?.length}个字');
      }
    });

    test('测试悔やむと書いてミライ.lrc解析', () async {
      final lrcFile = File('1864932183.lrc');
      expect(await lrcFile.exists(), isTrue);
      
      final content = await lrcFile.readAsString();
      final lyrics = LyricsService.parseLrcContent(content);
      
      expect(lyrics, isNotNull);
      expect(lyrics.isNotEmpty, isTrue);
      
      print('${lrcFile.path} 解析到${lyrics.length}行歌词');
    });
  });
}
