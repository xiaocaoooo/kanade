import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/lyrics_service.dart';

void main() {
  group('歌词解析基础测试', () {
    test('解析基本LRC格式', () {
      final content = '[00:10.00]测试歌词';
      final lyrics = LyricsService.parseLrcContent(content);
      
      expect(lyrics.length, 1);
      expect(lyrics[0].text, '测试歌词');
      expect(lyrics[0].startTime.inMilliseconds, 10000);
    });

    test('解析多行LRC', () {
      final content = '''
[00:10.00]第一行
[00:20.00]第二行
[00:30.00]第三行
'''.trim();
      
      final lyrics = LyricsService.parseLrcContent(content);
      expect(lyrics.length, 3);
    });

    test('空内容处理', () {
      final lyrics = LyricsService.parseLrcContent('');
      expect(lyrics.isEmpty, isTrue);
    });
  });
}
