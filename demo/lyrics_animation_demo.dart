import 'package:flutter/material.dart';
import '../lib/pages/lyrics_page.dart';

// 歌词动画演示页面
class LyricsAnimationDemo extends StatefulWidget {
  const LyricsAnimationDemo({super.key});

  @override
  State<LyricsAnimationDemo> createState() => _LyricsAnimationDemoState();
}

class _LyricsAnimationDemoState extends State<LyricsAnimationDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  double _progress = 0.0;

  // 示例歌词数据
  final List<WordTiming> demoWords = [
    WordTiming(word: "测试", startTime: const Duration(milliseconds: 0), endTime: const Duration(milliseconds: 500)),
    WordTiming(word: "动画", startTime: const Duration(milliseconds: 500), endTime: const Duration(milliseconds: 1000)),
    WordTiming(word: "效果", startTime: const Duration(milliseconds: 1000), endTime: const Duration(milliseconds: 1500)),
    WordTiming(word: "逐字", startTime: const Duration(milliseconds: 1500), endTime: const Duration(milliseconds: 2000)),
    WordTiming(word: "歌词", startTime: const Duration(milliseconds: 2000), endTime: const Duration(milliseconds: 2500)),
  ];

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // 模拟播放进度
    _demoController.addListener(() {
      setState(() {
        _progress = _demoController.value;
      });
    });

    // 自动播放演示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _demoController.repeat();
    });
  }

  @override
  void dispose() {
    _demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('歌词动画演示'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 显示当前播放时间
            Text(
              '播放进度: ${(_progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 40),
            
            // 逐字歌词动画演示
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _OptimizedWordLyrics(
                wordTimings: demoWords,
                isCurrent: true,
                position: Duration(milliseconds: (_progress * 2500).toInt()),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _demoController.reset();
                    _demoController.forward();
                  },
                  child: const Text('重新播放'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_demoController.isAnimating) {
                      _demoController.stop();
                    } else {
                      _demoController.forward();
                    }
                  },
                  child: Text(_demoController.isAnimating ? '暂停' : '播放'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 扩展WordTiming类使其可用于演示
extension DemoWordTiming on WordTiming {
  static WordTiming create(String word, Duration start, Duration end) {
    return WordTiming(word: word, startTime: start, endTime: end);
  }
}

// 运行演示的入口函数
void main() {
  runApp(const MaterialApp(
    home: LyricsAnimationDemo(),
    debugShowCheckedModeBanner: false,
  ));
}