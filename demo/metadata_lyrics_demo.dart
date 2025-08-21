import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:kanade/services/lyrics_service.dart';

/// 演示从音频文件元数据读取歌词
void main() async {
  print('=== 音频文件元数据歌词读取演示 ===\n');

  // 测试音频文件路径（请根据实际情况修改）
  const testAudioFile = 'test.mp3'; // 替换为实际的音频文件路径

  try {
    // 1. 使用audio_metadata_reader直接读取
    print('1. 使用audio_metadata_reader读取元数据...');
    final file = File(testAudioFile);
    
    if (!await file.exists()) {
      print('测试文件不存在: $testAudioFile');
      print('请创建一个包含歌词的音频文件或将路径修改为实际文件');
      return;
    }

    final meta = readAllMetadata(file, getImage: false);
      final lyric = meta.tags['lyrics'] as String? ?? 
                   meta.tags['LYRICS'] as String? ?? 
                   meta.tags['USLT'] as String?;
    
    print('音频文件: $testAudioFile');
    print('标题: ${meta.title ?? "未知"}');
    print('艺术家: ${meta.artist ?? "未知"}');
    print('专辑: ${meta.album ?? "未知"}');
    
    if (lyric != null) {
      print('\n找到歌词（前200字符）:');
      print(lyric.length > 200 ? '${lyric.substring(0, 200)}...' : lyric);
      
      // 2. 使用LyricsService解析歌词
      print('\n2. 解析歌词格式...');
      final parsedLyrics = LyricsService.parseLrcContent(lyric);
      
      if (parsedLyrics.isNotEmpty) {
        print('成功解析 ${parsedLyrics.length} 行歌词');
        print('前3行歌词:');
        for (int i = 0; i < 3 && i < parsedLyrics.length; i++) {
          final line = parsedLyrics[i];
          print('  ${i+1}. [${line.startTime}s] ${line.text}');
        }
        
        // 3. 检查逐字歌词
        final hasWordTimings = parsedLyrics.any((line) => line.wordTimings != null);
        if (hasWordTimings) {
          print('\n包含逐字歌词信息');
        } else {
          print('\n不包含逐字歌词信息');
        }
      } else {
        print('无法解析歌词格式');
      }
    } else {
      print('\n该音频文件不包含歌词信息');
    }

    // 4. 使用LyricsService的统一接口
    print('\n4. 使用LyricsService的统一接口...');
    final lyrics = await LyricsService.getLyricsFromMetadata(testAudioFile);
    
    if (lyrics != null && lyrics.isNotEmpty) {
      print('通过统一接口获取到 ${lyrics.length} 行歌词');
    } else {
      print('统一接口未获取到歌词');
    }

  } catch (e) {
    print('发生错误: $e');
  }

  print('\n=== 演示完成 ===');
}
