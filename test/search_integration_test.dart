import 'package:flutter_test/flutter_test.dart';
import '../lib/services/settings_service.dart';
import '../lib/models/song.dart';

void main() {
  group('Search Integration Tests', () {
    late SettingsService settingsService;

    setUp(() {
      settingsService = SettingsService();
    });

    test('搜索功能使用分割后的艺术家数据', () {
      // 创建测试歌曲
      final song1 = Song(
        id: '1',
        title: '测试歌曲1',
        artist: '艺术家A',
        album: '专辑1',
        duration: 180000,
        path: 'path1',
        size: 1024,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );

      final song2 = Song(
        id: '2',
        title: '测试歌曲2',
        artist: '艺术家A/艺术家B',
        album: '专辑2',
        duration: 200000,
        path: 'path2',
        size: 2048,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );

      final song3 = Song(
        id: '3',
        title: '初音未来歌曲',
        artist: '初音未来',
        album: 'Vocaloid专辑',
        duration: 220000,
        path: 'path3',
        size: 3072,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );

      final songs = [song1, song2, song3];

      // 验证艺术家分割
      expect(song1.artists, ['艺术家A']);
      expect(song2.artists, ['艺术家A', '艺术家B']);
      expect(song3.artists, ['初音未来']);

      // 模拟搜索功能
      final query = '艺术家A';
      final results =
          songs.where((song) {
            return song.title.toLowerCase().contains(query.toLowerCase()) ||
                song.artists.any(
                  (artist) =>
                      artist.toLowerCase().contains(query.toLowerCase()),
                ) ||
                song.album.toLowerCase().contains(query.toLowerCase());
          }).toList();

      expect(results.length, 2); // song1 和 song2 都包含艺术家A
      expect(results.any((song) => song.title == '测试歌曲1'), isTrue);
      expect(results.any((song) => song.title == '测试歌曲2'), isTrue);
    });

    test('搜索白名单艺术家不被分割', () {
      final song = Song(
        id: '1',
        title: '初音未来歌曲',
        artist: '初音未来/Leo/need',
        album: 'Vocaloid专辑',
        duration: 220000,
        path: 'path1',
        size: 1024,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );

      // 验证白名单艺术家不被分割
      expect(song.artists, ['初音未来', 'Leo/need']);

      // 搜索初音未来应该能找到这首歌
      final query = '初音未来';
      final results =
          [song]
              .where(
                (s) => s.artists.any(
                  (artist) =>
                      artist.toLowerCase().contains(query.toLowerCase()),
                ),
              )
              .toList();

      expect(results.length, 1);
      expect(results[0].title, '初音未来歌曲');
    });

    test('搜索艺术家分组功能', () {
      final songs = [
        Song(
          id: '1',
          title: '歌曲1',
          artist: '艺术家A',
          album: '专辑1',
          duration: 180000,
          path: 'path1',
          size: 1024,
          dateAdded: DateTime.now(),
          dateModified: DateTime.now(),
        ),
        Song(
          id: '2',
          title: '歌曲2',
          artist: '艺术家A',
          album: '专辑1',
          duration: 190000,
          path: 'path2',
          size: 2048,
          dateAdded: DateTime.now(),
          dateModified: DateTime.now(),
        ),
        Song(
          id: '3',
          title: '歌曲3',
          artist: '艺术家B',
          album: '专辑2',
          duration: 200000,
          path: 'path3',
          size: 3072,
          dateAdded: DateTime.now(),
          dateModified: DateTime.now(),
        ),
      ];

      // 按艺术家分组
      final artistMap = <String, List<Song>>{};
      for (final song in songs) {
        for (final artist in song.artists) {
          artistMap.putIfAbsent(artist, () => []).add(song);
        }
      }

      expect(artistMap['艺术家A']?.length, 2);
      expect(artistMap['艺术家B']?.length, 1);
    });

    test('搜索专辑功能', () {
      final songs = [
        Song(
          id: '1',
          title: '歌曲1',
          artist: '艺术家A',
          album: '专辑1',
          duration: 180000,
          path: 'path1',
          size: 1024,
          dateAdded: DateTime.now(),
          dateModified: DateTime.now(),
        ),
        Song(
          id: '2',
          title: '歌曲2',
          artist: '艺术家B',
          album: '专辑1',
          duration: 190000,
          path: 'path2',
          size: 2048,
          dateAdded: DateTime.now(),
          dateModified: DateTime.now(),
        ),
      ];

      // 按专辑分组
      final albumMap = <String, List<Song>>{};
      for (final song in songs) {
        albumMap.putIfAbsent(song.album, () => []).add(song);
      }

      expect(albumMap['专辑1']?.length, 2);
      expect(albumMap['专辑1']?[0].artists, ['艺术家A']);
      expect(albumMap['专辑1']?[1].artists, ['艺术家B']);
    });
  });
}
