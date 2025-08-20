import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/settings_service.dart';

void main() {
  group('SettingsService 集成测试', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    test('分隔符保存和读取', () async {
      // 测试自定义分隔符
      final customSeparators = ['|', '#', '@'];
      await SettingsService.setArtistSeparators(customSeparators);

      final retrieved = await SettingsService.getArtistSeparators();
      expect(retrieved, equals(customSeparators));
    });

    test('白名单保存和读取', () async {
      // 测试自定义白名单
      final customWhitelist = ['Custom Artist', 'Test/Group'];
      await SettingsService.setArtistWhitelist(customWhitelist);

      final retrieved = await SettingsService.getArtistWhitelist();
      expect(retrieved, equals(customWhitelist));
    });

    test('默认分隔符测试', () {
      final defaultSeparators = SettingsService.getDefaultSeparators();
      expect(defaultSeparators, isNotEmpty);
      expect(defaultSeparators, contains('/'));
    });

    test('默认白名单测试', () {
      final defaultWhitelist = SettingsService.getDefaultWhitelist();
      expect(defaultWhitelist, isNotEmpty);
      expect(defaultWhitelist, contains('Leo/need'));
    });

    test('分隔符字符串分割合并测试', () async {
      final separators = ['/', '&', ','];
      await SettingsService.setArtistSeparators(separators);

      final retrieved = await SettingsService.getArtistSeparators();
      expect(retrieved.length, equals(3));
      expect(retrieved, equals(separators));
    });

    test('白名单字符串分割合并测试', () async {
      final whitelist = ['Leo/need', 'YOASOBI', 'Test Artist'];
      await SettingsService.setArtistWhitelist(whitelist);

      final retrieved = await SettingsService.getArtistWhitelist();
      expect(retrieved.length, equals(3));
      expect(retrieved, equals(whitelist));
    });

    test('白名单保护艺术家不被分割', () async {
      // 设置白名单包含 Leo/need
      await SettingsService.setArtistWhitelist(['Leo/need']);

      // 验证 Leo/need 不会被分割
      final result = SettingsService.splitArtists('Leo/need');
      expect(result, equals(['Leo/need']));
    });
  });
}
