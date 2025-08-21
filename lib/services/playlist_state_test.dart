import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/models/song.dart';
import 'package:kanade/services/audio_player_service.dart';
import 'package:kanade/services/settings_service.dart';

void main() {
  group('播放状态保存和恢复测试', () {
    test('Song序列化和反序列化', () {
      final originalSong = Song(
        id: 'test-123',
        title: '测试歌曲',
        artist: '测试艺术家',
        album: '测试专辑',
        duration: 180000, // 3分钟
        path: '/test/path/song.mp3',
        size: 1024000, // 1MB
        albumId: 'album-123',
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );

      final json = originalSong.toJson();
      final restoredSong = Song.fromJson(json);

      expect(restoredSong.id, equals(originalSong.id));
      expect(restoredSong.title, equals(originalSong.title));
      expect(restoredSong.artist, equals(originalSong.artist));
      expect(restoredSong.album, equals(originalSong.album));
      expect(restoredSong.duration, equals(originalSong.duration));
      expect(restoredSong.path, equals(originalSong.path));
      expect(restoredSong.size, equals(originalSong.size));
      expect(restoredSong.albumId, equals(originalSong.albumId));
    });

    test('播放状态保存和清除', () async {
      // 清除之前的状态
      await SettingsService.clearPlaylistState();
      
      // 检查是否没有保存的状态
      final hasState = await AudioPlayerService.hasSavedPlaylistState();
      expect(hasState, isFalse);
    });
  });
}