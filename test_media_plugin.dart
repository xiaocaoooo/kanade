import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    home: MediaPluginTest(),
  ));
}

class MediaPluginTest extends StatefulWidget {
  const MediaPluginTest({super.key});
  
  @override
  State<MediaPluginTest> createState() => _MediaPluginTestState();
}

class _MediaPluginTestState extends State<MediaPluginTest> with WidgetsBindingObserver {
  static const platform = MethodChannel('media_service');
  String _result = '等待测试...';

  Future<void> _testGetAllSongs() async {
    try {
      final String result = await platform.invokeMethod('getAllSongs');
      setState(() {
        _result = '成功: ${result.length} 字符';
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = '平台异常: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _result = '错误: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('媒体插件测试')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _testGetAllSongs,
              child: Text('测试 getAllSongs'),
            ),
            SizedBox(height: 20),
            Text(_result),
          ],
        ),
      ),
    );
  }
}
