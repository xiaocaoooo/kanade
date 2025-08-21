import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/services/audio_player_service.dart';

/// 音量控制示例页面
/// 展示如何使用新的kanada_volume集成功能
class VolumeExamplePage extends StatefulWidget {
  const VolumeExamplePage({super.key});

  @override
  State<VolumeExamplePage> createState() => _VolumeExamplePageState();
}

class _VolumeExamplePageState extends State<VolumeExamplePage> {
  int? _systemVolume;
  int? _maxSystemVolume;

  @override
  void initState() {
    super.initState();
    _loadSystemVolumeInfo();
  }

  Future<void> _loadSystemVolumeInfo() async {
    final audioService = Provider.of<AudioPlayerService>(context, listen: false);
    
    final volume = await audioService.getSystemVolume();
    final maxVolume = await audioService.getSystemMaxVolume();
    
    setState(() {
      _systemVolume = volume;
      _maxSystemVolume = maxVolume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('音量控制示例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AudioPlayerService>(
        builder: (context, audioService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          '系统音量信息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('当前系统音量: ${_systemVolume ?? "未知"}'),
                        Text('系统最大音量: ${_maxSystemVolume ?? "未知"}'),
                        Text(
                          '应用音量百分比: ${(audioService.volume * 100).toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          '音量滑块控制',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.volume_down),
                            Expanded(
                              child: Slider(
                                value: audioService.volume,
                                onChanged: (value) {
                                  audioService.setVolume(value);
                                },
                                min: 0.0,
                                max: 1.0,
                                divisions: 15, // 对应Android的0-15音量等级
                              ),
                            ),
                            const Icon(Icons.volume_up),
                          ],
                        ),
                        Text(
                          '音量: ${(audioService.volume * 100).toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => audioService.setVolume(0.0),
                      child: const Text('静音'),
                    ),
                    ElevatedButton(
                      onPressed: () => audioService.setVolume(0.5),
                      child: const Text('50%'),
                    ),
                    ElevatedButton(
                      onPressed: () => audioService.setVolume(1.0),
                      child: const Text('最大'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSystemVolumeInfo,
                  child: const Text('刷新系统音量信息'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}