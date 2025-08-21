import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:kanade/pages/home_page.dart';
import 'package:kanade/pages/search_page.dart';
import 'package:kanade/pages/music_page.dart';
import 'package:kanade/pages/more_page.dart';
import 'package:kanade/services/audio_player_service.dart';
import 'package:kanade/services/settings_service.dart';
import 'package:kanade/widgets/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  await SettingsService.init();
  
  // 创建音频服务实例并恢复播放状态
  final audioService = AudioPlayerService();
  await audioService.restorePlaylistState();
  
  runApp(KanadeApp(audioService: audioService));
}

class KanadeApp extends StatelessWidget {
  final AudioPlayerService audioService;
  
  const KanadeApp({super.key, required this.audioService});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return ChangeNotifierProvider.value(
          value: audioService,
          child: MaterialApp(
            title: 'Kanade',
            theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
            darkTheme: ThemeData(
              colorScheme: darkColorScheme,
              useMaterial3: true,
            ),
            home: const MainNavigation(),
          ),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const MusicPage(),
    const MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: '主页'),
              NavigationDestination(icon: Icon(Icons.search), label: '搜索'),
              NavigationDestination(icon: Icon(Icons.music_note), label: '音乐'),
              NavigationDestination(icon: Icon(Icons.more_horiz), label: '更多'),
            ],
          ),
        ],
      ),
    );
  }
}
