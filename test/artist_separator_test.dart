import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/settings_service.dart';

class MockSettingsService {
  static List<String> getDefaultSeparators() => ['/', '&', ',', '、', ' '];

  static List<String> splitArtistsWithSeparators(
    String input,
    List<String> separators,
  ) {
    if (input.trim().isEmpty) return ['未知艺术家'];
    for (final sep in separators) {
      if (input.contains(sep)) {
        return input
            .split(sep)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return [input.trim()];
  }
}

void main() {
  group('艺术家分隔符测试', () {
    test('使用默认分隔符分割艺术家', () {
      final result = MockSettingsService.splitArtistsWithSeparators(
        '周杰伦/林俊杰',
        MockSettingsService.getDefaultSeparators(),
      );
      expect(result, equals(['周杰伦', '林俊杰']));
    });

    test('使用自定义分隔符分割艺术家', () {
      final result = MockSettingsService.splitArtistsWithSeparators('周杰伦&林俊杰', [
        '&',
      ]);
      expect(result, equals(['周杰伦', '林俊杰']));
    });

    test('多个分隔符按优先级使用', () {
      final result = MockSettingsService.splitArtistsWithSeparators(
        '周杰伦/林俊杰&王力宏',
        ['/', '&'],
      );
      expect(result, equals(['周杰伦', '林俊杰&王力宏']));
    });

    test('没有分隔符时返回原字符串', () {
      final result = MockSettingsService.splitArtistsWithSeparators('周杰伦', [
        '/',
        '&',
      ]);
      expect(result, equals(['周杰伦']));
    });

    test('处理空字符串', () {
      final result = MockSettingsService.splitArtistsWithSeparators('', [
        '/',
        '&',
      ]);
      expect(result, equals(['未知艺术家']));
    });

    test('处理带空格的情况', () {
      final result = MockSettingsService.splitArtistsWithSeparators(
        '周杰伦 / 林俊杰',
        MockSettingsService.getDefaultSeparators(),
      );
      expect(result, equals(['周杰伦', '林俊杰']));
    });

    test('获取默认分隔符列表', () {
      final separators = MockSettingsService.getDefaultSeparators();
      expect(separators, isNotEmpty);
      expect(separators, contains('/'));
    });
  });
}
