import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import '../lib/pages/search_page.dart';
import '../lib/services/music_service.dart';
import '../lib/services/audio_player_service.dart';
import '../lib/models/song.dart';

class MockMusicService extends Mock implements MusicService {}

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

void main() {
  group('SearchPage Tests', () {
    late MockMusicService mockMusicService;
    late MockAudioPlayerService mockAudioPlayerService;
    late List<Song> mockSongs;

    setUp(() {
      mockMusicService = MockMusicService();
      mockAudioPlayerService = MockAudioPlayerService();

      // 创建测试数据
      mockSongs = [
        Song(
          id: '1',
          title: '测试歌曲1',
          artist: '艺术家A',
          album: '专辑1',
          duration: 180000,
          uri: 'uri1',
          albumArtUri: null,
        ),
        Song(
          id: '2',
          title: '测试歌曲2',
          artist: '艺术家A/艺术家B',
          album: '专辑2',
          duration: 200000,
          uri: 'uri2',
          albumArtUri: null,
        ),
        Song(
          id: '3',
          title: '初音未来歌曲',
          artist: '初音未来',
          album: 'Vocaloid专辑',
          duration: 220000,
          uri: 'uri3',
          albumArtUri: null,
        ),
      ];

      // 模拟MusicService.getAllSongsWithoutArt方法
      when(
        mockMusicService.getAllSongsWithoutArt(),
      ).thenAnswer((_) async => mockSongs);
    });

    testWidgets('SearchPage 初始状态显示正确', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AudioPlayerService>.value(value: mockAudioPlayerService),
          ],
          child: const MaterialApp(home: SearchPage()),
        ),
      );

      expect(find.text('搜索音乐'), findsOneWidget);
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('输入关键词开始搜索'), findsOneWidget);
    });

    testWidgets('搜索功能按艺术家名称过滤', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AudioPlayerService>.value(value: mockAudioPlayerService),
          ],
          child: const MaterialApp(home: SearchPage()),
        ),
      );

      await tester.pumpAndSettle();

      // 输入搜索关键词
      await tester.enterText(find.byType(TextField), '艺术家A');
      await tester.pumpAndSettle();

      // 验证搜索结果
      expect(find.text('歌曲'), findsOneWidget);
      expect(find.text('艺术家'), findsOneWidget);
    });

    testWidgets('搜索功能按歌曲标题过滤', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AudioPlayerService>.value(value: mockAudioPlayerService),
          ],
          child: const MaterialApp(home: SearchPage()),
        ),
      );

      await tester.pumpAndSettle();

      // 输入搜索关键词
      await tester.enterText(find.byType(TextField), '测试歌曲');
      await tester.pumpAndSettle();

      // 验证搜索结果
      expect(find.text('测试歌曲1'), findsOneWidget);
      expect(find.text('测试歌曲2'), findsOneWidget);
    });

    testWidgets('搜索功能按专辑名称过滤', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AudioPlayerService>.value(value: mockAudioPlayerService),
          ],
          child: const MaterialApp(home: SearchPage()),
        ),
      );

      await tester.pumpAndSettle();

      // 输入搜索关键词
      await tester.enterText(find.byType(TextField), '专辑1');
      await tester.pumpAndSettle();

      // 验证搜索结果
      expect(find.text('专辑'), findsOneWidget);
    });

    testWidgets('搜索白名单艺术家不被分割', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AudioPlayerService>.value(value: mockAudioPlayerService),
          ],
          child: const MaterialApp(home: SearchPage()),
        ),
      );

      await tester.pumpAndSettle();

      // 输入搜索关键词
      await tester.enterText(find.byType(TextField), '初音未来');
      await tester.pumpAndSettle();

      // 验证搜索结果包含白名单艺术家
      expect(find.text('初音未来'), findsOneWidget);
    });

    testWidgets('清除搜索功能正常工作', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AudioPlayerService>.value(value: mockAudioPlayerService),
          ],
          child: const MaterialApp(home: SearchPage()),
        ),
      );

      await tester.pumpAndSettle();

      // 输入搜索关键词
      await tester.enterText(find.byType(TextField), '测试');
      await tester.pumpAndSettle();

      // 验证有搜索结果
      expect(find.text('歌曲'), findsOneWidget);

      // 点击清除按钮
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // 验证搜索结果已清除
      expect(find.text('歌曲'), findsNothing);
      expect(find.text('输入关键词开始搜索'), findsOneWidget);
    });

    testWidgets('空搜索结果显示正确', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AudioPlayerService>.value(value: mockAudioPlayerService),
          ],
          child: const MaterialApp(home: SearchPage()),
        ),
      );

      await tester.pumpAndSettle();

      // 输入不存在的搜索关键词
      await tester.enterText(find.byType(TextField), '不存在的歌曲');
      await tester.pumpAndSettle();

      // 验证显示空结果
      expect(find.text('未找到匹配的内容'), findsOneWidget);
    });
  });
}
