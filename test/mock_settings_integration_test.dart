import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/settings_service.dart';

void main() {
  group('SettingsService 模拟集成测试', () {
    test('白名单功能验证', () {
      // 测试默认白名单
      final defaultWhitelist = SettingsService.getDefaultWhitelist();
      expect(defaultWhitelist, isNotEmpty);
      expect(defaultWhitelist, contains('Leo/need'));

      // 测试白名单保护功能
      final separators = SettingsService.getDefaultSeparators();

      // Leo/need 应该被保护
      var result = SettingsService.splitArtistsWithSeparators(
        'Leo/need',
        separators,
        defaultWhitelist,
      );
      expect(result, equals(['Leo/need']));

      // YOASOBI 应该被保护
      result = SettingsService.splitArtistsWithSeparators(
        'YOASOBI',
        separators,
        defaultWhitelist,
      );
      expect(result, equals(['YOASOBI']));

      // 普通艺术家应该被正常分割
      result = SettingsService.splitArtistsWithSeparators(
        '初音未来/镜音铃',
        separators,
        defaultWhitelist,
      );
      expect(result, equals(['初音未来', '镜音铃']));
    });

    test('分隔符和白名单协同工作', () {
      final separators = ['/', '&'];
      final whitelist = ['Leo/need', 'Test&Group'];

      // 白名单艺术家完整匹配
      var result = SettingsService.splitArtistsWithSeparators(
        'Leo/need',
        separators,
        whitelist,
      );
      expect(result, equals(['Leo/need']));

      // 白名单艺术家大小写不敏感
      result = SettingsService.splitArtistsWithSeparators(
        'leo/need',
        separators,
        whitelist,
      );
      expect(result, equals(['Leo/need']));

      // 普通艺术家按分隔符分割
      result = SettingsService.splitArtistsWithSeparators(
        'Artist1/Artist2',
        separators,
        whitelist,
      );
      expect(result, equals(['Artist1', 'Artist2']));
    });
  });
}
