import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _dynamicColor = true;
  double _volume = 0.8;
  String _language = '中文';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSectionTitle('外观'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('切换应用主题模式'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('动态色彩'),
            subtitle: const Text('使用系统动态色彩主题'),
            value: _dynamicColor,
            onChanged: (value) {
              setState(() {
                _dynamicColor = value;
              });
            },
          ),
          _buildSectionTitle('音频'),
          ListTile(
            title: const Text('默认音量'),
            subtitle: Slider(
              value: _volume,
              onChanged: (value) {
                setState(() {
                  _volume = value;
                });
              },
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(_volume * 100).toInt()}%',
            ),
          ),
          _buildSectionTitle('通用'),
          ListTile(
            title: const Text('语言'),
            subtitle: const Text('选择应用显示语言'),
            trailing: DropdownButton<String>(
              value: _language,
              items: ['中文', 'English', '日本語'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _language = newValue!;
                });
              },
            ),
          ),
          ListTile(
            title: const Text('扫描音乐库'),
            subtitle: const Text('重新扫描设备中的音乐文件'),
            trailing: const Icon(Icons.refresh),
            onTap: () {
              // 这里可以添加扫描音乐库的逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在扫描音乐库...')),
              );
            },
          ),
          _buildSectionTitle('关于'),
          ListTile(
            title: const Text('版本信息'),
            subtitle: const Text('当前版本: 1.0.0'),
            onTap: () {
              // 这里可以添加版本信息详情
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
