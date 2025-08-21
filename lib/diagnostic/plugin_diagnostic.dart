import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class PluginDiagnostic extends StatefulWidget {
  const PluginDiagnostic({super.key});

  @override
  _PluginDiagnosticState createState() => _PluginDiagnosticState();
}

class _PluginDiagnosticState extends State<PluginDiagnostic> {
  static const platform = MethodChannel('media_service');
  String _status = '等待测试...';
  String _details = '';

  Future<void> _testPluginRegistration() async {
    setState(() {
      _status = '测试中...';
      _details = '';
    });

    try {
      // 测试方法调用
      final String result = await platform.invokeMethod('getAllSongs');
      final List<dynamic> songs = jsonDecode(result);
      
      setState(() {
        _status = '✅ 插件注册成功';
        _details = '找到 ${songs.length} 首歌曲';
      });
    } on MissingPluginException catch (e) {
      setState(() {
        _status = '❌ 插件未注册';
        _details = '错误: ${e.message}\n\n'
            '解决方案:\n'
            '1. 运行 flutter clean\n'
            '2. 运行 flutter pub get\n'
            '3. 完全卸载并重新安装应用\n'
            '4. 检查 Android 权限设置';
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = '⚠️ 平台异常';
        _details = '错误: ${e.message}\n\n'
            '可能原因:\n'
            '1. 权限被拒绝\n'
            '2. 没有媒体文件\n'
            '3. Android 版本兼容性问题';
      });
    } catch (e) {
      setState(() {
        _status = '❌ 未知错误';
        _details = '错误: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      const platform = MethodChannel('media_service');
      await platform.invokeMethod('requestPermissions');
      _testPluginRegistration();
    } catch (e) {
      setState(() {
        _status = '权限请求失败';
        _details = '错误: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('插件诊断工具'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '媒体服务插件状态',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 16,
                        color: _status.contains('✅') ? Colors.green : 
                               _status.contains('❌') ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '详细信息:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(_details),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testPluginRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('测试插件'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _requestPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('请求权限'),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '调试步骤:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. 确保在 AndroidManifest.xml 中声明了所有必要权限\n'
                      '2. 检查 MainActivity.kt 是否正确注册了 MediaServicePlugin\n'
                      '3. 运行 flutter clean && flutter pub get\n'
                      '4. 完全卸载应用后重新安装\n'
                      '5. 检查 Android 设置中的权限授予情况',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
