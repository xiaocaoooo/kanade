import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/settings_service.dart';
import 'package:kanade/services/music_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('文件夹白名单功能测试', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.init();
    });

    test('默认包含所有文件夹', () {
      expect(SettingsService.isFolderWhitelisted('/music'), isTrue);
      expect(SettingsService.isFolderWhitelisted('/downloads'), isTrue);
    });

    test('设置文件夹白名单', () async {
      final whitelist = {
        '/music': true,
        '/downloads': false,
        '/documents/music': true,
      };

      await SettingsService.setFolderWhitelist(whitelist);
      
      expect(SettingsService.isFolderWhitelisted('/music'), isTrue);
      expect(SettingsService.isFolderWhitelisted('/downloads'), isFalse);
      expect(SettingsService.isFolderWhitelisted('/documents/music'), isTrue);
      expect(SettingsService.isFolderWhitelisted('/unknown'), isTrue);
    });

    test('获取文件夹路径', () {
      expect(
        MusicService.getFolderPath('/storage/emulated/0/Music/song.mp3'),
        '/storage/emulated/0/Music',
      );
      
      expect(
        MusicService.getFolderPath('C:\\Users\\Music\\song.mp3'),
        'C:/Users/Music',
      );
      
      expect(
        MusicService.getFolderPath('/song.mp3'),
        '/',
      );
    });
  });
}