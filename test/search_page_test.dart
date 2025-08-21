import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kanade/pages/search_page.dart';
import 'package:kanade/models/song.dart';
import 'package:kanade/services/audio_player_service.dart';

import 'dart:typed_data';

class MockMusicService {
  Future<List<Song>> getAllSongs() async {
    return [
      Song(
        id: '1',
        title: '测试歌曲1',
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
        title: '测试歌曲2',
        artist: '艺术家A/艺术家B',
        album: '专辑2',
        duration: 200000,
        path: 'path2',
        size: 2048,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      ),
      Song(
        id: '3',
        title: '初音未来歌曲',
        artist: '初音未来',
        album: 'Vocaloid专辑',
        duration: 220000,
        path: 'path3',
        size: 3072,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      ),
    ];
  }
}

class MockAudioPlayerService extends AudioPlayerService {
  @override
  Future<void> playSong(Song song) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> togglePlayMode() async {}

  @override
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {}

  @override
  Uint8List? getAlbumArtForSong(Song song) => null;

  @override
  Future<Uint8List?> loadAlbumArtForSong(Song song) async => null;

  @override
  List<Song> get playlist => [];

  @override
  Song? get currentSong => null;

  @override
  bool get isPlaying => false;

  @override
  bool get isPaused => false;

  @override
  bool get isStopped => true;

  @override
  Duration get position => Duration.zero;

  @override
  Duration get duration => Duration.zero;

  @override
  double get volume => 1.0;

  @override
  double get progress => 0.0;

  @override
  PlayerState get playerState => PlayerState.stopped;

  @override
  PlayMode get playMode => PlayMode.sequence;

  @override
  IconData get playModeIcon => Icons.repeat;
}

void main() {
  group('SearchPage Tests', () {
    late MockAudioPlayerService mockAudioPlayerService;

    setUp(() {
      mockAudioPlayerService = MockAudioPlayerService();
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
