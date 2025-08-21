import 'lib/services/lyrics_service.dart';

void main() {
  final lrcContent = '''
[00:10.00]第一句
[00:20.00]第二句
[00:30.00]第三句
[00:40.00]第四句
'''.trim();

  final lyrics = LyricsService.parseLrcContent(lrcContent);
  
  print('歌词列表：');
  for (var i = 0; i < lyrics.length; i++) {
    print('  $i: ${lyrics[i].text} at ${lyrics[i].startTime.inSeconds}s');
  }
  
  print('\n测试当前歌词索引：');
  final testTimes = [5, 10, 15, 25, 45];
  for (final time in testTimes) {
    final index = LyricsService.getCurrentLyricIndex(lyrics, Duration(seconds: time));
    print('  $time秒: 索引 $index');
  }
}