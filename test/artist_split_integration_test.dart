import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/models/song.dart';


void main() {
  group('艺术家分割集成测试', () {
    test('Song模型使用分割后的艺术家', () {
      // 测试白名单艺术家不被分割
      final song1 = Song(
        id: '1',
        title: '测试歌曲1',
        artist: 'Leo/need',
        album: '测试专辑',
        duration: 180000,
        path: '/test/path1.mp3',
        size: 1024,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );
      
      expect(song1.artists, equals(['Leo/need']));
      expect(song1.artist, equals('Leo/need'));
      
      // 测试普通艺术家按分隔符分割
      final song2 = Song(
        id: '2',
        title: '测试歌曲2',
        artist: '初音未来/镜音铃',
        album: '测试专辑',
        duration: 180000,
        path: '/test/path2.mp3',
        size: 1024,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );
      
      expect(song2.artists, equals(['初音未来', '镜音铃']));
      expect(song2.artist, equals('初音未来 / 镜音铃'));
      
      // 测试白名单艺术家和普通艺术家的组合
      final song3 = Song(
        id: '3',
        title: '测试歌曲3',
        artist: '初音未来/Leo/need',
        album: '测试专辑',
        duration: 180000,
        path: '/test/path3.mp3',
        size: 1024,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );
      
      expect(song3.artists, equals(['初音未来', 'Leo/need']));
      expect(song3.artist, equals('初音未来 / Leo/need'));
    });
    
    test('空艺术家处理', () {
      final song = Song(
        id: '4',
        title: '测试歌曲4',
        artist: '',
        album: '测试专辑',
        duration: 180000,
        path: '/test/path4.mp3',
        size: 1024,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );
      
      expect(song.artists, equals(['未知艺术家']));
    });
  });
}