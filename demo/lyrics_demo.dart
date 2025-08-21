import 'dart:io';
import 'package:kanade/services/lyrics_service.dart';

void main() async {
  print('=== 歌词功能演示 ===');
  
  // 演示1: 基本LRC解析
  print('\n1. 基本LRC解析:');
  final basicLrc = '''
[00:10.00]这是第一句歌词
[00:20.50]这是第二句歌词
[00:30.00]这是第三句歌词
'''.trim();
  
  final basicLyrics = LyricsService.parseLrcContent(basicLrc);
  print('   解析到 ${basicLyrics.length} 行歌词');
  for (var i = 0; i < basicLyrics.length; i++) {
    print('   [${basicLyrics[i].startTime}] ${basicLyrics[i].text}');
  }
  
  // 演示2: 真实歌词文件测试
  print('\n2. 真实歌词文件测试:');
  final files = ['2713560379.lrc', '1864931358.lrc', '1864932183.lrc'];
  
  for (final filename in files) {
    final file = File(filename);
    if (await file.exists()) {
      final content = await file.readAsString();
      final lyrics = LyricsService.parseLrcContent(content);
      print('   $filename: ${lyrics.length} 行');
      
      // 检查是否有逐字歌词
      final hasWordTimings = lyrics.any((l) => l.wordTimings != null && l.wordTimings!.isNotEmpty);
      if (hasWordTimings) {
        print('   ✓ 包含逐字歌词');
      }
    } else {
      print('   $filename: 文件不存在');
    }
  }
  
  // 演示3: 歌词查找功能
  print('\n3. 歌词查找功能:');
  final testCases = [
    {'title': 'flos', 'artist': 'MORE MORE JUMP！'},
    {'title': '携帯恋話', 'artist': 'MORE MORE JUMP！'},
    {'title': '悔やむと書いてミライ', 'artist': 'MORE MORE JUMP！'},
  ];
  
  for (final testCase in testCases) {
    final lyrics = await LyricsService.findLyricsForSong(
      testCase['title']!, 
      testCase['artist']!
    );
    
    if (lyrics != null) {
      print('   ✓ ${testCase['title']}: 找到 ${lyrics.length} 行歌词');
    } else {
      print('   ✗ ${testCase['title']}: 未找到歌词');
    }
  }
  
  print('\n=== 演示完成 ===');
}