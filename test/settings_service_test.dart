import 'package:flutter_test/flutter_test.dart';
import 'package:kanade/services/settings_service.dart';

void main() {
  group('SettingsService', () {
    test('使用默认分隔符分割艺术家', () {
      final result = SettingsService.splitArtistsWithSeparators(
        '周杰伦/林俊杰',
        SettingsService.getDefaultSeparators(),
        SettingsService.getDefaultWhitelist(),
      );
      expect(result, equals(['周杰伦', '林俊杰']));
    });

    test('使用自定义分隔符分割艺术家', () {
      final result = SettingsService.splitArtistsWithSeparators('周杰伦&林俊杰', [
        '&',
      ], []);
      expect(result, equals(['周杰伦', '林俊杰']));
    });

    test('多个分隔符按优先级使用', () {
      final result = SettingsService.splitArtistsWithSeparators('周杰伦/林俊杰&王力宏', [
        '/',
        '&',
      ], []);
      expect(result, equals(['周杰伦', '林俊杰&王力宏']));
    });

    test('没有分隔符时返回原字符串', () {
      final result = SettingsService.splitArtistsWithSeparators('周杰伦', [
        '/',
        '&',
      ], []);
      expect(result, equals(['周杰伦']));
    });

    test('处理空字符串', () {
      final result = SettingsService.splitArtistsWithSeparators('', [
        '/',
        '&',
      ], []);
      expect(result, equals(['未知艺术家']));
    });

    test('处理带空格的情况', () {
      final result = SettingsService.splitArtistsWithSeparators(
        '  周杰伦  /  林俊杰  ',
        SettingsService.getDefaultSeparators(),
        [],
      );
      expect(result, equals(['周杰伦', '林俊杰']));
    });

    test('白名单艺术家不被分割', () {
      final result = SettingsService.splitArtistsWithSeparators(
        'Leo/need',
        ['/', '&'],
        ['Leo/need'],
      );
      expect(result, equals(['Leo/need']));
    });

    test('白名单匹配忽略大小写', () {
      final result = SettingsService.splitArtistsWithSeparators(
        'leo/need',
        ['/', '&'],
        ['Leo/need'],
      );
      expect(result, equals(['Leo/need']));
    });

    test('白名单艺术家完整匹配', () {
      final result = SettingsService.splitArtistsWithSeparators(
        'Leo/need',
        ['/', '&'],
        ['Leo/need'],
      );
      expect(result, equals(['Leo/need']));
    });

    test('获取默认分隔符列表', () {
      final separators = SettingsService.getDefaultSeparators();
      expect(separators, isNotEmpty);
      expect(separators, contains('/'));
    });

    test('获取默认白名单列表', () {
      final whitelist = SettingsService.getDefaultWhitelist();
      expect(whitelist, isNotEmpty);
      expect(whitelist, contains('Leo/need'));
    });
  });
}
