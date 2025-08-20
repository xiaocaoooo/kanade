import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/settings_service.dart';

void main() {
  group('白名单功能集成测试', () {
    test('Leo/need 不被分割', () {
      final result = SettingsService.splitArtists('Leo/need');
      expect(result, equals(['Leo/need']));
    });

    test('YOASOBI 不被分割', () {
      final result = SettingsService.splitArtists('YOASOBI');
      expect(result, equals(['YOASOBI']));
    });

    test('普通艺术家仍按分隔符分割', () {
      final result = SettingsService.splitArtists('初音未来/镜音铃');
      expect(result, equals(['初音未来', '镜音铃']));
    });

    test('白名单艺术家和普通艺术家的组合', () {
      final result = SettingsService.splitArtists('初音未来/Leo/need');
      expect(result, equals(['初音未来', 'Leo/need']));
    });

    test('大小写不敏感匹配', () {
      final result = SettingsService.splitArtists('leo/need');
      expect(result, equals(['Leo/need']));
    });

    test('自定义白名单测试', () {
      // 测试自定义白名单
      final customWhitelist = ['Custom/Artist', 'Test&Group'];
      final separators = ['/', '&'];

      // 应该被保护
      var result = SettingsService.splitArtistsWithSeparators(
        'Custom/Artist',
        separators,
        customWhitelist,
      );
      expect(result, equals(['Custom/Artist']));

      // 应该被分割
      result = SettingsService.splitArtistsWithSeparators(
        'Other/Artist',
        separators,
        customWhitelist,
      );
      expect(result, equals(['Other', 'Artist']));
    });
  });
}
