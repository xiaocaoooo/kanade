import 'package:flutter/material.dart';
import 'package:kanada_lyric_sender/kanada_lyric_sender.dart';

class DebugLyricSenderPage extends StatefulWidget {
  const DebugLyricSenderPage({super.key});

  @override
  State<DebugLyricSenderPage> createState() => _DebugLyricSenderPageState();
}

class _DebugLyricSenderPageState extends State<DebugLyricSenderPage> {
  bool _hasEnable = false;
  final TextEditingController _lyricController = TextEditingController();
  final TextEditingController _delayController = TextEditingController(text: '0');
  String _statusMessage = '';
  Color _statusColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _checkEnableStatus();
  }

  @override
  void dispose() {
    _lyricController.dispose();
    _delayController.dispose();
    super.dispose();
  }

  /// 检查插件是否已启用
  Future<void> _checkEnableStatus() async {
    try {
      final result = await KanadaLyricSenderPlugin.hasEnable();
      setState(() {
        _hasEnable = result;
        _updateStatus('插件状态: ${result ? '已启用' : '未启用'}', result ? Colors.green : Colors.red);
      });
    } catch (e) {
      setState(() {
        _hasEnable = false;
        _updateStatus('检查启用状态失败: $e', Colors.red);
      });
    }
  }

  /// 发送歌词
  Future<void> _sendLyric() async {
    final lyric = _lyricController.text.trim();
    if (lyric.isEmpty) {
      _updateStatus('请输入歌词内容', Colors.orange);
      return;
    }

    final delayText = _delayController.text.trim();
    int delay = 0;
    try {
      delay = int.parse(delayText);
    } catch (e) {
      _updateStatus('延迟时间必须是整数', Colors.orange);
      return;
    }

    try {
      await KanadaLyricSenderPlugin.sendLyric(lyric, delay);
      _updateStatus('歌词已发送: "$lyric" (延迟: ${delay}ms)', Colors.blue);
    } catch (e) {
      _updateStatus('发送歌词失败: $e', Colors.red);
    }
  }

  /// 清空歌词
  Future<void> _clearLyric() async {
    try {
      await KanadaLyricSenderPlugin.clearLyric();
      _updateStatus('歌词已清空', Colors.blue);
    } catch (e) {
      _updateStatus('清空歌词失败: $e', Colors.red);
    }
  }

  /// 更新状态消息
  void _updateStatus(String message, Color color) {
    setState(() {
      _statusMessage = message;
      _statusColor = color;
    });
    
    // 3秒后清除状态消息
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _statusMessage == message) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('歌词发送调试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkEnableStatus,
            tooltip: '刷新状态',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 插件状态显示
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '插件状态',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('是否启用: '),
                        Expanded(
                          child: Text(
                            _hasEnable ? '已启用' : '未启用',
                            style: TextStyle(
                              color: _hasEnable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 发送歌词区域
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '发送歌词',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lyricController,
                      decoration: const InputDecoration(
                        labelText: '歌词内容',
                        hintText: '请输入要发送的歌词...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _delayController,
                            decoration: const InputDecoration(
                              labelText: '延迟时间 (毫秒)',
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _sendLyric,
                          child: const Text('发送'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearLyric,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('清空歌词'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkEnableStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('检查状态'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 状态消息
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  border: Border.all(color: _statusColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(color: _statusColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}